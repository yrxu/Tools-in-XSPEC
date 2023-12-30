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

num_simulations=10
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
import scipy.integrate as integrate
import scipy.special as special
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
	if df.iloc[i][1]>0:
		temp=df_sim.iloc[i][1:]
		temp=temp[temp>=df.iloc[i][1]]
		pvalue=len(temp)/num_simulations
		norm_list.append(1)
	else:
		temp=df_sim.iloc[i][1:]
		temp=temp[temp<=df.iloc[i][1]]
		pvalue=len(temp)/num_simulations
		norm_list.append(-1)
		#pvalue=np.sum([1 if c<df.iloc[i][1] else 0 for c in df_sim.iloc[i][1:]])/num_simulations
	p_value.append(pvalue)

def find_nearest(array, value):
	array = np.asarray(array)
	idx = (np.abs(array - value)).argmin()
	return idx
confidence_level=[1 - i for i in p_value]
arr=np.linspace(0,3.99,num=100000)
k=[special.erf(i/np.sqrt(2)) for i in arr]
significance=[j*arr[find_nearest(k,i)] for i,j in zip(confidence_level,norm_list)]
#np.savetxt('${DIR_home}/'+'single_trial_pvalue_lw'+str(${linewidth[$a]})+'.txt',np.column_stack([np.array(df[0]),np.array(p_value)]))
np.savetxt('${DIR_home}/'+'single_trial_significance_lw'+str(${linewidth[$a]})+'.txt',np.column_stack([np.array(df[0]),np.array(significance)]))

max_list=[]
min_list=[]
true_p_value=[]
true_norm_list=[]
for i in range(num_simulations):
	max_cor=max(np.array(df_sim[i+1]))
	min_cor=min(np.array(df_sim[i+1]))
	max_list.append(max_cor)
	min_list.append(min_cor)
for i in range(num_models):
	print('calculate the real significance of the '+str(i)+'th model point')
	if df.iloc[i][1]>0:
		temp=pd.DataFrame(max_list)
		temp=temp[temp>=df.iloc[i][1]]
		temp=temp.dropna()
		true_pvalue=len(temp)/num_simulations
		true_norm_list.append(1)
		#true_pvalue=np.sum([1 if c>df.iloc[i][1] else 0 for c in max_list])/num_simulations
	else:
		temp=pd.DataFrame(min_list)
		temp=temp[temp<=df.iloc[i][1]]
		temp=temp.dropna()
		true_pvalue=len(temp)/num_simulations
		true_norm_list.append(-1)
		#true_pvalue=np.sum([1 if c<df.iloc[i][1] else 0 for c in min_list])/num_simulations
	true_p_value.append(true_pvalue)
true_confidence_level=[1 - i for i in true_p_value]
true_significance=[j*arr[find_nearest(k,i)] for i,j in zip(true_confidence_level,true_norm_list)]
#np.savetxt('${DIR_home}/'+'true_pvalue_lw'+str(${linewidth[$a]})+'.txt',np.column_stack([np.array(df[0]),np.array(true_p_value)]))
np.savetxt('${DIR_home}/'+'true_significance_lw'+str(${linewidth[$a]})+'.txt',np.column_stack([np.array(df[0]),np.array(true_significance)]))



EOF

done
echo "done"
