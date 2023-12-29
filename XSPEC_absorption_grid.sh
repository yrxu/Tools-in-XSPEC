#!/bin/bash

###initials
DIR=${PWD}

ID=( 01 02 03 04 ) ###name of spectra
length=`echo "${#ID[@]}-1" | bc`

model_name="nthcomp+relxillCp" ## model name / root name of the .xcm file e.g. nthcomp+relxillCp_01.xcm
model_include_plasma_model="constant*tbabs*zashift*mtable{xabs_xs.fits}*(nthcomp+relxillCp)"

type=XABS ##perform absorption model scan

index_NH=5
index_logxi=4
index_v=6
index_zv=8
index_fc=7
N_plasma=4 #the order of plasma model in XSPEC model combination, here is the 4th component

###scan mainly divided by logxi, this split is to reduce the cache space 
part_list=(all 01 02 03 04 05)
xi_min_list=(-3.0 -3.0  -1.24 0.36 1.96 3.56)  
xi_max_list=(5.01 -1.4  0.2   1.8  3.4  5.01)  

for k in 0 ##scan between logxi=-3 to 5  
do
part=${part_list[$k]}
xi_min=${xi_min_list[$k]}         
xi_max=${xi_max_list[$k]}        
xi_step=0.1       # step of logxi

###zv grids, expected to be blueshifted
zv_min=0           # 0 normally 0 km/s (gas at rest)
zv_max=105000      # 105000 to have up to at least >=0.3c (after Relativistic correction)

###line width and corresponding velocity steps
width_list=(100 250 500 1500 2500 4500 10000) # Line widths to be adopted in km/s
vstep_list=(300 300 500 700 1000 1500 2500)   # Velocity steps to adopted in km/s
N_of_width=4       # ="${#width_list[@]}" for all line widths (how many to run)
min_item=3         # =0 to start from 1st of the line widths (from which to start)


statistics=cstat #statistics used in XSPEC
abundance=lpgs   #abundace used for Galactic absorption model i.e. TBabs

number_of_cores=4 # Define parallelization parameters
echo "choosing number of cores =${number_of_cores}"

###################### 2) DEFINITION OF DIRECTORIES AND VARIABLES ################################

for u in $(seq 0 1 ${length}) # loop over spectra
do

mkdir ${DIR}/${type}_grids_${ID[${u}]}
DIR_home=${DIR}/${type}_grids_${ID[${u}]}

### !!! Caution: the data files in .xcm file must have the global location rather than e.g. ../pn.fits
xspec_startup_xcm=${DIR}/${model_name}_${ID[$u]}.xcm  

mkdir ${DIR_home}/part_${part}            # Where each individual fit is saved
mkdir ${DIR_home}/part_${part}/linegrid            # Where each individual fit is saved

DIR_outgrid=${DIR_home}/part_${part}/linegrid

################### 3) CREATION OF THE XSPEC ROUTINE FOR THE GRID  ####################################

max_item=`echo "${N_of_width}-1" | bc`

for item in $(seq ${min_item} 1 ${max_item}) # 1) LOOP OVER LINE WIDTH
do

width=${width_list[${item}]}

zv_step=${vstep_list[${item}]}

echo "Line Width = ${width} km/s, assiming grid Step = ${zv_step} km/s" # Check: print the velocities

results_file_1=${DIR_home}/part_${part}/${type}_${width}_kms_2Df.dat    # OUTPUT 1: 2col file

detection_routine=${DIR_home}/part_${part}/xspec_det_routine_w${width}kms.xcm

echo "Running XSPEC detection routine for width = ${width} km/s"
echo "# Photoionization model scan, line width = ${width}kms "                  > ${detection_routine}
echo "query yes"                                                               >> ${detection_routine}
echo "abun ${abundance}"                                                       >> ${detection_routine}
echo "statistic ${statistics}"                                                 >> ${detection_routine}
echo "parallel leven ${number_of_cores}"                                       >> ${detection_routine}
echo "parallel error ${number_of_cores}"                                       >> ${detection_routine}


echo "# C-stat  NH   Log_xi  z  v (km/s)" >  ${results_file_1}
echo "# "                                 >> ${results_file_1}


