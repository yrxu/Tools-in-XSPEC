#!/bin/bash
N_cpu=4 # Define parallelization parameters

mkdir ${PWD}/simulation
DIR_home=${PWD}/simulation
mkdir ${DIR_home}/MC_spectrum
mkdir ${DIR_home}/model
mkdir ${DIR_home}/res
MC_spectrum=${DIR_home}/MC_spectrum
model_dir=${DIR_home}/model
res_spectrum=${DIR_home}/res

num_simulations=10000  ###number of simulated residual spectra
max_item=`echo "${number}-1" | bc`

Emin=0.4  ### RGS energy band: 0.4-1.77 keV
Emax=1.77

xspec_startup_xcm=${PWD}/nthcomp+relxillCp.xcm  #change the location of data into global location not e.g. ../../analysis
################cross-correlate residual and model spectra
linewidth=(0 500 1500 4500 10000)
for a in 0 1 2 3 4
do
echo "linewidth: ${linewidth[$a]} km/s"

python3<<EOF
import numpy as np
import pandas as pd
import multiprocessing as mp
import time
import itertools
def func(params):
        a=params[0]
        b=params[1]
        return np.correlate(a,b)

###read real residual spectrum
infile='${DIR_home}/real_res_rgs.qdp'
data = pd.read_csv(infile,header=None,skiprows=3, delimiter=' ')
x=data[0];errx=data[1];y=data[2];erry=data[3]
y=y/erry**2

###read model spectra and cross-correlate with the real residual spectrum
inmodel='${DIR_home}/merge_model_lw'+str(${linewidth[$a]})+'.txt'
df_model=pd.read_csv(inmodel,header=None,delimiter=' ')
df=df_model[df_model[0].isin(data[0])]   ###remove the bad channel in model spectra
num_model=len(df.columns)-1   ###number of simulated model spectra, i.e. number of line energy grids
correlate=[]
for i in range(num_model):
	y_model=np.array(df[i+1]) ###avoid the energy column
	cor=np.correlate(y,y_model)
	correlate.append(cor)
en=np.logspace(np.log10(${Emin}),np.log10(${Emax}),num=num_model)
np.savetxt('${DIR_home}/'+'raw_correlate_real_lw'+str(${linewidth[$a]})+'.txt',np.column_stack([en,np.array(correlate)]), fmt='%.9f')

###read simulated residual spectra and cross-correlate with model spectra
sim_res_file='${DIR_home}/merge_res_'+str(${num_simulations})+'.txt'
df_sim=pd.read_csv(sim_res_file,header=None,delimiter=' ')
paramlist=list(itertools.product(np.array(df_sim.iloc[:,1:]).T,np.array(df.iloc[:,1:]).T))

print('start to parallel')
star=time.time()
pool=mp.Pool(${N_cpu})
correlate_sim=pool.map(func,paramlist)
end=time.time()
print('parallelization time: {:.4f} s'.format(end-star))
correlate_stack=np.array(correlate_sim).reshape($num_simulations,num_model)

np.savetxt('${DIR_home}/'+'raw_correlate_sim_lw'+str(${linewidth[$a]})+'.txt',np.column_stack([en,np.array(correlate_stack).T]), fmt='%.9f')

###########renormalized the real and each simulated cross-correlation results by simulated cross-correlations
###########The normalization follows Kosec, Peter et al. 2021, renormalizing positive and negative values separately. 
raw_file='${DIR_home}/'+'raw_correlate_sim_lw'+str(${linewidth[$a]})+'.txt'
df_raw=pd.read_csv(raw_file,header=None, delimiter=' ')
N_corr=[]
N_corr_real=[]
for i in range(num_model):
	corr=df_raw.iloc[i][1:]	
	count_pos=np.sum([1 if c>=0 else 0 for c in corr])
	count_neg=np.sum([1 if c<0 else 0 for c in corr])
	index_pos=[True if c>=0 else False for c in corr]	
	index_neg=[True if c<0 else False for c in corr]
	if count_pos==0:
		norm_pos=np.infty
	else:
		norm_pos=np.sqrt(sum([k**2 for k in corr[index_pos]])/count_pos)	
	if count_neg==0:
		norm_neg=np.infty
	else:
		norm_neg=np.sqrt(sum([k**2 for k in corr[index_neg]])/count_neg)
	n_corr=[c/norm_pos if c>=0 else c/norm_neg for c in corr]
	N_corr.append(n_corr)
	n_corr_real=[c/norm_pos if c>=0 else c/norm_neg for c in correlate[i]]
	N_corr_real.append(n_corr_real)
	print('calculate the normalized significance of the '+str(i)+'th model point')
np.savetxt('${DIR_home}/'+'norm_correlate_sim_lw'+str(${linewidth[$a]})+'.txt',np.column_stack([en,np.array(N_corr)]))
np.savetxt('${DIR_home}/'+'norm_correlate_real_lw'+str(${linewidth[$a]})+'.txt',np.column_stack([en,np.array(N_corr_real)]))
EOF

done
echo "done"
