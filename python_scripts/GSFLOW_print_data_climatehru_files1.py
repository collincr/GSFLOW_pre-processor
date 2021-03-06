# GSFLOW_print_climate_hru_files1.m
# 11/24/16
#
# based on: PRMS_print_climate_hru_files2.m

# Creates climate data inputs files to run PRMS for climate_hru mode using 
# by uniformly applying data from a single weather station:
#   Specify precip, tmax, tmin, and solrad for each HRU for each
#   simulation day.  Can have start day earlier and end day later than
#   simulation period.
# 

import pandas as pd
import numpy as np
from ConfigParser import SafeConfigParser
from StringIO import StringIO

parser = SafeConfigParser()
parser.read('settings.ini')
LOCAL_DIR = parser.get('settings', 'local_dir')

GSFLOW_DIR = LOCAL_DIR + "/GSFLOW"


# *** CUSTOMIZE TO YOUR COMPUTER! *****************************************

# directory for PRMS input files (include slash ('/') at end) - cbh files
# outputed to here
PRMSinput_dir = GSFLOW_DIR + '/inputs/PRMS/'

# PRMSinput_dir = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/GSFLOW/ChimTest'

# directory with files to be read in to generate PRMS input files in_GISdata_dir
in_data_dir = GSFLOW_DIR + '/inputs/PRMS/'
in_climatedata_dir = in_data_dir + '/climate/' # specifically climate data

# GIS data (for nhru)
in_data_dir = GSFLOW_DIR + '/DataToReadIn/'
in_GISdata_dir = in_data_dir + '/GIS/' # specifically GIS data
HRUfil = in_GISdata_dir + '/HRU.csv'

# *************************************************************************

# Project-specific entries ->

# -- Number of HRU's over which to apply data uniformly
# nhru should be generated dynamically (from GIS data)
HRUdata = pd.read_csv(HRUfil, header=0)
nhru = HRUdata['id'].max()

## -- Set any description of data here (example: location, units)
descr_str = 'BocaToma'

# -- Read in daily values from 1 station for:
#   - precip (check 'precip_units')
#   - tmax (check 'temp_units')
#   - tmin (check 'temp_units') 
#   [- swrad [langleys for F temp_units] ]-currently unavailable at Chim
#   - ymdhms_v

in_datafil = in_climatedata_dir + '/test_boca_toma_F_in.txt'
Data = pd.read_csv(in_datafil, skiprows=5, delim_whitespace=True, header=None)
Data_columns = ['year', 'month', 'day', 'hour', 'min', 'sec', 'tmax', 'tmin', 'precip']

#tmax must be F
#tmin must be F
#precip must be inch

if Data.shape[1] == 5:
    Data_columns += ['swrad']

Data.columns = Data_columns

if 'swrad' in Data.columns:
    Data['swrad'] = Data['swrad'] * 1.e+6 / 41480.
    # MJ/m2 -> Langeley (1 Langely = 41840 J/m2)

## ------------------------------------------------------------------------
# Generally, do no change below here

# -- These files will be generated (names must match those in Control file!)
#    (generally don't change this)
empty_datafil = PRMSinput_dir + '/empty.day'
precip_datafil = PRMSinput_dir + '/precip.day'
tmax_datafil = PRMSinput_dir + '/tmax.day'
tmin_datafil = PRMSinput_dir + '/tmin.day'
hum_datafil = PRMSinput_dir + '/humidity.day' # fake! 
solrad_datafil = PRMSinput_dir + '/swrad.day'

# - how many of above met variables to process (0 thru N)
N = 4

# - Write to data variable files
print_fmt1 = ["%4d"] + ["%2d"] * 5
print_fmt2 = ["%4d"] + ["%2d"] * 5 + ["%6.2f"] * nhru

 
try:
    swrad
except:
    pass
else:
    N = 5

for ii in range(0, N+1):
    if ii==0:
        outdatafil = empty_datafil
        data = []
        label = ['precip 0', 'tmax 0', 'tmin 0']
    elif ii==1:
        outdatafil = precip_datafil
        data = Data['precip']
        label = ['precip {}'.format(nhru)]
    elif ii==2: 
        outdatafil = tmax_datafil
        data = Data['tmax']
        label = ['tmaxf {}'.format(nhru)]
    elif ii==3: 
        outdatafil = tmin_datafil
        data = Data['tmin']
        label = ['tminf {}'.format(nhru)]
    elif ii==4: 
        outdatafil = hum_datafil
        data = Data['tmax']/100.
        label = ['humidity_hru {}'.format(nhru)]
    elif ii==5: 
        outdatafil = solrad_datafil
        data = Data['swrad']
        label = ['swrad {}'.format(nhru)]

    fid = open(outdatafil, "w+")

    header = "\n".join([descr_str] + label) + "\n##########\n"
    fid.write(header)

    if len(data) > 0:
        data0 = pd.concat([Data[['year', 'month', 'day', 'hour', 'min', 'sec']],
                          pd.DataFrame(np.dstack([data] * nhru)[0])], axis=1)
        np.savetxt(fid, data0, fmt=print_fmt2, delimiter=" ")

    else:
        data0 = Data[['year', 'month', 'day', 'hour', 'min', 'sec']]
        np.savetxt(fid, data0, fmt=print_fmt1, delimiter=" ")

    fid.close()

