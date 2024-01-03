#!/bin/bash
N_cpu=4  # Define parallelization parameters

mkdir ${PWD}/simulation
DIR_home=${PWD}/simulation
mkdir ${DIR_home}/MC_spectrum
mkdir ${DIR_home}/model
mkdir ${DIR_home}/NH_grids
MC_spectrum=${DIR_home}/MC_spectrum
model_dir=${DIR_home}/model
NH_dir=${DIR_home}/NH_grids

redshift=0.048  ### the redshift of the source
xi_min=0.0 
xi_max=5.0      ### scanned logxi grids
xi_step=0.1
zv_min=0
zv_max=105000   ###km/s scanned velocity grids
linewidth=(500 1500 4500 10000)       ### scanned linewidth grids
vstep_list=(300 700 1500 3000)        ### corresponding step of velocities

Emin=0.4 #keV
Emax=1.77 #keV RGS energy band: 0.4-1.77 keV
xspec_startup_xcm=${PWD}/nthcomp+relxillCp.xcm  #change the location of data into a global location not e.g. ../../analysis

index_redshift=1   # the index of the redshift of zashift
index_fc=5   # the index of the covering factor of XABS 
index_z=6    # the index of the redshift of XABS   
index_logxi=2 # the index of logxi of XABS 
index_v=4    # the index of line width of XABS 
index_NH=3   # the index of NH of XABS 
index_gamm=7   # the index of gamma of pow 
index_norm=8   # the index of norm of pow
################create routines to produce model spectra with absorption lines
for a in 0 1 2 3
do
echo "linewidth: ${linewidth[$a]} km/s with a step of velocity: ${vstep_list[$a]} km/s"
routine_sim=${DIR_home}/simulated_lw${linewidth[$a]}_model.xcm

echo "logxi = " ${xi_min} "-" ${xi_max} ", with step " ${xi_step}	
echo "start to make the routine file to generate model"
echo "@${xspec_startup_xcm}" > ${routine_sim}
echo "query yes"            >> ${routine_sim}
echo "abun lpgs"            >> ${routine_sim}
echo "model zashift*mtable{xabs_xs.fits}*pow"     >> ${routine_sim}
echo "/*"                   >> ${routine_sim}
echo "new ${index_redshift} ${redshift} "                   >> ${routine_sim}
echo "new ${index_fc} 1 "                   >> ${routine_sim}
echo "new ${index_gamm} 0 "                   >> ${routine_sim}  ### we want a flat continuum
echo "new ${index_v} ${linewidth[$a]}"                 >> ${routine_sim}

echo "start to generate loop" 
echo "cpd /null"                    >> ${routine_sim}
IFS=$'\n';
for LINE in $(cat ${NH_dir}/NH_logxi_grids_lw${linewidth[$a]}.txt)
do
	xi=$(echo ${LINE} | awk '{ print $1}')
	NH=$(echo ${LINE} | awk '{ print $2}')
	echo "logxi: ${xi}; NH: ${NH} 1e24 cm^-2 "
	echo "#logxi: ${xi}; NH: ${NH}" >> ${routine_sim}
	echo "new ${index_NH} ${NH} "             >> ${routine_sim}
	echo "new ${index_logxi} ${xi} "         >> ${routine_sim}

	#	echo "start to generate loop" 
	for j in $(seq ${zv_min} ${vstep_list[$a]} ${zv_max})
		do 
		z=`echo "scale=7;${j}/-300000" | bc`
		echo "new ${index_z} ${z},0.01,-1,-1,1,1"                 >> ${routine_sim}
		echo " "                          >> ${routine_sim}
		echo "ignore 1:**-${Emin} ${Emax}-** 2:**-1.77 8.0-**"    >> ${routine_sim}
				#echo "cpd /null"                    >> ${routine_sim}
			echo "setp e"                     >> ${routine_sim}
			echo "plot uf"                   >> ${routine_sim}
			echo "plot "                      >> ${routine_sim}
			echo "setplot command wd model_lw${linewidth[$a]}_xi${xi}_zv${j}.qdp"         >> ${routine_sim}
			echo "plot "                      >> ${routine_sim}
			echo "setplot list"               >> ${routine_sim}
			echo "mv model_lw${linewidth[$a]}_xi${xi}_zv${j}.qdp ${model_dir} "                       >> ${routine_sim}
			echo "setplot delete all"         >> ${routine_sim}	
			echo " "                          >> ${routine_sim}
		done
	done 
	echo "exit"                 >> ${routine_sim}


xspec<<EOF
@${routine_sim}
EOF

done
echo "done"
