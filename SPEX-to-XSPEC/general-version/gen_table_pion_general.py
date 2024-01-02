#!/usr/bin/env python


import numpy as np
from matplotlib import pyplot as pl
import astropy.io.fits as pf

grid_dir='emission_grid' ##the directory containing generated spectra by PION

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



outfil="pion_xs.fits"



varnames=["logxi","nh","gamma","v","omeg"]
Nvars=len(varnames)  #number of variables
lengths=[20,9,9,9,5]
nmodels=np.prod(lengths)
nmax=max(lengths)

parray=[]
spec_array=[]

for xi in logxi_vals:
    for col_density in col_density_vals:
        for gamma in gamma_vals:
            for v in v_vals:
                for omeg in omeg_vals:
                    modstr="xi%s_nH%s_gamma%s_v%s_omeg%s" % (str(xi),str(col_density),str(gamma),str(v),str(omeg))

                    spec_fname=grid_dir+"/piongrid_%s.qdp" % modstr

                    pars=[xi,col_density,gamma,v,omeg]
                    parray.append(pars)

                    temp_data=np.loadtxt(spec_fname,skiprows=1)

                    spec_array.append(temp_data[:,3])

parray=np.array(parray)
spec_array=np.array(spec_array)




###### SET UP PRIMARY HEADER #######


prihdu = pf.PrimaryHDU()
prihd =prihdu.header
prihd.extend([('MODLNAME','PIONTABLE'),('MODLUNIT','PHOTONS/CM2/S'),\
                  ('REDSHIFT',True),('ADDMODEL',True),('HDUCLASS','OGIP'),\
                  ('HDUCLAS1','XSPEC TABLE MODEL'),('HDUVERS','1.0.0'),\
                  ('CREATOR','YERONG XU'),\
                  ('AUTHOR','M L PARKER'),\
                  ('COMMENT','BASED ON PION MODEL IN SPEX')])



#### SET UP PARAMETERS TABLE



pcnames = ['NAME','METHOD','INITIAL','DELTA','MINIMUM','BOTTOM',\
               'TOP','MAXIMUM','NUMBVALS','VALUE']
pcformats = ['12A','J','E','E','E','E','E','E','J','%sE' % nmax]


# All arrays have to have the same length, so make empty arrays and set the first few values
logxi_array=np.empty(nmax)
for i,xi in enumerate(logxi_vals):
    logxi_array[i]=xi


col_density_array=np.empty(nmax)
for i,d in enumerate(col_density_vals):
    col_density_array[i]=d

gamma_array=np.empty(nmax)
for i,gamma in enumerate(gamma_vals):
    gamma_array[i]=gamma

v_array=np.empty(nmax)
for i,v in enumerate(v_vals):
    v_array[i]=v

omeg_array=np.empty(nmax)
for i,omeg in enumerate(omeg_vals):
    omeg_array[i]=omeg

#'NAME','METHOD 0:linear; 1:log','INITIAL','DELTA','MINIMUM','BOTTOM','TOP','MAXIMUM','NUMBVALS','VALUE'
p1=['logxi',0,3,0.01,min(logxi_vals),min(logxi_vals),max(logxi_vals),max(logxi_vals),len(logxi_vals),logxi_array]
p2=['nH',1,np.median(col_density_vals),0.01,min(col_density_vals),min(col_density_vals),max(col_density_vals),max(col_density_vals),len(col_density_vals),col_density_array]
p3=['gamma',0,2,0.01,min(gamma_vals),min(gamma_vals),max(gamma_vals),max(gamma_vals),len(gamma_vals),gamma_array]
p4=['v',1,1000,0.01,min(v_vals),min(v_vals),max(v_vals),max(v_vals),len(v_vals),v_array]
p5=['omeg',0,1,0.01,min(omeg_vals),min(omeg_vals),max(omeg_vals),max(omeg_vals),len(omeg_vals),omeg_array]


pars=[p1,p2,p3,p4,p5]

parcols=[]
for c in range(0,len(pars[0])):
    col=[]
    for p in range(0,Nvars):
        par = pars[p]
        col.append(par[c])
    parcols.append(pf.Column(name=pcnames[c],format=pcformats[c],array=col))

pcdefs = pf.ColDefs(parcols)
partb = pf.BinTableHDU.from_columns(pcdefs)
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

energtb = pf.BinTableHDU.from_columns([energ_lo,energ_hi])
energtb.name = 'Energies'
energhd = energtb.header
energhd.extend([('HDUCLASS','OGIP'),('HDUCLAS1','XSPEC TABLE MODEL'),\
                  ('HDUCLAS2','ENERGIES'),('HDUVERS','1.0.0')])



####### SET UP SPECTRUM TABLE ##########

parcol = pf.Column(name = 'PARAMVAL',format='%sE' %Nvars ,array = parray)
speccol = pf.Column(name = 'INTPSPEC',format='%sE' % len(spec_array[0]),\
                        unit='photons/cm2/s',array = spec_array)

spectb = pf.BinTableHDU.from_columns([parcol,speccol])
spectb.name = 'Spectra'
spechd = spectb.header
spechd.extend([('HDUCLASS','OGIP'),('HDUCLAS1','XSPEC TABLE MODEL'),\
                  ('HDUCLAS2','MODEL SPECTRA'),('HDUVERS','1.0.0')])


thdulist = pf.HDUList([prihdu, partb, energtb, spectb])

thdulist.writeto(outfil)
