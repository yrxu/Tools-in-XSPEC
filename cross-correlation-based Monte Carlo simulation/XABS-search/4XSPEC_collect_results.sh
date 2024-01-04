#!/bin/bash
N_cpu=4  # Define parallelization parameters

mkdir ${PWD}/simulation
DIR_home=${PWD}/simulation
mkdir ${DIR_home}/MC_spectrum
mkdir ${DIR_home}/model
mkdir ${DIR_home}/res
MC_spectrum=${DIR_home}/MC_spectrum
model_dir=${DIR_home}/model
res_spectrum=${DIR_home}/res

xi_min=0.0 
xi_max=5.0      ### scanned logxi grids
xi_step=0.1
zv_min=0
zv_max=105000   ###km/s scanned velocity grids
linewidth=(500 1500 4500 10000)       ### scanned linewidth grids
vstep_list=(300 700 1500 3000)        ### corresponding step of velocities

num_simulations=10000   
max_item=`echo "${number}-1" | bc`


xspec_startup_xcm=${PWD}/nthcomp+relxillCp.xcm  #change the location of data into a global location not e.g. ../../analysis
################calculate p-values and significance without considering look-elsewhere effect
for a in 0 1 2 3   
do
echo "linewidth: ${linewidth[$a]} km/s"

python3<<EOF
import numpy as np
import pandas as pd
import scipy.stats as stats
infile='${DIR_home}/norm_correlate_real_lw'+str(${linewidth[$a]})+'.txt'
df=pd.read_csv(infile,header=None,delimiter=' ')
insimfile='${DIR_home}/norm_correlate_sim_lw'+str(${linewidth[$a]})+'.txt'
df_sim=pd.read_csv(insimfile,header=None,delimiter=' ')
num_models=df.shape[0]
num_simulations=df_sim.shape[1]-2  ###avoid logxi and zv column
print('Number of simulations: ',num_simulations)
p_value=[]
norm_list=[]
for i in range(num_models):
	print('calculate the '+str(i)+'th model point')
	temp=df_sim.iloc[i][2:]
	temp=temp[temp>=df.iloc[i][2]] ###count the number of the cross-correlation of simulated spectra larger than that of the real spectrum within the i-th parameter bin
	pvalue=len(temp)/num_simulations
	p_value.append(pvalue)

def pvalue_to_sigma(p):
        return -stats.norm.ppf(p / 2)  ###divide by 2 for a two-tailed test
max_sigma=pvalue_to_sigma(1/${num_simulations})  ###maximal achievable sigma given the number of simulations
significance=[pvalue_to_sigma(i) if pvalue_to_sigma(i)!=np.infty else max_sigma for i in p_value]
xi=[];zv=[]
for i in np.arange(${xi_min}, ${xi_max}+0.01,${xi_step}):
	for j in np.arange(${zv_min},${zv_max}+1,${vstep_list[$a]}):
		xi.extend([round(i,2)]);zv.extend([j*-1])
np.savetxt('${DIR_home}/'+'single_trial_significance_lw'+str(${linewidth[$a]})+'.txt',np.column_stack([ np.array(xi), np.array(zv),np.array(significance)]), fmt='%.9f')

################calculate p-values and significance considering look-elsewhere effect
max_list=[]
min_list=[]
true_p_value=[]
true_norm_list=[]
for i in range(num_simulations):
	max_cor=max(np.array(df_sim[i+2]))
	min_cor=min(np.array(df_sim[i+2]))
	max_list.append(max_cor)
	min_list.append(min_cor)
for i in range(num_models):
	print('calculate the real significance of the '+str(i)+'th model point')
	temp=pd.DataFrame(max_list)
	temp=temp[temp>=df.iloc[i][2]]
	temp=temp.dropna()
	true_pvalue=len(temp)/num_simulations
	true_p_value.append(true_pvalue)

true_significance=[pvalue_to_sigma(i) if pvalue_to_sigma(i)!=np.infty else max_sigma for itrue_p_value]
np.savetxt('${DIR_home}/'+'true_significance_lw'+str(${linewidth[$a]})+'.txt',np.column_stack([np.array(xi), np.array(zv),np.array(true_significance)]), fmt='%.9f')

EOF

done
echo "done"
