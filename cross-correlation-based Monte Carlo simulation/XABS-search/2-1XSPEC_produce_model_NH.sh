#!/bin/bash
N_cpu=4  # Define parallelization parameters

mkdir ${PWD}/simulation
DIR_home=${PWD}/simulation
mkdir ${DIR_home}/MC_spectrum
mkdir ${DIR_home}/NH_grids
mkdir ${DIR_home}/res
NH_dir=${DIR_home}/NH_grids
MC_spectrum=${DIR_home}/MC_spectrum
res_spectrum=${DIR_home}/res
inst=(rgs epicpn)
Emin=(0.4 1.77) #keV
Emax=(1.77 10.0) #keV   RGS energy band: 0.4-1.77 keV; EPIC-pn energy band: 1.77-10.0 keV
logxi_best=1.42  # the best-fit logxi from spectral fitting, to gauge the normalization of the fitted NH vs. logxi relation 
NH_best=1.5E-04  # the best-fit  NH   from spectral fitting, to gauge the normalization of the fitted NH vs. logxi relation 

### Pre-calculate the column density at each logxi grid using the uncertainty estimation

### set scanned logxi grid
xi_min=0.0
xi_max=5.0
xi_step=0.1
linewidth=( 500 1500 4500 10000)
xspec_startup_xcm=${PWD}/nthcomp+relxillCp.xcm  #change the location of data into a global location not e.g. ../../analysis
model_plus_plamsa="constant*tbabs*zashift*mtable{xabs_xs.fits}*(nthComp+relxillCp)" #the model included an XABS_XS model, see how to generate XABS_XS in directory: /SPEX-to-XSPEC/

index_fc=7   # the index of the covering factor of XABS 
index_z=8    # the index of the redshift of XABS   
index_logxi=4 # the index of logxi of XABS 
index_v=6    # the index of line width of XABS 
index_NH=5   # the index of NH of XABS 

################create the routine to simulate spectra and run error command on NH of the plasma

routine_sim=${DIR_home}/simulated_spectrum_for_NH.xcm
echo "start to make the routine file for simulation"
echo "@${xspec_startup_xcm}"                                                                 > ${routine_sim}
echo "query yes"                                                                            >> ${routine_sim}
echo "abun lpgs"                                                                            >> ${routine_sim}
echo " "                                                                                    >> ${routine_sim}
echo "#generate real residual spectrum routine"                                             >> ${routine_sim}
echo "fakeit"                                                                               >> ${routine_sim} ### the background and response files should be in the same directory of this script
echo "y"                                                                                    >> ${routine_sim}
echo "NH_"                                                                                  >> ${routine_sim}
echo "simulated_NH_${inst[0]}.fak"                                                          >> ${routine_sim}
echo " "                                                                                    >> ${routine_sim}
echo "simulated_NH_${inst[1]}.fak"                                                          >> ${routine_sim}
echo " "                                                                                    >> ${routine_sim}
echo "ignore 1:**-${Emin[0]} ${Emax[0]}-** 2:**-${Emin[1]} ${Emax[1]}-**"                   >> ${routine_sim}
echo "fit"                                                                                  >> ${routine_sim}
echo "editmod ${model_plus_plamsa}"                                                         >> ${routine_sim}
echo "/*"                                                                                   >> ${routine_sim}
echo "fre ${index_fc} ${index_z}"                                                           >> ${routine_sim}
echo "parallel leven ${N_cpu}"                                                              >> ${routine_sim}
echo "parallel error ${N_cpu}"                                                              >> ${routine_sim}

for a in  0 1 2 3
do
	echo "line width ${linewidth[$a]} km/s"
	for xi in $(seq ${xi_min} ${xi_step} ${xi_max})
	do
	echo "new ${index_logxi} ${xi} -1"                                                  >> ${routine_sim}
	echo "new ${index_v} ${linewidth[$a]} -1"                                           >> ${routine_sim}
	echo "fit"                                                                          >> ${routine_sim}
	echo "fit"                                                                          >> ${routine_sim}
	echo "log ${NH_dir}/NH_lw${linewidth[$a]}_logxi${xi}.log"                           >> ${routine_sim}
	echo "err ${index_NH}"                                                              >> ${routine_sim}
	echo "log none"                                                                     >> ${routine_sim}
	echo " "                                                                            >> ${routine_sim}
	
	done


echo "mv simulated_NH_${inst[0]}.fak ${NH_dir} "                                            >> ${routine_sim}
echo "mv simulated_NH_${inst[1]}.fak ${NH_dir} "                                            >> ${routine_sim}
echo "mv simulated_NH_${inst[0]}_bkg.fak ${NH_dir} "                                        >> ${routine_sim}
echo "mv simulated_NH_${inst[1]}_bkg.fak ${NH_dir} "                                        >> ${routine_sim}

echo "exit"                                                                                 >> ${routine_sim}

xspec<<EOF
@${routine_sim}
EOF


echo "merge NH and logxi into one file"

outputfile=${NH_dir}/NH_lw${linewidth[$a]}.txt
rm ${outputfile}
for xi in $(seq ${xi_min} ${xi_step} ${xi_max})
do
input_file=${NH_dir}/NH_lw${linewidth[$a]}_logxi${xi}.log
if [ ! -f "${input_file}" ]
then
	echo "File ${input_file} does not exists"
else      
	NH=`grep "#     ${index_NH}" ${input_file} | awk '{print $4}'`
	echo ${xi} ${NH}  >> ${outputfile}
fi
done

python3<<EOF
import numpy as np
from scipy import optimize, stats
def para(x, m,b, c):  ###just a rough assumption, perhaps a linear function is also ok
	return m * x**b + c
def obtain_factor(x_best,y_best,m,b,c):
	return y_best/10**para(x_best,m,b,c)
dtype=[('x','float'),('y','float')]
x_best=${logxi_best}
y_best=${NH_best}   # 1e24cm^-2
infile='${NH_dir}/NH_lw'+str(${linewidth[$a]})+'.txt'
data = np.loadtxt(infile,dtype=dtype)
x=data['x'];y=data['y']
pars, pars_covariance = optimize.curve_fit(para, x, np.log10(y), [1e-3,2,1e-5])
f=obtain_factor(x_best,y_best,pars[0],pars[1],pars[2])   ###roughly correct the predicted NH based on fitting results
y_save=f*10**para( x, pars[0],pars[1],pars[2])
fmts='%.2f','%.9f'
np.savetxt('${NH_dir}/'+'NH_logxi_grids_lw'+str(${linewidth[$a]})+'.txt', np.column_stack([x,y_save]),fmt='%.9f')  
EOF

done
echo "done"
