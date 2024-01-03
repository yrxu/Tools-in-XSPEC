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

xspec_startup_xcm=${PWD}/nthcomp+relxillCp.xcm  #change the location of data into a global location not e.g. ../../analysis
model_plus_plasma="zashift*mtable{xabs_xs.fits}*pow"
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
	echo "new 1 ${redshift} "                   >> ${routine_sim}
	echo "new 5 1 "                   >> ${routine_sim}
	echo "new 7 0 "                   >> ${routine_sim}
	echo "new 4 ${linewidth[$a]}"                 >> ${routine_sim}
	#	echo "new 2 ${NH} -1"             >> ${routine_sim}
	echo "start to generate loop" 
	echo "cpd /null"                    >> ${routine_sim}
	IFS=$'\n';
	for LINE in $(cat ${NH_dir}/NH_logxi_grids_lw${linewidth[$a]}.txt)
	do
		#NH=$(echo "scale=8; e((${lognh}-24.0)*l(10))"| bc -l )
		xi=$(echo ${LINE} | awk '{ print $1}')
		NH=$(echo ${LINE} | awk '{ print $2}')
		echo "logxi: ${xi}; NH: ${NH} 1e24 cm^-2 "
		echo "#logxi: ${xi}; NH: ${NH}" >> ${routine_sim}
		echo "new 3 ${NH} -1"             >> ${routine_sim}
		echo "new 2 ${xi} "         >> ${routine_sim}

	#	echo "start to generate loop" 
		for j in $(seq ${zv_min} ${vstep_list[$a]} ${zv_max})
		do 
			z=`echo "scale=7;${j}/-300000" | bc`
		
		#energy=$(echo "scale=8; e((${logmin}+$y*$logestep)*l(10))"| bc -l )
		#lw=$(echo "scale=8; ${energy}*${linewidth[$a]}/300000"| bc -l )
			#echo "#logxi: ${xi}; z: ${z}" >> ${routine_sim}
	#echo "index" $(($y+1))"/"${num_points}

			echo "new 6 ${z},0.01,-1,-1,1,1"                 >> ${routine_sim}
			echo " "                          >> ${routine_sim}
			echo "ignore 1:**-0.4 1.77-** 2:**-1.77 8.0-**"    >> ${routine_sim}
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
