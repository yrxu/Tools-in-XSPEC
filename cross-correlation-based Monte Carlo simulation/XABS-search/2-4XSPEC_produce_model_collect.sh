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

for a in 0 1 2 3
do
echo "linewidth: ${linewidth[$a]} km/s with a step of velocity: ${vstep_list[$a]} km/s"
echo "merge residual spectra into one file"

python3<<EOF
import pandas as pd
import numpy as np
ystack=[]
for i in np.arange(${xi_min}, ${xi_max}+0.01,${xi_step}):
	for j in np.arange(${zv_min},${zv_max}+1,${vstep_list[$a]}):
		infile='${model_dir}/'+'model_lw'+str(${linewidth[$a]})+'_xi'+str(round(i,1))+'_zv'+str(j)+'.qdp' 
		infile2='${model_dir}/'+'model_lw'+str(${linewidth[$a]})+'_xi'+str(round(i,1))+'_zv'+str(j)+'_bald.qdp' 
		data=np.loadtxt(infile,skiprows=3,dtype=str)
		data2=np.loadtxt(infile2,skiprows=3,dtype=str)
		x=data[:,0];y=data[:,4]
		x2=data2[:,0];y2=data2[:,4]
		if len(ystack)==0:
			ystack.append(x)
		y_sub=[n - m  for n,m in zip(y,y2)]  ###remove the effects of edges, leaving only lines
		ystack.append(y_sub)
np.savetxt('${DIR_home}/'+'merge_model_lw'+str(${linewidth[$a]})+'.txt', np.array(ystack).T, fmt='%.9f')  
EOF

done
echo "done"
