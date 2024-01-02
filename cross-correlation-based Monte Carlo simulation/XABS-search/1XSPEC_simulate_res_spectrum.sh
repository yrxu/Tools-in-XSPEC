#!/bin/bash
N_cpu=4  # Define parallelization parameters

mkdir ${PWD}/simulation
DIR_home=${PWD}/simulation
mkdir ${DIR_home}/MC_spectrum
mkdir ${DIR_home}/res
MC_spectrum=${DIR_home}/MC_spectrum
res_spectrum=${DIR_home}/res
Emin=(0.4 1.77) #keV
Emax=(1.77 8.0) #keV RGS energy band: 0.4-1.77 keV; EPIC-pn energy band: 1.77-8.0 keV


number=10000     ##number of simulated spectra
max_item=`echo "${number}-1" | bc`
xspec_startup_xcm=${PWD}/nthcomp+relxillCp.xcm  #change the location of data into a global location not e.g. ../../analysis

#########create the .xcm file to simulate spectra
#########save real residual spectrum
routine_sim=${DIR_home}/simulated_${number}_res_spectrum.xcm
echo "start to make the routine file for simulation"
echo "@${xspec_startup_xcm}"                                                       > ${routine_sim}
echo "query yes"                                                                  >> ${routine_sim}
echo "parallel leven ${N_cpu}"                                                    >> ${routine_sim}
echo "abun lpgs"                                                                  >> ${routine_sim}
#echo "data 2:2 none"                                                             >> ${routine_sim} ###currently, just consider one spectrum
echo "cpd /null"                                                                  >> ${routine_sim}
echo "setplot delete all"                                                         >> ${routine_sim}
echo "setp area"                                                                  >> ${routine_sim}
echo "setp e"                                                                     >> ${routine_sim}
echo "plot res"                                                                   >> ${routine_sim}
echo "setplot command wd real_res"                                                >> ${routine_sim}
echo "setplot list"                                                               >> ${routine_sim}
echo "plot "                                                                      >> ${routine_sim}
echo "mv real_res.qdp ${DIR_home}"                                                >> ${routine_sim}
echo "setplot delete all"                                                         >> ${routine_sim}
echo " "                                                                          >> ${routine_sim}

echo "#generate real residual spectrum routine"                                   >> ${routine_sim}
for n in $(seq 0 1 ${max_item})
do
echo "@${xspec_startup_xcm}"                                                      >> ${routine_sim}
echo "query yes"                                                                  >> ${routine_sim}
echo "abun lpgs"                                                                  >> ${routine_sim}
#echo "data 2:2 none"                                                             >> ${routine_sim}
echo "# spectrum ${n}"                                                            >> ${routine_sim}
echo "fakeit"                                                                     >> ${routine_sim}
echo "y"                                                                          >> ${routine_sim}
echo "${n}_"                                                                      >> ${routine_sim}
echo "simulated_${n}_rgs.fak"                                                     >> ${routine_sim}
echo " "                                                                          >> ${routine_sim}
echo "simulated_${n}_epicpn.fak"                                                  >> ${routine_sim}
echo " "                                                                          >> ${routine_sim}
echo "ignore 1:**-${Emin[0]} ${Emax[0]}-** 2:**-${Emin[1]} ${Emax[1]}-**"         >> ${routine_sim}
echo "fit"                                                                        >> ${routine_sim}
echo "cpd /null"                                                                  >> ${routine_sim}
echo "setp e"                                                                     >> ${routine_sim}
echo "setp area"                                                                  >> ${routine_sim}
echo "plot res"                                                                   >> ${routine_sim}
echo "setplot command wd ${n}_res"                                                >> ${routine_sim}
echo "setplot list"                                                               >> ${routine_sim}
echo "plot "                                                                      >> ${routine_sim}
echo "setplot delete all"                                                         >> ${routine_sim}
echo "mv ${n}_res.qdp ${res_spectrum} "                                           >> ${routine_sim}
echo "mv simulated_${n}_rgs.fak ${MC_spectrum} "                                  >> ${routine_sim}
echo "mv simulated_${n}_epicpn.fak ${MC_spectrum} "                               >> ${routine_sim}
echo "mv simulated_${n}_rgs_bkg.fak ${MC_spectrum} "                              >> ${routine_sim}
echo "mv simulated_${n}_epicpn_bkg.fak ${MC_spectrum} "                           >> ${routine_sim}
echo " "
echo "# simulate and save spectrum ${n}"
done

echo "exit"                                                                       >> ${routine_sim}

xspec<<EOF
@${routine_sim}
EOF

echo "merge residual spectra into one file"
python3<<EOF
import numpy as np
import pandas as pd
def where_is_str(array, string="NO"):
	index=np.where(array==string)
	seen = set()
	dupes = [x for x in index[0] if x in seen or seen.add(x)]    
	return dupes
ystack=[]
for i in range(${number}):
	infile='${res_spectrum}/'+str(i)+'_res.qdp'
	data = np.loadtxt(infile,skiprows=3,dtype=str)
	index=where_is_str(data)
	data=np.delete(data,index,0)
	index=where_is_str(data,string="0")
	data=np.delete(data,index,0)
	data = data.astype(np.float64)
	x=data[:,0];errx=data[:,1];y=data[:,2];erry=data[:,3]
	#x=x[:-1];errx=errx[:-1];y=y[:-1];erry=erry[:-1]
	if i==0:
		ystack.append(x)
	ystack.append(np.nan_to_num(y/erry**2))
np.savetxt('${DIR_home}/'+'merge_res_'+str(${number})+'.txt', np.array(ystack).T, fmt='%.9f')
EOF

echo "done"
