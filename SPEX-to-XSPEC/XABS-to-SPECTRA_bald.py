#!/usr/bin/env python
#run source $SPEX90/spexdist.sh first!

import numpy as np
import os
import subprocess
import multiprocessing as mp
import shutil

grid_dir='absorption_grid_bald'
if os.path.exists(grid_dir):
    shutil.rmtree(grid_dir)
os.makedirs(grid_dir)

# ionization parameter grids logxi= -3 to 5
logxi_vals=np.linspace(-3,5,20)
# column density in the unit of cm^-2 range between 1e18 and 2e24 cm^-2
column_vals=np.logspace(np.log10(1e-6) ,np.log10(2),9)
# turbulent velocity km/s between 100 to 1e4 km/s
v_vals=np.logspace(2,4,9)
# covering factor of absorbing gas, range between 0 to 1
fcov_vals=np.linspace(0,1,5)



i=0
fname="xabsgrid_ufopcov_bald.sh"
outfile=open(fname,"w")
ionfile="xabs_inputfile_corr1"  ###ionization balance, calculated by using xabsinput


preamble=("#!/usr/bin/env bash\n\nspex<<EOF\n\n")

components="\n".join(
                     ["com po", \
                      "com xabs",\
                      "com rel 1 2"]
                     )+"\n\n"

fixed_pars="\n".join(
                     ["par 1 gamm v 2",\
                      "par 1 norm v 10",\
                      "par 2 col av "+ionfile,\
                      "par 2 fcov v 1"]
                    )+"\n"

plotting="\n".join(
                    ["pl dev null",\
                     "pl ty mo",\
                     "pl ux ke",\
                     "pl uy cou",\
                     "p rx 0.1 10",\
                     "p ry 0 0.01",\
                     "p x  lin",\
                     "p y  lin",\
                     "p fil dis f"]
                   )+"\n"

outfile.write(preamble+components+fixed_pars+plotting)
for xi in logxi_vals:
    for column in column_vals:
        for v in v_vals:
            for fcov in fcov_vals:
                modstr="xi%s_column%s_v%s_fcov%s" % (str(xi), str(column), str(v), str(fcov))
                spec_fname=grid_dir+"/xabsgrid_%s" % modstr


                variable_pars="\n".join(["par 2 xil v %s" % str(xi),\
                                        "par 2 nh v %s" % str(column),\
                                        "par 2 v v %s" % str(v),\
                                        "par 2 fcov v %s" % str(fcov),\
                                        "ion ignore all",\
                                         "calc"])+"\n"

                #NB: Change pl dev to a .ps file for running on sci grid - can't use xs there. M
                plotting="\n".join(
                            ["p",\
                             "plot adum %s over" % spec_fname])+"\n"


                outfile.write(variable_pars+plotting)



post="q\nEOF"

outfile.write(post)
outfile.flush()
outfile.close()


subprocess.call(["bash %s" % (fname)], shell=True)
