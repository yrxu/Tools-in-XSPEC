#!/bin/bash

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

xspec_startup_xcm=${PWD}/nthcomp+relxillCp.xcm  #change the localtion of data into global location not e.g. ../../analysis
################calculate p-values and significance without considering look-elsewhere effect
linewidth=(0 500 1500 4500 10000)
for a in 0 1 2 3 4
do
echo "linewidth: ${linewidth[$a]} and number of points: ${num_points}"

python3<<EOF
import numpy as np
import pandas as pd
import scipy.stats as stats
infile='${DIR_home}/norm_correlate_real_lw'+str(${linewidth[$a]})+'.txt'
df=pd.read_csv(infile,header=None,delimiter=' ')
insimfile='${DIR_home}/norm_correlate_sim_lw'+str(${linewidth[$a]})+'.txt'
df_sim=pd.read_csv(insimfile,header=None,delimiter=' ')
num_models=df.shape[0]
num_simulations=df_sim.shape[1]-1
print(num_simulations)
p_value=[]
norm_list=[]
for i in range(num_models):
	print('calculate the '+str(i)+'th model point')
	if df.iloc[i][1]>=0:   ###positive cross-correlation
		temp=df_sim.iloc[i][1:]
		temp=temp[temp>=df.iloc[i][1]]  ###count the number of the cross-correlation of simulated spectra larger than that of the real spectrum within the i-th parameter bin 
		pvalue=len(temp)/num_simulations
		norm_list.append(1)
	else:                  ###negative cross-correlation
		temp=df_sim.iloc[i][1:]
		temp=temp[temp<=df.iloc[i][1]]  ###count the number of the cross-correlation of simulated spectra larger than that of the real spectrum within the i-th parameter bin 
		pvalue=len(temp)/num_simulations
		norm_list.append(-1)
		
	p_value.append(pvalue)

def pvalue_to_sigma(p):
	return -stats.norm.ppf(p / 2)  ###divide by 2 for a two-tailed test

max_sigma=pvalue_to_sigma(1/${num_simulations})  ###maximal achievable sigma given the number of simulations
significance=[pvalue_to_sigma(i)*j if pvalue_to_sigma(i)!=np.infty else max_sigma*j for i,j in zip(p_value,norm_list)]
np.savetxt('${DIR_home}/'+'single_trial_significance_lw'+str(${linewidth[$a]})+'.txt',np.column_stack([np.array(df[0]),np.array(significance)]), fmt='%.9f')


################calculate p-values and significance considering look-elsewhere effect
max_list=[]
min_list=[]
true_p_value=[]
true_norm_list=[]
####pick out the largest cross-correlation within simulated spectra, positive and negative
for i in range(num_simulations):
	max_cor=max(np.array(df_sim[i+1]))
	min_cor=min(np.array(df_sim[i+1]))
	max_list.append(max_cor)
	min_list.append(min_cor)
####calculate p-values
for i in range(num_models):
	print('calculate the real significance of the '+str(i)+'th model point')
	if df.iloc[i][1]>0:
		temp=pd.DataFrame(max_list)
		temp=temp[temp>=df.iloc[i][1]]
		temp=temp.dropna()
		true_pvalue=len(temp)/num_simulations
		true_norm_list.append(1)
	else:
		temp=pd.DataFrame(min_list)
		temp=temp[temp<=df.iloc[i][1]]
		temp=temp.dropna()
		true_pvalue=len(temp)/num_simulations
		true_norm_list.append(-1)
	true_p_value.append(true_pvalue)
true_significance=[pvalue_to_sigma(i)*j if pvalue_to_sigma(i)!=np.infty else max_sigma*j for i,j in zip(true_p_value,true_norm_list)]
np.savetxt('${DIR_home}/'+'true_significance_lw'+str(${linewidth[$a]})+'.txt',np.column_stack([np.array(df[0]),np.array(true_significance)]), fmt='%.9f')

EOF

done
echo "done"
