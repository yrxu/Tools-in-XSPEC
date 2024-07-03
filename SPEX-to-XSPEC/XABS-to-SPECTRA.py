#!/usr/bin/env python
#run source $SPEX90/spexdist.sh first!

import numpy as np
import os
import subprocess
import multiprocessing as mp
import shutil

grid_dir='absorption_grid'
if os.path.exists(grid_dir):
    shutil.rmtree(grid_dir)
os.makedirs(grid_dir)

# ionization parameter grids logxi= -3 to 5
logxi_vals=np.linspace(0,7,25)
# column density in the unit of cm^-2 range between 1e18 and 2e24 cm^-2
column_vals=np.logspace(np.log10(1e-5) ,np.log10(10),25)
# turbulent velocity km/s between 100 to 1e4 km/s
v_vals=np.logspace(0,4.48,10)
# covering factor of absorbing gas, range between 0 to 1
fcov_vals=np.linspace(0,1,3)

##parallelization function
def jobsub_call(fname):
    subprocess.call(["bash %s" % (fname)], shell=True)
    pass

### use a quarter of CPU numbers of the laptop
#Ncpus=int(mp.cpu_count()/4)
Ncpus=int(10)
pool=mp.Pool(Ncpus)
print("Running in parallel on",Ncpus,"CPUs")
i=0
ionfile="xabs_inputfile_corr1"  ###ionization balance, calculated by using xabsinput
fname="xabsgrid_ufopcov.sh"
filenames=[]
for xi in logxi_vals:
    for column in column_vals:
        for v in v_vals:
            for fcov in fcov_vals:
                modstr="xi%s_column%s_v%s_fcov%s" % (str(xi), str(column), str(v), str(fcov))
                fname=grid_dir+"/xabsgrid_%s.sh" % modstr
                spec_fname=grid_dir+"/xabsgrid_%s" % modstr
                if not os.path.exists(spec_fname+'.qdp'):
                    i+=1
                    print("submitting job",i)
                    print(spec_fname+'.qdp')
                    filenames.append(fname)
                    outfile=open(fname,"w")
                    preamble=("#!/usr/bin/env bash\n\nspex<<EOF\n\n")

                    components="\n".join(
                            ["com po", \
                            "com xabs",\
                            "com rel 1 2"]
                            )+"\n\n"

                    fixed_pars="\n".join(
                            ["par 1 gamm v 2",\
                            "par 1 norm v 1",\
                            "par 2 col av "+ionfile,\
                            "par 2 fcov v 1"]
                            )+"\n"

                    variable_pars="\n".join(["par 2 xil v %s" % str(xi),\
                                        "par 2 nh v %s" % str(column),\
                                        "par 2 v v %s" % str(v),\
                                        "par 2 fcov v %s" % str(fcov),\
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


