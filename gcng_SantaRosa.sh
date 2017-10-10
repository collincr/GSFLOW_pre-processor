#!/bin/bash

python2.7 setup.py --gsflow $HOME"/opt/GSFLOW-1.2.0/bin" \
                   --start "1990-04-23" --end "2017-09-27" \
                   --dem "stros_srtm_3arc_utm" \
                   --name "SantaRosaIsland"

## - comment out below after data is already there
#unzip strosa_data.zip
#mkdir -p data/GIS
#cp -R strosa_data/GIS/* data/GIS/
#cp strosa_data/dem/* data/GIS
#cp strosa_data/climate/* "$PRMSinput_dir"

python2.7 python_scripts/settings.py
##python2.7 process_weatherdata.py
python2.7 python_scripts/GSFLOW_print_controlfile.py
python2.7 python_scripts/GSFLOW_print_PRMSparamfile.py
python2.7 python_scripts/print_MODFLOW_inputs_res_NWT.py
./GSFLOW/control/SantaRosaIsland_GSFLOW.sh

