#!/bin/bash

###initials
home_dir=$PWD                                        # Launching directory

ID=( 01 02 03 04 )  #names of spectra
length=`echo "${#ID[@]}-1" | bc` #number of spectra

model_name="nthcomp+relxillCp" #model name / root name of the .xcm file e.g. nthcomp+relxillCp_01.xcm
model_plus_gaussian="constant*tbabs*zashift*(nthComp+relxillCp+gauss)" #the model included a Gaussian in XSPEC

index_energy=24 #the index of the line energy in Gaussian model in XSPEC, then N_energy+1= index of line width, N_energy+2= index of normalization
index_width=$(($index_energy+1))
index_norm=$(($index_energy+2))
N_gauss=6 #the order of Gaussian in XSPEC model combination, here is the 6th component 

line_width=(500 1500 4500)  #scanned line width
number_of_points=(2000 700 300) #number of scanned grids corresponding to line width

statistics=cstat #statistics used in XSPEC
abundance=lpgs   #abundace used for Galactic absorption model i.e. TBabs
Emin=0.4  # keV scanned energy band
Emax=10.0  # keV 

number_of_cores=4 # Define parallelization parameters
echo "choosing number of cores =${number_of_cores}"

###start loop
### !!! Caution: the data files in .xcm file must have the global location rather than e.g. ../pn.fits

for u in $(seq 0 1 ${length}) 
do

mkdir ${home_dir}/Gaussian_${ID[$u]}               
mkdir ${home_dir}/Gaussian_${ID[$u]}/linegrid   

work_dir=${home_dir}/Gaussian_${ID[$u]}                          #DIR where XSPEC will be executed
startup_xspec_continuum=${home_dir}/${model_name}_${ID[$u]}.xcm  # XSPEC startup .xcm file (load data and continuum model)
read_dir=${work_dir}/linegrid       # DIR where XSPEC outputs are to be read
out_dir=${work_dir}                                  # DIR where final results are saved


# Define routine and run XSPEC
number_of_width=`echo "${#line_width[@]}-1" | bc`
echo "number of line width: ${number_of_width}"
for w in $(seq 0 1 ${number_of_width})
do

width=${line_width[$w]}
detection_routine=${work_dir}/xspec_det_routine_w${width}kms.xcm # Note ".com" is removed for SPEX input

echo "Running XSPEC detection routine for width = ${width} km/s"

cd ${home_dir}

echo "query yes"                                > ${detection_routine}
echo "statistic ${statistics}"                  >> ${detection_routine}
echo "abund ${abundance}"                       >> ${detection_routine}
echo "para leven ${number_of_cores}"            >> ${detection_routine}
echo "para error ${number_of_cores}"            >> ${detection_routine}

python3<<EOF
import numpy as np
import math
outdir="${work_dir}"
c=3.0e5        # lightspeed in km/s
Log_E=np.logspace(math.log10(${Emin}), math.log10(${Emax}), num=${number_of_points[$w]})
np.set_printoptions(precision=6)
np.set_printoptions(formatter={'float': '{: 0.6f}'.format})
np.savetxt(str(outdir)+'/Log_E_grid_'+str(${Emin})+'-'+str(${Emax})+'keV_'+str(${width})+'kms.txt',Log_E,delimiter=' ', fmt='%1.6f')
EOF

for i in `cat ${work_dir}/Log_E_grid_${Emin}-${Emax}keV_${width}kms.txt`
do
	energy=$(echo "$i" | bc)
	line_width_energy=`echo "scale=7;${width}*${energy}/300000." | bc` ###transfer the line width into energy
	echo "Updating code in the file ${detection_routine} for Energy ${i} keV and LW ${line_width_energy} keV"

	echo " "                                             >> ${detection_routine}
	echo "@${startup_xspec_continuum}"                   >> ${detection_routine}
	echo "editmod ${model_plus_gaussian}"                >> ${detection_routine}
	echo "/*"                                            >> ${detection_routine}
	echo "query yes"                                     >> ${detection_routine}
	echo "fre ${index_energy} ${index_width}"            >> ${detection_routine}
	echo "new ${index_energy} ${i}"                      >> ${detection_routine}
	echo "new ${index_width}  ${line_width_energy}"      >> ${detection_routine}
	echo "new ${index_norm}  "                           >> ${detection_routine}
	echo "1e-4,0.1,-1e+20,-1e+20,1e+20,1e+24"            >> ${detection_routine}
	echo "fit"                                           >> ${detection_routine}
	echo "fit"                                           >> ${detection_routine}
	echo "fit"                                           >> ${detection_routine}
	echo "sho all"                                       >> ${detection_routine}
	echo "err ${index_norm}"                             >> ${detection_routine}
	echo "log ${read_dir}/line_${width}kms_${i}_keV.log" >> ${detection_routine}
	echo "sho all"                                       >> ${detection_routine}
	echo "log none"                                      >> ${detection_routine}
done
echo "	exit" >> ${detection_routine}

xspec<<EOF
@${detection_routine}
EOF


cd ${home_dir}

# Read all results (linegrid) into a file for each line width

output_file=${out_dir}/results_gaus_${width}kms.txt

echo "# Energy ${statistics}  Norm " >  ${output_file}

for i in `cat ${work_dir}/Log_E_grid_${Emin}-${Emax}keV_${width}kms.txt`
do
echo ${i}
energy=$(echo "$i" | bc)

input_file=${read_dir}/line_${width}kms_${i}_keV.log
echo "energy:${energy}"

if [ ! -f "${input_file}" ]
then
	echo "${input_file} does not exists"
else
   	CSTAT=`grep '#Total fit statistic ' ${input_file} | awk '{print $4}'`
        GNORM=`grep "#  ${index_norm}    ${N_gauss}   gaussian   norm" ${input_file} | awk '{print $6}'`
	echo ${i} ${CSTAT} ${GNORM}
	echo ${i} ${CSTAT} ${GNORM} >> ${output_file}

fi

done

echo "Done: Gaussian line scan has been saved in file: ${output_file}"
done
done
