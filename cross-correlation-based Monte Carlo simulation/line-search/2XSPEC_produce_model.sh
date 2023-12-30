#!/bin/bash
export OMP_NUM_THREADS=4
mkdir ${PWD}/simulation
DIR_home=${PWD}/simulation
mkdir ${DIR_home}/MC_spectrum
mkdir ${DIR_home}/model
MC_spectrum=${DIR_home}/MC_spectrum
model_dir=${DIR_home}/model




min_energy=0.4
max_energy=1.77

xspec_startup_xcm=${PWD}/zdiskbb+relxilllpCp.xcm  #change the localtion of data into global location not e.g. ../../analysis
################save real residual spectrum
linewidth=(0 100 500 1000 1500 2000 5000)
num_points=2000
for a in 0 1 4 5 6
do
echo "linewidth: ${linewidth[$a]} and number of points: ${num_points}"
routine_sim=${DIR_home}/simulated_lw${linewidth[$a]}_model_${num_points}.xcm

logmin=$(echo "l(${min_energy})/l(10)" | bc -l)
logmax=$(echo "l(${max_energy})/l(10)" | bc -l)
logestep=$(echo "(l(${max_energy})/l(10)-l(${min_energy})/l(10))/(${num_points}-1)" | bc -l)
echo ${logestep} ${logmin} ${logmax}
echo "start to make the routine file to generate model"
echo "@${xspec_startup_xcm}" > ${routine_sim}
echo "query yes"            >> ${routine_sim}
echo "abun wilm"            >> ${routine_sim}
echo "data 2:2 none"        >> ${routine_sim}
echo "model gaus"           >> ${routine_sim}
echo "/*"                   >> ${routine_sim}



echo "start to generate loop" 
for y in $(seq 0 1 $((${num_points}-1)))
do 
	energy=$(echo "scale=8; e((${logmin}+$y*$logestep)*l(10))"| bc -l )
	lw=$(echo "scale=8; ${energy}*${linewidth[$a]}/300000"| bc -l )
	echo "Energy: ${energy} keV; linewidth: ${lw} keV"
	echo "#Energy: ${energy} keV; linewidth: ${lw} keV" >> ${routine_sim}
	echo "index" $(($y+1))"/"${num_points}

	echo "new 1 ${energy} -1"         >> ${routine_sim}
	echo "new 2 ${lw} -1"             >> ${routine_sim}
	echo "new 3 1 -1"                 >> ${routine_sim}
	echo " "                          >> ${routine_sim}
	echo "ignore 1:**-0.4 1.77-**"    >> ${routine_sim}
	echo "cpd /xs"                    >> ${routine_sim}
	echo "setp e"                     >> ${routine_sim}
	echo "plot uf"                   >> ${routine_sim}
	echo "setplot command wd ${y}_model_rgs"         >> ${routine_sim}
	echo "plot "                      >> ${routine_sim}
	echo "setplot list"               >> ${routine_sim}
	echo "mv ${y}_model_rgs.qdp ${model_dir} "                       >> ${routine_sim}
	echo "setplot delete all"         >> ${routine_sim}	
	echo " "                          >> ${routine_sim}
done

echo "exit"                 >> ${routine_sim}

xspec<<EOF
@${routine_sim}
EOF

echo "merge residual spectra into one file"

python3<<EOF
import pandas as pd
import numpy as np
ystack=[]
number=${num_points}
for i in range(number):
	infile='${model_dir}/'+str(i)+'_model_rgs.qdp'
	data = pd.read_csv(infile,skiprows=3,header=None,delimiter=' ')
	x=np.array(data[0][:-1]);y=np.array(data[4][:-1])
	if i==0:
		ystack.append(x)
	ystack.append(y)
np.savetxt('${DIR_home}/'+'merge_model_lw'+str(${linewidth[$a]})+'.txt', np.array(ystack).T)  
EOF

done
echo "done"
