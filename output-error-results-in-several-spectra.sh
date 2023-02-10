#!/bin/bash
#### e.g.PG1211+143 observations
####     I want to run the error on the spectrum and extract the parameters of xabs_xs: nh, logxi, v, zv into four files with their errorbars.
ID=( 0112610101 0208020101 0502050101 0502050201 0745110101 0745110201 0745110301 0745110401 0745110501 0745110601 0745110701)

### my model name
model_name="WA_diskbb+relxillCp"   

#### select the number of CPU cores you want to use
core=4

#### parameter index you want to run error
para_begin=4
para_end=24


DIR=${PWD}
length=`echo "${#ID[@]}-1" | bc`

nh_result_file=${DIR}/nh.txt
echo "# ID nh left_error right_error" > ${nh_result_file}
nh_index=5  #### parameter index of nh

logxi_result_file=${DIR}/logxi.txt
echo "# ID logxi left_error right_error" > ${logxi_result_file}
logxi_result_file_index=4  #### parameter index of logxi_result_file

v_result_file=${DIR}/v.txt
echo "# ID v left_error right_error" > ${v_result_file}
v_index=6  #### parameter index of v

zv_result_file=${DIR}/zv.txt
echo "# ID zv left_error right_error" > ${zv_result_file}
zv_index=8  #### parameter index of zv

for u in $(seq 0 1 ${length})
do
detection_routine=${DIR}/${model_name}_${ID[$u]}.xcm
xspec<<EOF
@${detection_routine}
query yes
para error ${core}
para leven ${core}
fit
log error_${model_name}_${ID[$u]}.txt
err ${para_begin}-${para_end}    
log none
tclout param ${nh_index}
scan \$xspec_tclout "%f" nh
tclout error ${nh_index}
scan \$xspec_tclout "%f %f" lerr_nh rerr_nh
echo ${ID[$u]} \$nh \$lerr_nh \$rerr_nh
echo ${ID[$u]} \$nh \$lerr_nh \$rerr_nh >> ${nh_result_file}
tclout param ${logxi_result_file_index}
scan \$xspec_tclout "%f" logxi
tclout error ${logxi_result_file_index}
scan \$xspec_tclout "%f %f" lerr_logxi rerr_logxi
echo ${ID[$u]} \$logxi \$lerr_logxi \$rerr_logxi
echo ${ID[$u]} \$logxi \$lerr_logxi \$rerr_logxi >> ${logxi_result_file}
tclout param ${v_index}
scan \$xspec_tclout "%f" v
tclout error ${v_index}
scan \$xspec_tclout "%f %f" lerr_v rerr_v
echo ${ID[$u]} \$v \$lerr_v \$rerr_v
echo ${ID[$u]} \$v \$lerr_v \$rerr_v >> ${v_result_file}
tclout param ${zv_index}
scan \$xspec_tclout "%f" zv
tclout error ${zv_index}
scan \$xspec_tclout "%f %f" lerr_zv rerr_zv
echo ${ID[$u]} \$zv \$lerr_zv \$rerr_zv
echo ${ID[$u]} \$zv \$lerr_zv \$rerr_zv >> ${zv_result_file}
save all ${model_name}_${ID[$u]}.xcm
y
EOF
done
