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

num_simulations=10000
max_item=`echo "${number}-1" | bc`

xi_min=0.0
xi_max=5.0
xi_step=0.1
zv_min=0
zv_max=105000
linewidth=(100 1500 4500)
vstep_list=(300 700 1500)

#logNH_min=19.0 ### cm^-2
#logNH_max=23.0
#logNH_step=1.0

#min_energy=0.4
#max_energy=1.77

xspec_startup_xcm=${PWD}/nthcomp+relxillCp.xcm  #change the localtion of data into global location not e.g. ../../analysis
################save real residual spectrum
#linewidth=(500 1500)
for a in 0  
do
echo "linewidth: ${linewidth[$a]} km/s"

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
num_simulations=df_sim.shape[1]-2
print('Number of simulations: ',num_simulations)
p_value=[]
norm_list=[]
for i in range(num_models):
	print('calculate the '+str(i)+'th model point')
	#if df.iloc[i][3]>0:
	temp=df_sim.iloc[i][2:]
	#print("temp:",temp)
	#print("index",temp>=df.iloc[i][2])
	temp=temp[temp>=df.iloc[i][2]]
	pvalue=len(temp)/num_simulations
		#norm_list.append(1)
	#else:
	#	temp=df_sim.iloc[i][3:]
	#	temp=temp[temp<=df.iloc[i][3]]
	#	pvalue=len(temp)/num_simulations
		#norm_list.append(-1)
		#pvalue=np.sum([1 if c<df.iloc[i][1] else 0 for c in df_sim.iloc[i][1:]])/num_simulations
	p_value.append(pvalue)

def find_nearest(array, value):
	array = np.asarray(array)
	idx = (np.abs(array - value)).argmin()
	return idx
#print(p_value)
confidence_level=[1 - i for i in p_value]
arr=np.linspace(0,3.89,num=100000)
levels=[special.erf(i/np.sqrt(2)) for i in arr]
significance=[arr[find_nearest(levels,i)] for i in confidence_level]
#np.savetxt('${DIR_home}/'+'single_trial_pvalue_lw'+str(${linewidth[$a]})+'.txt',np.column_stack([np.array(df[0]),np.array(p_value)]))

xi=[];zv=[]
#for k in np.arange(${logNH_min}, ${logNH_max}+0.01, ${logNH_step}):
for i in np.arange(${xi_min}, ${xi_max}+0.01,${xi_step}):
	for j in np.arange(${zv_min},${zv_max}+1,${vstep_list[$a]}):
		xi.extend([round(i,1)]);zv.extend([j*-1])
np.savetxt('${DIR_home}/'+'single_trial_significance_lw'+str(${linewidth[$a]})+'.txt',np.column_stack([ np.array(xi), np.array(zv),np.array(significance)]))

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
	#if df.iloc[i][1]>0:
	temp=pd.DataFrame(max_list)
	temp=temp[temp>=df.iloc[i][2]]
	temp=temp.dropna()
	true_pvalue=len(temp)/num_simulations
	#true_norm_list.append(1)
		#true_pvalue=np.sum([1 if c>df.iloc[i][1] else 0 for c in max_list])/num_simulations
	#else:
	#	temp=pd.DataFrame(min_list)
	#	temp=temp[temp<=df.iloc[i][1]]
	#	temp=temp.dropna()
	#	true_pvalue=len(temp)/num_simulations
	#	true_norm_list.append(-1)
		#true_pvalue=np.sum([1 if c<df.iloc[i][1] else 0 for c in min_list])/num_simulations
	true_p_value.append(true_pvalue)
#print(true_p_value)
true_confidence_level=[1 - i for i in true_p_value]
#print(arr,true_confidence_level)
true_significance=[arr[find_nearest(levels,i)] for i in true_confidence_level]
#np.savetxt('${DIR_home}/'+'true_pvalue_lw'+str(${linewidth[$a]})+'.txt',np.column_stack([np.array(df[0]),np.array(true_p_value)]))
np.savetxt('${DIR_home}/'+'true_significance_lw'+str(${linewidth[$a]})+'.txt',np.column_stack([np.array(xi), np.array(zv),np.array(true_significance)]))



EOF

done
echo "done"
