#!/bin/bash
number_of_cores=4 # Define parallelization parameters
mkdir ${PWD}/simulation
DIR_home=${PWD}/simulation
mkdir ${DIR_home}/MC_spectrum    ### simulated spectra
mkdir ${DIR_home}/res            ###residual spectra
MC_spectrum=${DIR_home}/MC_spectrum
res_spectrum=${DIR_home}/res

number=10000                ##number of simulated spectra
max_item=`echo "${number}-1" | bc`

xspec_startup_xcm=${PWD}/zdiskbb+relxilllpCp.xcm  #startup .xcm file, caution!!! change the location of data into global location not e.g. ../../analysis
################save real residual spectrum
routine_sim=${DIR_home}/simulated_${number}_res_spectrum.xcm
echo "start to make the routine file for simulation"
echo "@${xspec_startup_xcm}" > ${routine_sim}
echo "query yes"            >> ${routine_sim}
echo "abun wilm"            >> ${routine_sim}
echo "data 2:2 none"        >> ${routine_sim}
echo "cpd /xs"              >> ${routine_sim}
echo "setp e"               >> ${routine_sim}
echo "setplot delete all"       >> ${routine_sim}
echo "plot res"             >> ${routine_sim}
echo "setplot command wd real_res_rgs"      >> ${routine_sim}
echo "setplot list"         >> ${routine_sim}
echo "plot "             >> ${routine_sim}
echo "mv real_res_rgs.qdp ${DIR_home}" >> ${routine_sim}
echo "setplot delete all"       >> ${routine_sim}
echo " "                    >> ${routine_sim}

echo "#generate real residual spectrum routine" >> ${routine_sim}

for n in $(seq 0 1 ${max_item})
do
echo "@${xspec_startup_xcm}" >> ${routine_sim}
echo "query yes"            >> ${routine_sim}
echo "abun wilm"            >> ${routine_sim}
echo "data 2:2 none"        >> ${routine_sim}
echo "# spectrum ${n}"         >> ${routine_sim}
echo "fakeit"                  >> ${routine_sim}
echo "y"                       >> ${routine_sim}
echo "${n}_"                   >> ${routine_sim}
echo "simulated_${n}_rgs.fak"  >> ${routine_sim}
echo " "                       >> ${routine_sim}
echo "ignore 1:**-0.4 1.77-**" >> ${routine_sim}
echo "cpd /xs"                 >> ${routine_sim}
echo "setp e"                  >> ${routine_sim}
echo "plot res"                >> ${routine_sim}
echo "setplot command wd ${n}_res_rgs"         >> ${routine_sim}
echo "setplot list"         >> ${routine_sim}
echo "plot "                >> ${routine_sim}
echo "mv ${n}_res_rgs.qdp ${res_spectrum} "                       >> ${routine_sim}
echo "mv simulated_${n}_rgs.fak ${MC_spectrum} "                  >> ${routine_sim}
echo "mv simulated_${n}_rgs_bkg.fak ${MC_spectrum} "             >> ${routine_sim}
echo "setplot delete all"       >> ${routine_sim}
echo " "
echo "# simulate and save spectrum ${n}"
done

echo "exit"                 >> ${routine_sim}

xspec<<EOF
@${routine_sim}
EOF

echo "merge residual spectra into one file"

python3<<EOF
import numpy as np

dtype=[('x','float'),('errx','float'),('y','float'),('erry','float')]
ystack=[]
for i in range(${number}):
	infile='${res_spectrum}/'+str(i)+'_res_rgs.qdp'
	data = np.loadtxt(infile,skiprows=3,dtype=dtype)
	x=data['x'];errx=data['errx'];y=data['y'];erry=data['erry']
	x=x[:-1];errx=errx[:-1];y=y[:-1];erry=erry[:-1]
	if i==0:
		ystack.append(x)
	ystack.append(y)
np.savetxt('${DIR_home}/'+'merge_res_'+str(${number})+'.txt', np.array(ystack).T)  
EOF

echo "done"
