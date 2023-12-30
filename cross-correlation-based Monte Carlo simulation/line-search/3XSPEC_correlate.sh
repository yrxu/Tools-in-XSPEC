#!/bin/bash
export OMP_NUM_THREADS=4
mkdir ${PWD}/simulation
DIR_home=${PWD}/simulation
mkdir ${DIR_home}/MC_spectrum
mkdir ${DIR_home}/model
mkdir ${DIR_home}/res
MC_spectrum=${DIR_home}/MC_spectrum
model_dir=${DIR_home}/model
res_spectrum=${DIR_home}/res

num_simulations=10000
max_item=`echo "${number}-1" | bc`

min_energy=0.4
max_energy=1.77

xspec_startup_xcm=${PWD}/zdiskbb+relxilllpCp.xcm  #change the localtion of data into global location not e.g. ../../analysis
################save real residual spectrum
linewidth=(0 100 500 1000 1500 2000 5000)
for a in 0 1 2 3 4 5 6
do
echo "linewidth: ${linewidth[$a]} and number of points: ${num_points}"

python3<<EOF
import numpy as np
import pandas as pd
dtype=[('x','float'),('errx','float'),('y','float'),('erry','float')]
infile='${DIR_home}/real_res_rgs.qdp'
data = np.loadtxt(infile,skiprows=3,dtype=dtype)
x=data['x'];errx=data['errx'];y=data['y'];erry=data['erry']
x=x[:-1];errx=errx[:-1];y=y[:-1];erry=erry[:-1]


inmodel='${DIR_home}/merge_model_lw'+str(${linewidth[$a]})+'.txt'
df=pd.read_csv(inmodel,header=None,delimiter=' ')
num_model=len(df.columns)-1
correlate=[]
for i in range(num_model):
	y_model=np.array(df[i+1])
	cor=np.correlate(y,y_model)
	correlate.append(cor)
en=np.logspace(np.log10(${min_energy}),np.log10(${max_energy}),num=num_model)
np.savetxt('${DIR_home}/'+'raw_correlate_real_lw'+str(${linewidth[$a]})+'.txt',np.column_stack([en,np.array(correlate)]))

sim_res_file='${DIR_home}/merge_res_'+str(${num_simulations})+'.txt'
df_sim=pd.read_csv(sim_res_file,header=None,delimiter=' ')
correlate_stack=[]
for i in range(${num_simulations}):
	y_sim=np.array(df_sim[i+1])
	correlate_sim=[]
	for j in range(num_model):
		y_model=np.array(df[j+1])
		cor_sim=np.correlate(y_sim,y_model)
		correlate_sim.append(cor_sim)
		print('calculate the '+str(j)+'th model point of the '+str(i)+'th simulation')
	if i==0:
		correlate_stack.append(en)
	correlate_stack.append(correlate_sim)
np.savetxt('${DIR_home}/'+'raw_correlate_sim_lw'+str(${linewidth[$a]})+'.txt',np.array(correlate_stack).T)

raw_file='${DIR_home}/'+'raw_correlate_sim_lw'+str(${linewidth[$a]})+'.txt'
df_raw=pd.read_csv(raw_file,header=None, delimiter=' ')
N_corr=[]
N_corr_real=[]
for i in range(num_model):
	corr=df_raw.iloc[i][1:]	
	count_pos=np.sum([1 if c>0 else 0 for c in corr])
	count_neg=np.sum([1 if c<0 else 0 for c in corr])
	index_pos=[True if c>0 else False for c in corr]	
	index_neg=[True if c<0 else False for c in corr]
	if count_pos==0:
		norm_pos=np.infty
	else:
		norm_pos=np.sqrt(sum([k**2 for k in corr[index_pos]])/count_pos)	
	if count_neg==0:
		norm_neg=np.infty
	else:
		norm_neg=np.sqrt(sum([k**2 for k in corr[index_neg]])/count_neg)
	n_corr=[c/norm_pos if c>0 else c/norm_neg for c in corr]
	N_corr.append(n_corr)
	n_corr_real=[c/norm_pos if c>0 else c/norm_neg for c in correlate[i]]
	N_corr_real.append(n_corr_real)
	print('calculate the normalized significance of the '+str(i)+'th model point')
np.savetxt('${DIR_home}/'+'norm_correlate_sim_lw'+str(${linewidth[$a]})+'.txt',np.column_stack([en,np.array(N_corr)]))
np.savetxt('${DIR_home}/'+'norm_correlate_real_lw'+str(${linewidth[$a]})+'.txt',np.column_stack([en,np.array(N_corr_real)]))
EOF

done
echo "done"