for xi_start in $(seq ${xi_min} ${xi_step} ${xi_max}) # 2) LOOP OVER LOG_XI
do

###set suitable NH initial values given logxi to avoid falling in local minima
if [ `echo "${xi_start}>=-3.0" | bc` -eq 1 ] && [ `echo "${xi_start}<1.3" | bc` -eq 1 ]
then
      nh_start=1.e-4

elif [ `echo "${xi_start}>=1.3" | bc` -eq 1 ] && [ `echo "${xi_start}<1.8" | bc` -eq 1 ]
then
      nh_start=5.e-4

elif [ `echo "${xi_start}>=1.8" | bc` -eq 1 ] && [ `echo "${xi_start}<4.0" | bc` -eq 1 ]
then
      nh_start=1.e-3

elif [ `echo "${xi_start}>=4.0" | bc` -eq 1 ] && [ `echo "${xi_start}<4.5" | bc` -eq 1 ]
then
      nh_start=1.e-2

elif [ `echo "${xi_start}>=4.5" | bc` -eq 1 ] && [ `echo "${xi_start}<4.8" | bc` -eq 1 ]
then
      nh_start=2.e-2

elif [ `echo "${xi_start}>=4.8" | bc` -eq 1 ] && [ `echo "${xi_start}<5.4" | bc` -eq 1 ]
then
      nh_start=3.e-2
else
      nh_start=1.e-1
fi

echo "XSPEC code for ${type} Log_xi = ${xi_start} and N_H (start) = ${nh_start}" 

for j in $(seq ${zv_min} ${zv_step} ${zv_max})  # 3) LOOP OVER ZV_LOS
do

z=`echo "scale=7;${j}/-300000" | bc`

echo " "                                                                       >> ${detection_routine}
echo "@${xspec_startup_xcm}"                                                   >> ${detection_routine}
echo "fit"                                                                     >> ${detection_routine}
echo "editmod ${model_include_plasma_model}"                                   >> ${detection_routine}
echo "/*"                                                                      >> ${detection_routine}
echo "fre ${index_fc}"                                                         >> ${detection_routine}
echo "new ${index_zv}"                                                         >> ${detection_routine}
echo "${z},-1,-0.5,-0.5,0.5,0.5"                                               >> ${detection_routine}
echo "new ${index_v} ${width},-1"                                              >> ${detection_routine}
echo "new ${index_logxi} ${xi_start} -1 "                                      >> ${detection_routine}
echo "new ${index_NH} ${nh_start} "                                            >> ${detection_routine}
echo "fit"                                                                     >> ${detection_routine}
echo "fit"                                                                     >> ${detection_routine}
echo "log ${DIR_outgrid}/${type}_${width}_${xi_start}_${z}.log"                >> ${detection_routine}
echo "show all"                                                                >> ${detection_routine}
echo "log none"                                                                >> ${detection_routine}

done
done

###################### 4) EXECUTION OF THE XSPEC ROUTINE FOR THE GRID  ################################
###

xspec<<EOF
@${detection_routine}
EOF

################# 5) READ THE XSPEC RESULTS IN ONE FILE PER LINE WIDTH  ###############################



for xi_start in $(seq ${xi_min} ${xi_step} ${xi_max})
do 
   for j in $(seq ${zv_min} ${zv_step} ${zv_max})  # 3) LOOP OVER ZV_LOS
    do

    z=`echo "scale=7;${j}/-300000" | bc`

    input_file=${DIR_outgrid}/${type}_${width}_${xi_start}_${z}.log # individual fit results to read

if [ ! -f "${input_file}" ]
then
test_command=0 # if file for a certain point does not exist, ignore it or comment next line to track
echo "File ${input_file} does not exists"
else
	cstat=`grep '#Total fit statistic ' ${input_file} | awk '{print $4}'`
	NH=`grep "#   ${index_NH}    ${N_plasma}   ${type}TABLE  column" ${input_file} | awk '{print $6}'`
	echo ${cstat} ${NH} ${xi_start} ${z} ${width} >> ${results_file_1} # update output1
fi 
done
done


done
done
cd ${DIR}
done
echo "Done."
###################################### END OF THE ROUTINE ############################################
