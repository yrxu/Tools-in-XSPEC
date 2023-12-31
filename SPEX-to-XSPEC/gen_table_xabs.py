#!/usr/bin/env python

import numpy as np
from matplotlib import pyplot as pl
import pyfits as pf

grid_dir='absorption_grid' ##the directory containing generated spectra by PION

# ionization parameter grids logxi= -3 to 5
logxi_vals=np.linspace(-3,5,20)
# column density in the unit of cm^-2 range between 1e18 and 2e24 cm^-2
column_vals=np.logspace(np.log10(1e-6) ,np.log10(2),9)
# turbulent velocity km/s between 100 to 1e4 km/s
v_vals=np.logspace(2,4,9)
# covering factor of absorbing gas, range between 0 to 1
fcov_vals=np.linspace(0,1,5)


outfil="xabs_xs.fits"


# Nvars=3
varnames=["logxi","column","v", "fcov"]
lengths=[20,9,9,5]
Nvars=len(varnames)
nmodels=np.prod(lengths)
nmax=max(lengths)

parray=[]
spec_array=[]

for xi in logxi_vals:
    for column in column_vals:
        for v in v_vals:
            for fcov in fcov_vals:
                modstr="xi%s_column%s_v%s_fcov%s" % (str(xi), str(column), str(v), str(fcov))

                spec_fname=grid_dir+"/xabsgrid_%s.qdp" % modstr

                pars=[xi,column,v,fcov]
                parray.append(pars)

                temp_data=np.loadtxt(spec_fname,skiprows=1)

                spec_array.append(temp_data[:,3])

parray=np.array(parray)
spec_array=np.array(spec_array)

max_vals=spec_array.max(axis=0)

spec_array=spec_array/max_vals




###### SET UP PRIMARY HEADER #######


prihdu = pf.PrimaryHDU()
prihd =prihdu.header
prihd.extend([('MODLNAME','XABSTABLE'),('MODLUNIT','PHOTONS/CM2/S'),\
                  ('REDSHIFT',True),('ADDMODEL',False),('HDUCLASS','OGIP'),\
                  ('HDUCLAS1','XSPEC TABLE MODEL'),('HDUVERS','1.0.0'),\
                  ('CREATOR','YERONG XU'),\
                  ('ORIGINAL AUTHOR','M L PARKER'),\
                  ('COMMENT','BASED ON XABS (ACTUAL PION) MODEL IN SPEX')])



#### SET UP PARAMETERS TABLE



pcnames = ['NAME','METHOD','INITIAL','DELTA','MINIMUM','BOTTOM',\
               'TOP','MAXIMUM','NUMBVALS','VALUE']
pcformats = ['12A','J','E','E','E','E','E','E','J','%sE' % nmax]


# All arrays have to have the same length, so make empty arrays and set the first few values
col_array=np.empty(nmax)
for i,col in enumerate(column_vals):
    col_array[i]=col

v_array=np.empty(nmax)
for i,v in enumerate(v_vals):
    v_array[i]=v

logxi_array=np.empty(nmax)
for i,logxi in enumerate(logxi_vals):
        logxi_array[i]=logxi

fcov_array=np.empty(nmax)
for i,fc in enumerate(fcov_vals):
        fcov_array[i]=fc

#'NAME','METHOD 0:linear; 1:log','INITIAL','DELTA','MINIMUM','BOTTOM','TOP','MAXIMUM','NUMBVALS','VALUE'
p1=['logxi',0,np.median(logxi_vals),0.01,min(logxi_vals),min(logxi_vals),max(logxi_vals),max(logxi_vals),len(logxi_vals),logxi_array]
p2=['column',1,np.median(column_vals),0.01,min(column_vals),min(column_vals),max(column_vals),max(column_vals),len(column_vals),col_array]
p3=['v',0,np.median(v_vals),0.01,min(v_vals),min(v_vals),max(v_vals),max(v_vals),len(v_vals),v_array]
p4=['fcov',0,1,0.01,0,0,1,1,len(fcov_vals),fcov_array]


pars=[p1,p2,p3,p4]

parcols=[]
for c in range(0,len(pars[0])):
    col=[]
    for p in range(0,Nvars):
        par = pars[p]
        col.append(par[c])
    parcols.append(pf.Column(name=pcnames[c],format=pcformats[c],array=col))

pcdefs = pf.ColDefs(parcols)
partb = pf.new_table(pcdefs)
partb.name='Parameters'
parhd = partb.header
parhd.extend([('NINTPARM',Nvars),('NADDPARM',0),('HDUCLASS','OGIP'),\
                  ('HDUCLAS1','XSPEC TABLE MODEL'),\
                  ('HDUCLAS2','PARAMETERS'),('HDUVERS','1.0.0')])



######## SET UP ENERGIES TABLE ########

elow=temp_data[:,0]+temp_data[:,2]
ehigh=temp_data[:,0]+temp_data[:,1]

energ_lo = pf.Column(name='ENERG_LO', format='E', array=elow)
energ_hi = pf.Column(name='ENERG_HI', format='E', array=ehigh)

energtb = pf.new_table([energ_lo,energ_hi])
energtb.name = 'Energies'
energhd = energtb.header
energhd.extend([('HDUCLASS','OGIP'),('HDUCLAS1','XSPEC TABLE MODEL'),\
                  ('HDUCLAS2','ENERGIES'),('HDUVERS','1.0.0')])



####### SET UP SPECTRUM TABLE ##########
parcol = pf.Column(name = 'PARAMVAL',format='%sE' %Nvars ,array = parray)
speccol = pf.Column(name = 'INTPSPEC',format='%sE' % len(spec_array[0]),\
                        unit='photons/cm2/s',array = spec_array)

spectb = pf.new_table([parcol,speccol],tbtype='BinTableHDU')
spectb.name = 'Spectra'
spechd = spectb.header
spechd.extend([('HDUCLASS','OGIP'),('HDUCLAS1','XSPEC TABLE MODEL'),\
                  ('HDUCLAS2','MODEL SPECTRA'),('HDUVERS','1.0.0')])


thdulist = pf.HDUList([prihdu, partb, energtb, spectb])

thdulist.writeto(outfil)
