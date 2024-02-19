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

routine_sim=${DIR_home}/plot_continuum_model.xcm
echo "@${xspec_startup_xcm}" 							  			   > ${routine_sim}
echo "query yes"            							  			  >> ${routine_sim}
echo "abun lpgs"            							  			  >> ${routine_sim}
echo "data 2:2 none"        							  			  >> ${routine_sim}  ###only consider one spectrum
echo "ignore 1:**-${Emin} ${Emax}-**"                      					          >> ${routine_sim}
echo "cpd /null"                                         					          >> ${routine_sim}
echo "setp e"                                             					          >> ${routine_sim}
echo "plot uf"                                             					          >> ${routine_sim}
echo "setplot command wd continuum_model_rgs"                					          >> ${routine_sim}
echo "plot "                                                    				          >> ${routine_sim}
echo "mv continuum_model_rgs.qdp ${model_dir} "                  					  >> ${routine_sim}
echo "setplot delete all"                                          					  >> ${routine_sim}

xspec<<EOF
@${routine_sim}
EOF

################collect generated model spectra and produce the predicted residual spectra by models
for a in 0 1 2 3
do
echo "linewidth: ${linewidth[$a]} km/s with a step of velocity: ${vstep_list[$a]} km/s"
echo "merge residual spectra into one file"

python3<<EOF
import pandas as pd
import numpy as np
def where_is_str(array,string="NO"):
        index=np.where(array== string)
        return list(set(index[0]))
ystack=[]
infile_con='${model_dir}/continuum_model_rgs.qdp'
data = pd.read_csv(infile_con,skiprows=3,header=None,delimiter=' ')
index=where_is_str(np.array(data))
for i in np.arange(${xi_min}, ${xi_max}+0.01,${xi_step}):
	for j in np.arange(${zv_min},${zv_max}+1,${vstep_list[$a]}):
 		logxi='%.2f'%i
		infile='${model_dir}/'+'model_lw'+str(${linewidth[$a]})+'_xi'+str(logxi)+'_zv'+str(j)+'.qdp' 
		infile2='${model_dir}/'+'model_lw'+str(${linewidth[$a]})+'_xi'+str(logxi)+'_zv'+str(j)+'_bald.qdp' 
  		data_raw=pd.read_csv(infile,header=None, skiprows=3,delimiter=' ')
    		data_raw2=pd.read_csv(infile2,header=None, skiprows=3,delimiter=' ')
      		data = data_raw.drop(index); data2 = data_raw2.drop(index)
                x=np.array(data[0]);y=np.array(data[4])
                x2=np.array(data2[0]);y2=np.array(data2[4])
		if len(ystack)==0:
			ystack.append(x)
		y_sub=[n - m  for n,m in zip(y,y2)]  ###remove the effects of edges, leaving only lines
		ystack.append(y_sub)
np.savetxt('${DIR_home}/'+'merge_model_lw'+str(${linewidth[$a]})+'.txt', np.array(ystack).T, fmt='%.9f')  
EOF

done
echo "done"
