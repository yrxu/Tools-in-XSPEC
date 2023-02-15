######### extract error results
######### assume the infile is created by log XXX.txt and fit with error, each line starts from '#'
######### assume the table appears before the final error results display
import numpy as np
import math
##########round the results into conventional precision
def precision(value, left_uncertainty,right_uncertainty):
        rounded_value_collect=[]
        absolute_left_uncertainty_collect=[]
        absolute_right_uncertainty_collect=[]
        for i,j,k in zip(value,left_uncertainty,right_uncertainty):
            v=float(i);l_err=-float(j);r_err=float(k)
            uncertainty=min([abs(l_err),abs(r_err)])
            if uncertainty>=1:    ####if the uncertainty is larger than unity, choose the precision to digits
                rounded_value = int(round(v, 1))
                absolute_left_uncertainty = int(round(l_err, 1 ))
                absolute_right_uncertainty = int(round(r_err, 1 ))
            else:
                rounded_value = round(v, -int(math.floor(math.log10(uncertainty))) )
                absolute_left_uncertainty = round(l_err, -int(math.floor(math.log10(l_err))) )
                absolute_right_uncertainty = round(r_err, -int(math.floor(math.log10(r_err))) )
            if l_err==v and r_err==-v: ####if reach the upper or lower limit, set the uncertainty to zero
                rounded_value=0
                absolute_left_uncertainty=0
                absolute_right_uncertainty=0   
            elif l_err==v:
                absolute_left_uncertainty = 0
            elif  r_err==-v:
                absolute_right_uncertainty = 0
            rounded_value_collect+=[rounded_value]
            absolute_left_uncertainty_collect+=[absolute_left_uncertainty]
            absolute_right_uncertainty_collect+=[absolute_right_uncertainty]
        return rounded_value_collect,absolute_left_uncertainty_collect,absolute_right_uncertainty_collect

#### parameter names+units    feel free to add any parameters and units you want
p_name={
        
        'column':'$N_\mathrm{H}$ ($10^{21}$\,cm$^{-2}$)', 
        'v':'$\sigma_\mathrm{v}$ (km/s)',
        'z':'$z_\mathrm{LOS}$ ', 
        'Gamma':'$\Gamma$', 
        'gamma':'$\Gamma$', 
        'norm':' $N_\mathrm{XX}$ ($10^{-3}$)',
        'nH':'$N^\mathrm{Gal}_\mathrm{H}$ ($10^{20}$ cm$^{-2}$)',
        'h':'$h$ ($R_\mathrm{Horizon}$) ',
        'a':'$a_\star$ ($cJ/GM^2$)',
        'Incl':'$i$ (deg)',
        'Rin':'$R_\mathrm{in}$ (${R_\mathrm{ISCO}}$)',
        'Rin_G':'$R_\mathrm{in}$ (${R_\mathrm{g}}$)',
        'Afe':'$A_{\mathrm{Fe}}$',
        'kTe':'$kT_\mathrm{e}$ (keV)',
        'kT_e':'$kT_\mathrm{e}$ (keV)',
        'refl_frac':'$f_\mathrm{Refl}$',
        'Index1':'$q$',
        'Index':'$q$',
        'logN':'$\log{[n_\mathrm{e}/\mathrm{cm}^{-3}]}$',
        'logxi':'$\log(\\xi/\mathrm{erg\,cm\,s^{-1})}$',
        'Tin':'$kT_\mathrm{e}$ (keV)',
        'lineE':'$E$ (keV)'
       }

##### source name and spectra name
##### e.g. PG1244+026; run error on stacked, flux-resolved spectra
source='PG1244+026'   
ID=['avg','40','41','42','43'] ### exmaple
model_name='WA_nthcomp+relxillCp'    ##### the name of the file, see the 'infile' variable below.
read_dir='D:/INAF/Sample_study/'+source+'/error_results'   ##### directory

##### Initialization
storage_index=[]
storage_component=[]
storage_component_index=[]
storage_name=[]
storage_para=[]
storage_cstat=[]
storage_dof=[]

baseline_para_index=[]
baseline_para_name=[]
baseline_para_component=[]
baseline_para_component_index=[]

