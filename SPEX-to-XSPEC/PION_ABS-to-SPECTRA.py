#!/usr/bin/env python
#run source $SPEX90/spexdist.sh first!

import numpy as np
import os
import subprocess
import multiprocessing as mp
import shutil


# ionization parameter grids logxi= 0 to 7
logxi_vals=np.linspace(0,7,21)
# column density in the unit of cm^-2 range between 1e19 and 1e25 cm^-2
col_density_vals=np.logspace(-5,1,13)
# covering fraction of absorbing gas, range between 0 to 1
fcov_vals=np.linspace(0,1,3)
# turbulent velocity km/s between 100 to 1e5 km/s
v_vals=np.logspace(0,4,9)
### add any parameter you want, otherwise use the default values of PION

##parallelization function
def jobsub_call(fname):
    subprocess.call(["bash %s" % (fname)], shell=True)
    pass

### use a quarter of CPU numbers of the laptop
Ncpus=int(10)
pool=mp.Pool(Ncpus)
print("Running in parallel on",Ncpus,"CPUs")
i=0
ID=['PG1211']
for u in range(len(ID)):
    grid_dir='pion_absorption_grid_'+ID[u]
    if os.path.exists(grid_dir):
        shutil.rmtree(grid_dir)
    os.makedirs(grid_dir)

    SED_file="PION_SED_"+ID[u]+"_keV_photonserg.out" ## SED file input into PION, Y-axis: photon/s/keV, X-axis: keV
    norm_SED=1
    filenames=[]
    for xi in logxi_vals:
        for col_density in col_density_vals:
            for v in v_vals:
                for fc in fcov_vals:
                    modstr="xi%s_nH%s_v%s_fc%s" % (str(xi),str(col_density),str(v),str(fc))
                    fname=grid_dir+"/piongrid_%s.sh" % modstr
                    spec_fname=grid_dir+"/piongrid_%s" % modstr
                    if not os.path.exists(spec_fname+'.qdp'):
                        i+=1
                        print("submitting job",i)
                        print(spec_fname+'.qdp')
                        filenames.append(fname)
                        outfile=open(fname,"w")

                        preamble=("#!/usr/bin/env bash\n\nspex<<EOF\n\n")

                        components="\n".join(
                                            ["com file", \
                                            "com pion",\
                                            "com rel 1 2"]
                                            )+"\n\n"


                        fixed_pars="\n".join(
                                            ["par 1 norm v "+str(norm_SED),\
                                            "par 1 file av "+SED_file,\
                                            "egr log 1e-3:1e3 2e4 ",\
                                            "par 2 fcov v 1"]
                                            )+"\n"

                        variable_pars="\n".join(["par 2 xil v %s" % str(xi),\
                                                "par 2 nh v %s" % str(col_density),\
                                                "par 2 fc v %s" % str(fc),\
                                                "par 2 v v %s" % str(v),\
                                                "calc"])+"\n"

                        plotting="\n".join(
                                    ["pl dev null",\
                                    "pl ty mo",\
                                    "pl ux ke",\
                                    "pl uy cou",\
                                    "p rx 0.1 10",\
                                    "p ry 0 0.01",\
                                    "p x  lin",\
                                    "p y  lin",\
                                    "p fil dis f",\
                                    "p",\
                                    "plot adum %s over" % spec_fname])+"\n"

                        post="q\nEOF"

                        outfile.write(preamble+components+fixed_pars+variable_pars+plotting+post)
                        outfile.flush()
                        outfile.close()


    pool.map(jobsub_call,filenames)

    # Loop through all files in the directory
    for filename in os.listdir(grid_dir):
        # Check if the file ends with .sh
        if filename.endswith(".sh"):
            # Construct absolute file path
            file_path = os.path.join(grid_dir, filename)
            # Remove the file
            os.remove(file_path)
            print(f'Removed: {file_path}')
                                                                                     
