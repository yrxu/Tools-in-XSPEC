#!/bin/bash
N_cpu=4  # Define parallelization parameters

mkdir ${PWD}/simulation
DIR_home=${PWD}/simulation
mkdir ${DIR_home}/MC_spectrum
mkdir ${DIR_home}/model
MC_spectrum=${DIR_home}/MC_spectrum
model_dir=${DIR_home}/model


xi_min=0.0 
xi_max=5.0      ### scanned logxi grids
xi_step=0.1
zv_min=0
zv_max=105000   ###km/s scanned velocity grids
linewidth=(500 1500 4500 10000)       ### scanned linewidth grids
vstep_list=(300 700 1500 3000)        ### corresponding step of velocities


xspec_startup_xcm=${PWD}/nthcomp+relxillCp.xcm  #change the location of data into a global location not e.g. ../../analysis
################collect generated model spectra and produce the predicted residual spectra by models

for a in 0
do
echo "linewidth: ${linewidth[$a]} km/s with a step of velocity: ${vstep_list[$a]} km/s"
	#for lognh in $(seq ${logNH_min} ${logNH_step} ${logNH_max})
	#do
	#	NH=$(echo "scale=8; e((${lognh}-24.0)*l(10))"| bc -l )
	#	echo "logNH: ${lognh} cm^-2 with a step of Delta logNH: ${logNH_step}"
echo "merge residual spectra into one file"

python3<<EOF
#import pandas as pd
import numpy as np
def where_is_str(array,string="NO"):
	index=np.where(array== string)
	return list(set(index[0]))

#load powerlaw spectrum
#powinfile='${model_dir}/model_power.qdp'
#powdata=np.loadtxt(powinfile,skiprows=3,dtype=str)
#powindex=where_is_str(powdata)
#powdata=np.delete(powdata,powindex,0)
#powdata=powdata.astype(np.float64)
#x_pow=powdata[:,0];y_pow=powdata[:,4]
#y_pow=[1 if abs(u-1)<8.e-4 else u for u in y_pow]
#y_pow=[m/n**2 for n,m in zip(x_pow,y_pow)]
ystack=[]
ystack_edge=[]
#number=${num_points}
#for k in np.arange(${logNH_min}, ${logNH_max}+0.01, ${logNH_step}):
for i in np.arange(${xi_min}, ${xi_max}+0.01,${xi_step}):
	for j in np.arange(${zv_min},${zv_max}+1,${vstep_list[$a]}):
		infile='${model_dir}/'+'model_lw'+str(${linewidth[$a]})+'_xi'+str(round(i,1))+'_zv'+str(j)+'.qdp' 
		infile2='${model_dir}/'+'model_lw'+str(${linewidth[$a]})+'_xi'+str(round(i,1))+'_zv'+str(j)+'_bald.qdp' 
		#print(infile)
		data=np.loadtxt(infile,skiprows=3,dtype=str)
		data2=np.loadtxt(infile2,skiprows=3,dtype=str)
		index=where_is_str(data)
		index2=where_is_str(data2)
		data=np.delete(data,index,0)
		data2=np.delete(data2,index2,0)
		data=data.astype(np.float64)
		data2=data2.astype(np.float64)
		x=data[:,0];y=data[:,4]
		x2=data2[:,0];y2=data2[:,4]
		#y=[1 if abs(u-1)<8.e-4 else u for u in y]
		#y=[n - m  for n,m in zip(y,y2)]
		if len(ystack)==0:
			ystack.append(x)
			ystack_edge.append(x)
		#if max(abs(np.array(y)))<1e-4:
	    	#	y=np.zeros(len(y))
		ystack_edge.append(y)
		y=[n - m  for n,m in zip(y,y2)]
		ystack.append(y)
np.savetxt('${DIR_home}/'+'merge_model_lw'+str(${linewidth[$a]})+'_edge.txt', np.array(ystack_edge).T )  
np.savetxt('${DIR_home}/'+'merge_model_lw'+str(${linewidth[$a]})+'.txt', np.array(ystack).T )  
EOF

done
echo "done"