#### loop for each spectrum
for i in range(len(ID)):
    index_fp=[]
    name_fp=[]
    best_fp=[]
    left_err_fp=[]
    right_err_fp=[]
    cstat=np.inf
    component=[]
    component_index=[]
    error_index=[]
    ##### my personal naming habits: avg without any suffix
    if ID[i]=='avg':
        infile=read_dir+'/error_'+model_name+'.txt'
    else:
        infile=read_dir+'/error_'+model_name+'_'+ID[i]+'.txt'
    
    #### read each line
    with open(infile,'r') as f:
        for l in f:
            row=l.split()
            #### get errors
            if len(row)>=2 and (row[1] in index_fp) and row[-1][-1]==')':
                left=row[-1].split(',')[0][1:]
                right=row[-1].split(',')[1][:-1]
                if row[1] in error_index: #### check if the error result of the parameter has been saved, if yes, replace with new one
                    index_temp=error_index.index(row[1])
                    left_err_fp[index_temp]=left
                    right_err_fp[index_temp]=right
                else:
                    error_index+=[row[1] ]
                    left_err_fp+=[left]
                    right_err_fp+=[right]

            if len(row)>6:
                ##### get cstat and dof
                if row[-1]=='d.o.f.' and float(row[3])<float(cstat):
                    cstat=row[3]
                    dof=row[5]
                ##### get parameter best-fit
                if row[-2]=='+/-' and row[2]!='1':
                    if row[1] in index_fp:#### check if the best-fit of the parameter has been saved, if yes, replace with new one
                        index_temp=index_fp.index(row[1])
                        best_fp[index_temp]=row[-3]
                    else:
                        index_fp+=[row[1]]
                        component+=[row[3]]
                        name_fp+=[row[4]]
                        best_fp+=[row[-3]] 
                        component_index+=[row[2]]

    ##### since some parameters during the error will not appear, re-order the error results according to the best-fit values
    left_error_fp_ordered=[]
    right_error_fp_ordered=[]
    for o in range(len(index_fp)):
        temp=error_index.index(index_fp[o])
        left_error_fp_ordered+=[left_err_fp[temp]]
        right_error_fp_ordered+=[right_err_fp[temp]]
        
    best_fp_rounded,left_err_fp_rounded,right_err_fp_rounded=precision(best_fp, left_error_fp_ordered,right_error_fp_ordered) ###round results
   
    ##### combine results of parameters
    parameters=['$'+str(i)+'^{+'+str(k)+'}'+'_{-'+str(j)+'}'+'$' for i,j,k in zip(best_fp_rounded,left_err_fp_rounded,right_err_fp_rounded)]
    
    ##### save results
    storage_index+=[index_fp]
    storage_component+=[component]
    storage_component_index+=[component_index]
    storage_name+=[name_fp]
    storage_para+=[parameters]
    storage_cstat+=[cstat]
    storage_dof+=[dof]

    ##### choose the average/first spectrum as the baseline (the maximal number of free parameters) 
    if ('avg' in ID):
        if ID[i]=='avg':
            baseline_para_index=index_fp
            baseline_para_name=name_fp
            baseline_para_component=component
            baseline_para_component_index=component_index
    else:
        if i==0: ### Caution: risky if fix some parameters only in the first spectrum! Usually seldom occur
            baseline_para_index=index_fp
            baseline_para_name=name_fp
            baseline_para_component=component
            baseline_para_component_index=component_index

##### title
title='Description'+' & '+'Parameter'
for i in ID:
    title+=' & '+i
title=title+' \\'+'\\'

##### statistics
statistic='& C-stat/d.o.f.'
for i in range(len(storage_cstat)):
    statistic+=' & '+storage_cstat[i]+'/'+storage_dof[i]
statistic=statistic+' \\'+'\\'

##### combine each line of the main content of table
avg_length=max([len(i) for i in storage_index])
collect_all=[]
for i in range(avg_length):
    ind_base=baseline_para_index[i]
    
    #### remove the duplicate component name
    if i!=0:
        if baseline_para_component_index[i]==baseline_para_component_index[i-1]: 
            component_name=' '
            collect_begin=component_name+' & '+p_name[baseline_para_name[i]]
        else:
            component_name=baseline_para_component[i]
            collect_begin=component_name+' & '+p_name[baseline_para_name[i]]
    else:
        collect_begin=baseline_para_component[i]+' & '+p_name[baseline_para_name[i]]
        
    #### load parameters
    collect_mid=''
    for j in range(len(ID)):
        if ind_base in storage_index[j]: ####If the parameter is not free in non-avg spectrum, just let them empty
            temp=storage_index[j].index(ind_base)
            add=storage_para[j][temp]
        else:
            add=' '
        collect_mid+=' & '+add
    collect=collect_begin+collect_mid+' \\'+'\\'
    collect_all+=[collect]

#### output
with open(read_dir+'/model_table.txt', "w") as file:
    file.write(title+"\n")
    for string in collect_all:
        file.write(string + "\n")
    file.write(statistic+"\n")
