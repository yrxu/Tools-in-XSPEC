#!/usr/bin/env python
#run source $SPEX90/spexdist.sh first!

import numpy as np
import os
import subprocess
import multiprocessing as mp
import shutil


grid_dir='emission_grid'
if os.path.exists(grid_dir):
    shutil.rmtree(grid_dir)
os.makedirs(grid_dir)

#os.mkdir(grid_dir)

# ionization parameter grids logxi= -2 to 5
logxi_vals=np.linspace(-2,5,20)
# column density in the unit of cm^-2 range between 1e18 and 2e24 cm^-2
col_density_vals=np.logspace(-6,np.log10(2),9)
# spectral slope of the irradiation field Gamma= 1.5 to 3
gamma_vals=np.linspace(1.5,3,9)
# solid angle of emitting gas normalized by 4 pi, range between 0 to 1
omeg_vals=np.linspace(0,1,5)
# turbulent velocity km/s between 100 to 1e5 km/s
v_vals=np.logspace(np.log10(100),np.log10(100000),9)
### add any parameter you want, otherwise use the default values of PION

##parallelization function
def jobsub_call(fname):
    subprocess.call(["bash %s" % (fname)], shell=True)
    pass

### use a quarter of CPU numbers of the laptop
Ncpus=int(mp.cpu_count()/4)
#Ncpus=int(10)
pool=mp.Pool(Ncpus)
print("Running in parallel on",Ncpus,"CPUs")
i=0
filenames=[]
for xi in logxi_vals:
    for col_density in col_density_vals:
        for gamma in gamma_vals:
            for v in v_vals:
                for omeg in omeg_vals:
                    modstr="xi%s_nH%s_gamma%s_v%s_omeg%s" % (str(xi),str(col_density),str(gamma),str(v),str(omeg))
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
                                            ["com po", \
                                            "com pion",\
                                            "com etau",\
                                            "com etau",\
                                            "com etau",\
                                            "com rel 1 3,4,2,5"]
                                            )+"\n\n"


                        fixed_pars="\n".join(
                                            ["par 5 a v 0",\
                                            "par 5 tau v 1000",\
                                            "par 3 a v -1",\
                                            "par 3 tau v 0.136",\
                                            "par 4 a v 1",\
                                            "par 4 tau v 0.01",\
                                            "par 2 fcov v 0"]
                                            )+"\n"

                        variable_pars="\n".join(["par 2 xil v %s" % str(xi),\
                                                "par 2 nh v %s" % str(col_density),\
                                                "par 1 gamm v %s" % str(gamma),\
                                                "par 2 omeg v %s" % str(omeg),\
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
