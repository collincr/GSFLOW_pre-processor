# -*- coding: utf-8 -*-
"""
Created on Sun Sep 17 22:06:52 2017

Based on: print_MODFLOW_inputs_res_NWT.m

@author: gcng
"""

# print_MODFLOW_inputs

import numpy as np
#import MODFLOW_NWT_lib as mf # functions to write individual MODFLOW files
#import MODFLOW_NWT_lib as mf # functions to write individual MODFLOW files
import MODFLOW_NWT_lib as mf # functions to write individual MODFLOW files
import os  # os functions

# - directories
sw_2005_NWT = 2 # 1 for MODFLOW-2005; 2 for MODFLOW-NWT algorithm (both can be 
                # carried out with MODFLOW-NWT code) 
fl_BoundConstH = 1 # 1 for const head at high elev boundary, needed for numerical 
                    # convergence for AGU2016 poster.  Maybe resolved with MODFLOW-NWT?
sw_spinup_restart = 2 # 1: spinup (2 periods: steady-state and transient), 2: restart (1 period: transient)


if sw_2005_NWT == 1:
    # MODFLOW input files
    GSFLOW_indir = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/GSFLOW/inputs/MODFLOW_2005/'
    # MODFLOW output files
    GSFLOW_outdir = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/GSFLOW/outputs/MODFLOW_2005/'
    
elif sw_2005_NWT == 2:
    # MODFLOW input files
    GSFLOW_indir = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/GSFLOW/inputs/MODFLOW_NWT/'
    # MODFLOW output files
    GSFLOW_outdir = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/GSFLOW/outputs/MODFLOW_NWT/'

infile_pre = 'test2lay_py';

NLAY = 2;
DZ = [100, 50] # [NLAYx1] [m] ***testing
# DZ = [350, 100] # [NLAYx1] [m] ***testing

# length of transient stress period (follows 1-day steady-state period) [d]
# perlen_tr = 365; # [d], ok if too long
perlen_tr = 365*5 + np.ceil(365*5/4); # [d], includes leap years; ok if too long (I think, but maybe run time is longer?)
#perlen_tr = 365*30 + np.ceil(365*30/4) # [d], includes leap years; ok if too long (I think, but maybe run time is longer?)

GIS_indir = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/Data/GIS/';

# use restart file as initial cond (empty string to not use restart file)
#fil_res_in = '' # empty string to not use restart file
#fil_res_in = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/GSFLOW/outputs/MODFLOW_NWT/test2lay_melt_py_30yr.out' 
#fil_res_in = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/GSFLOW/outputs/MODFLOW_NWT/test2lay_melt_py_30yr_woConstH.out'
#fil_res_in = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/GSFLOW/outputs/MODFLOW_NWT/test2lay_melt_py_30yr_wConstH.out'
#fil_res_in = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/GSFLOW/outputs/MODFLOW_NWT/test2lay_melt_py_30yr_wConstH.out'
#fil_res_in = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/GSFLOW/outputs/MODFLOW_NWT/test2lay_py_30yr_woConstH.out'
fil_res_in = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/GSFLOW/outputs/MODFLOW_NWT/test2lay_py_30yr_wConstH.out'
#fil_res_in = '/media/gcng/STORAGE3A/GSFLOW/simdir_Sept2017/res_5yr_wConstHeadMODres2woConstHead_NWT/outputs/MODFLOW_NWT/test2lay_py.out'

# for various files: ba6, dis, uzf, lpf
surfz_fil = GIS_indir + 'topo.asc'
# surfz_fil = GIS_indir + 'SRTM_new_20161208.asc'
# for various files: ba6, uzf
mask_fil = GIS_indir + 'basinmask_dischargept.asc'

# for sfr
reach_fil = GIS_indir + 'reach_data.txt'
segment_fil_all = [GIS_indir + 'segment_data_4A_INFORMATION_Man.csv', 
                   GIS_indir + 'segment_data_4B_UPSTREAM_Man.csv', 
                   GIS_indir + 'segment_data_4C_DOWNSTREAM_Man.csv']


# create MODFLOW input directory if it does not exist:
if not os.path.isdir(GSFLOW_indir):
    os.mkdir(GSFLOW_indir)
    
# while we're at it, create MODFLOW output file if it does not exist:
if not os.path.isdir(GSFLOW_outdir):
    os.mkdir(GSFLOW_outdir)

## 
mf.write_dis_MOD2_f(GSFLOW_indir, infile_pre, surfz_fil, NLAY, DZ, perlen_tr, sw_spinup_restart);
mf.write_ba6_MOD3_2(GSFLOW_indir, infile_pre, mask_fil, fl_BoundConstH); # list this below write_dis_MOD2_f

# flow algorithm
if sw_2005_NWT == 1:
    mf.write_lpf_MOD2_f2_2(GSFLOW_indir, infile_pre, surfz_fil, NLAY);
elif sw_2005_NWT == 2:
    # MODFLOW-NWT files
    mf.write_upw_MOD2_f2_2(GSFLOW_indir, infile_pre, surfz_fil, NLAY);
    mf.NWT_write_file(GSFLOW_indir, infile_pre);

# unsat zone and streamflow input files
mf.make_uzf3_f_2(GSFLOW_indir, infile_pre, surfz_fil, mask_fil, sw_spinup_restart);
mf.make_sfr2_f_Mannings(GSFLOW_indir, infile_pre, reach_fil, segment_fil_all, sw_spinup_restart); # list this below write_dis_MOD2_f

# Write PCG file (only used for MODFLOW-2005, but this function also creates OC file)
mf.write_OC_PCG_MOD_f(GSFLOW_indir, infile_pre, perlen_tr, sw_spinup_restart);

# Write namefile
mf.write_nam_MOD_f2_NWT(GSFLOW_indir, GSFLOW_outdir, infile_pre, fil_res_in, sw_2005_NWT);
