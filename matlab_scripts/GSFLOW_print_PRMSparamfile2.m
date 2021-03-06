% GSFLOW_print_PRMSparamfile2.m
% 11/23/16
% (based on PRMS_print_paramfile3.m, 11/25/15)
% gcng
%
% This version is NOT for climate_hru (climate_hru is for pre-processed time
% series data)

% Creates inputs files with PRMS parameters (**not GSFLOW parameters***)
% leaves out many of the "extra" options.  
% GSFLOW Input files:
%   - control file (generate with GSFLOW_print_controlfile1.m - NOT YET WRITTEN)
%   - parameter files (generate with GSFLOW_print_PRMSparamfile1.m and GSFLOW_print_GSFLOWparamfile1.m - NOT YET WRITTEN)
%   - variable / data files (generate with GSFLOW_print_ObsMet_files1.m - NOT YET WRITTEN)
% (Control file includes names of parameter and data files.  Thus, 
% parameter and variable file names must match those specified there!!)
%
% note on order of parameter values when there are 2 dimensions: par_value{ii} = ones(ndim1, ndim2); par_value{ii} = par_value{ii}(:)
%
% Search for "CHANGE FOR SPECIFIC SITE"

clear all, close all, fclose all;
%% Parameter file

% See Appendix 1 Table 1-1 (p.30-31) for Dimensions list, Appendix 1 Table 1-
% 3 for parameters (by module) (p.37-59), description p. 128

% general syntax - Dimensions
%   line 1: '####'
%   line 2: dimension name
%   line 3: dimension value


% general syntax - Parameters
%   line 1: '####'
%   line 2: parameter name
%   line 3: Number of dimensions
%   line 4 to 3+NumOfDims: Name of dimensions, 1 per line 
%   line 3+NumOfDims+1: Number of values 
%   line 3+NumOfDims+2: data type -> 1=int, 2=single prec, 3=double prec, 4=char str
%   line 3+NumOfDims+3 to end: parameter values, 1 per line

% 2-dimensional arrays:
%   read in column-by-column, i.e. [nhru x nmonth] has all Jan first, then 
%   all Feb, etc.

% *** CUSTOMIZE TO YOUR COMPUTER! *****************************************
% NOTE: '/' is directory separator for Linux, '\' for Windows!!

% directory for GSFLOW input and output files (include slash ('/') at end)
PRMSinput_dir = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/GSFLOW/inputs/PRMS/';
PRMSoutput_dir = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/GSFLOW/outputs/';

% directory with files to be read in to generate PRMS input files (include slash ('/') at end)
in_data_dir = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/Data/';
in_GISdata_dir = strcat(in_data_dir, 'GIS/'); % specifically GIS data

% parameter file that will be written (name must match that in Control file!)
parfil_pre = 'ChimTest';

% GIS-generated files read in to provide values to PRMS input file
HRUfil = strcat(in_GISdata_dir, 'HRU.csv');
segmentfil = strcat(in_GISdata_dir, 'segment_data_4A_INFORMATION.txt');
reachfil = strcat(in_GISdata_dir, 'reach_data.txt'); % *** NEW FOR GSFLOW, only required here for NREACH, other info is for SFR file
gvrfil = strcat(in_GISdata_dir, 'GRAVITY_RESERVOIRS.csv'); % *** NEW FOR GSFLOW
MODfil = strcat(in_GISdata_dir, 'basinmask.asc'); % *** NEW FOR GSFLOW, only required here for ngwcell (NROW*NCOL)
% *************************************************************************

% Project-specific entries ->

% - choose one:
% model_mode = 'WRITE_CLIMATE'; % creates pre-processed climate_hru files
model_mode = 'PRMS'; % run only PRMS
% model_mode = 'MODFLOW'; % run only MODFLOW-2005
% model_mode = 'GSFLOW'; % run coupled PRMS-MODFLOW

parfil = [PRMSinput_dir, parfil_pre, '_', model_mode, '.param'];

% Load GIS-generated files with HRU, segment etc information
% fid = fopen(segmentfil, 'r');
% line0 = fgets(fid);
% D = textscan(line0, '%s', 13, 'delimiter', ',');
% segmentdata.colheaders = D{1};
% D = textscan(fid, '%f %s %f %f %f %f %f %f %f %f %f %f %f %f %f \n', 'delimiter', ',');
% segmentdata.data = zeros(length(D{1}),length(segmentdata.colheaders));
% segmentdata.data(:,1) = D{1};
% for ii = 3:13
%     segmentdata.data(:,ii) = D{ii};
% end
% fclose(fid);
segmentdata = importdata(segmentfil,',',1);
HRUdata = importdata(HRUfil,',',1);
reachdata = importdata(reachfil,',',1);
gvrdata = importdata(gvrfil,',',1);
fid = fopen(MODfil, 'r');
D = textscan(fid, '%s %f', 6); 
MODdata.NSEW = D{2}(1:4);
MODdata.NROW = D{2}(5);
MODdata.NCOL = D{2}(6);
fclose(fid);


% 2 lines available for comments
title_str1 = 'TEST';
title_str2 = 'much based on merced and sagehen examples, NOT using climate_hru';

% n_Dim, n_par, should be dynamically generated

% - initialize dimension and parameter variables
n_Dim_max = 100; % there are a lot, unsure how many total...
dim_name = cell(n_Dim_max,1);
dim_value = nan(n_Dim_max,1);

n_par_max = 100; % there are a lot, unsure how many total...
par_name = cell(n_par_max,1); % name of parameter
par_num_dim = nan(n_par_max,1); % number of dimensions
par_dim_name = cell(n_par_max,1); % names of dimensions
par_num = nan(n_par_max,1); % number of parameter values
par_type = nan(n_par_max,1); % parameter number type 1=int, 2=single prec, 3=double prec, 4=char str
par_value = cell(n_par_max,1); % array of parameter values

% ********************
% *    Dimensions    *
% ********************
ii = 0;
% -- Fixed Dimensions (generally, do not change) --
ii = ii+1;
dim_name{ii} = 'ndays'; % max num days in year
dim_value(ii) = 366;

ii = ii+1;
dim_name{ii} = 'nmonths'; % num months in year
dim_value(ii) = 12;

ii = ii+1;
dim_name{ii} = 'one';
dim_value(ii) = 1;


% -- Spatial dimensions --
ii = ii+1;
% ****to be read in from GIS info****
dim_name{ii} = 'nhru';  
dim_value(ii) = max(HRUdata.data(:, strcmp(HRUdata.colheaders, 'id')));

ii = ii+1;
% ****to be read in from GIS info****
dim_name{ii} = 'nsegment';  % num stream channel segments
% dim_value(ii) = max(segmentdata.data(:, strcmp(segmentdata.colheaders, 'id')));
dim_value(ii) = max(segmentdata.data(:, strcmp(segmentdata.colheaders, 'NSEG')));

ii = ii+1;
dim_name{ii} = 'ngw';  % num stream channel segments
dim_value(ii) = dim_value(strcmp(dim_name, 'nhru'));  % do not change

ii = ii+1;
dim_name{ii} = 'nssr';  % num subsurface reservoirs
dim_value(ii) = dim_value(strcmp(dim_name, 'nhru'));  % do not change

% new for GSFLOW:
if strcmp(model_mode, 'GSFLOW')
    ii = ii+1;
    % ****to be read in from GIS info****
    dim_name{ii} = 'nreach';  % total num reaches (in all stream segments)
    dim_value(ii) = size(reachdata.data, 1);
end

% new for GSFLOW:
ii = ii+1;
% ****to be read in from GIS info****
dim_name{ii} = 'ngwcell';  % total num MODFLOW GW cells 
dim_value(ii) = MODdata.NROW * MODdata.NCOL;

% new for GSFLOW:
ii = ii+1;
% ****to be read in from GIS info****
dim_name{ii} = 'nhrucell';  % total num gravity reservoirs (intersections of hru and grid cells)
dim_value(ii) = max(gvrdata.data(:, strcmp(gvrdata.colheaders, 'cat')));


% -- Time-series input data dimensions --
% (some of these data are not needed but are handy to output for calibration)
ii = ii+1;
dim_name{ii} = 'nrain';  % num precip measurement stations
dim_value(ii) = 0; % can be 0 if using climate_hru

ii = ii+1;
dim_name{ii} = 'ntemp';  % num temperature measurement stations
dim_value(ii) = 0; % can be 0 if using climate_hru

ii = ii+1;
dim_name{ii} = 'nsol';  % num solar rad measurement stations
dim_value(ii) = 0; % can be 0 if using ddsolrad (degree-day) or climate_hru

ii = ii+1;
dim_name{ii} = 'nhumid';  % num humidity measurement stations
dim_value(ii) = 0; % optional, for some  ET modules

ii = ii+1;
dim_name{ii} = 'nwind';  % num wind speed measurement stations
dim_value(ii) = 0; % optional, for some  ET modules

ii = ii+1;
dim_name{ii} = 'nobs';  % num streamflow obs, replaces model when using muskingum or strmflow_in_out
dim_value(ii) = 0;

ii = ii+1;
dim_name{ii} = 'nsnow';  % num snow depth measurement stations
dim_value(ii) = 0;  % optional


% -- Computational dimensions --
ii = ii+1;
% ****to be read in from GIS info****
dim_name{ii} = 'ncascade';  % num HRU links, for cascade_flag = 1
dim_value(ii) = 0;

% (gw - can mirror surface)
ii = ii+1;
dim_name{ii} = 'ncascdgw';  % num GWR links, for cascadegw_flag = 1
dim_value(ii) = dim_value(strcmp(dim_name, 'ncascade'));  % do not change

% (snow)
ii = ii+1;
dim_name{ii} = 'ndepl';  % num snow-depletion curves
dim_value(ii) = 2;

ii = ii+1;
dim_name{ii} = 'ndeplval';  % num values in all snow-depletion curves
dim_value(ii) = dim_value(strcmp(dim_name, 'ndepl')) * 11; % do not change

NumDims = ii;
dim_name = dim_name(1:NumDims);
dim_value = dim_value(1:NumDims);
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

% ********************
% *   Parameters    *
% ********************
ii = 0;

% -- Basic Computational Attributes --
ii = ii+1;
par_name{ii} = 'elev_units';
par_dim_name{ii} = {'one'};
par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 1;  % 0: ft, 1: m; do not change

ii = ii+1;
% ****to be read in from GIS info****
par_name{ii} = 'hru_area';
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = HRUdata.data(:, strcmp(HRUdata.colheaders, par_name{ii}));  % [acre]

ii = ii+1;
% ****to be read in from GIS info****
par_name{ii} = 'hru_aspect';
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = HRUdata.data(:, strcmp(HRUdata.colheaders, par_name{ii}));  % [angular degrees]

ii = ii+1;
% ****to be read in from GIS info****
par_name{ii} = 'hru_elev';
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = HRUdata.data(:, strcmp(HRUdata.colheaders, par_name{ii}));  % elev_units = m

ii = ii+1;
% ****to be read in from GIS info****
par_name{ii} = 'hru_lat';
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = HRUdata.data(:, strcmp(HRUdata.colheaders, par_name{ii}));  % [angular degrees]

ii = ii+1;
% ****to be read in from GIS info****
par_name{ii} = 'hru_slope';
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = HRUdata.data(:, strcmp(HRUdata.colheaders, par_name{ii}));  % [-]

% -- GSFLOW: PRMS-MODFLOW mapping 
if strcmp(model_mode, 'GSFLOW') || (strcmp(model_mode, 'PRMS') && ...
        dim_value(strcmp(dim_name, 'nhru')) ~= dim_value(strcmp(dim_name, 'ngwcell')))
    % new for GSFLOW, also for model_mode=PRMS which nhru~=ngwcell
    ii = ii+1;
    par_name{ii} = 'gvr_hru_id'; % HRU corresponding to gravity reservior
    par_dim_name{ii} = {'nhrucell'};
    par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
    par_value{ii} = gvrdata.data(:, strcmp(gvrdata.colheaders, par_name{ii}));  % [-]

    % new for GSFLOW, also for model_mode=PRMS which nhru~=ngwcell
    ii = ii+1;
    par_name{ii} = 'gvr_hru_pct'; % Decimal fraction of hru area associated with gravity reservior
    par_dim_name{ii} = {'nhrucell'};
    par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
    par_value{ii} = gvrdata.data(:, strcmp(gvrdata.colheaders, par_name{ii}));  % [-]
    
    % new for GSFLOW, also for model_mode=PRMS which nhru~=ngwcell
    ii = ii+1;
    par_name{ii} = 'gvr_cell_id'; % HRU corresponding to gravity reservior
    par_dim_name{ii} = {'nhrucell'};
    par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
    par_value{ii} = gvrdata.data(:, strcmp(gvrdata.colheaders, par_name{ii}));  % [-]

    % new for GSFLOW, also for model_mode=PRMS which nhru~=ngwcell
    ii = ii+1;
    par_name{ii} = 'gvr_cell_pct'; % Decimal fraction of hru area associated with gravity reservior
    par_dim_name{ii} = {'nhrucell'};
    par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
    par_value{ii} = gvrdata.data(:, strcmp(gvrdata.colheaders, par_name{ii}));  % [-]
    
end


% -- Measured input --
ii = ii+1;
par_name{ii} = 'precip_units';
par_dim_name{ii} = {'one'};
par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0;  % 0: inch, 1: mm; do not change

ii = ii+1;
par_name{ii} = 'temp_units';
par_dim_name{ii} = {'one'};
par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0;  % 0: F, 1: C; do not change

ii = ii+1;
par_name{ii} = 'adj_by_hru'; % flag for how to adjust precip and temp 
par_dim_name{ii} = {'one'};
par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 1; % adjust by: 0= sub-basin, 1= hru; do not change

ii = ii+1;
par_name{ii} = 'adjmix_rain'; % monthly factor to adjust rain proportion into rain/snow event
par_dim_name{ii} = {'nmonths'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = ones(12,1);  % [-]; do not change(?)  double-check what this means??

ii = ii+1;
par_name{ii} = 'rain_cbh_adj'; % monthly factor to adjust rain proportion into rain/snow event
par_dim_name{ii} = {'nhru', 'nmonths'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_num(ii) = 1;
for jj = 1: length(par_dim_name{ii})
    par_num(ii) = par_num(ii) * dim_value(strcmp(dim_name, par_dim_name{ii}{jj}));
end
par_value{ii} = ones(par_num(ii), 1);  % [-]

ii = ii+1;
par_name{ii} = 'rain_cbh_adj'; % monthly factor to adjust data
par_dim_name{ii} = {'nhru', 'nmonths'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_num(ii) = 1;
for jj = 1: length(par_dim_name{ii})
    par_num(ii) = par_num(ii) * dim_value(strcmp(dim_name, par_dim_name{ii}{jj}));
end
par_value{ii} = ones(par_num(ii), 1);  % [-]

ii = ii+1;
par_name{ii} = 'snow_cbh_adj'; % monthly factor to adjust data
par_dim_name{ii} = {'nhru', 'nmonths'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_num(ii) = 1;
for jj = 1: length(par_dim_name{ii})
    par_num(ii) = par_num(ii) * dim_value(strcmp(dim_name, par_dim_name{ii}{jj}));
end
par_value{ii} = ones(par_num(ii), 1);  % [-]

ii = ii+1;
par_name{ii} = 'tmax_cbh_adj'; % monthly factor to adjust data; 
par_dim_name{ii} = {'nhru', 'nmonths'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_num(ii) = 1;
for jj = 1: length(par_dim_name{ii})
    par_num(ii) = par_num(ii) * dim_value(strcmp(dim_name, par_dim_name{ii}{jj}));
end
par_value{ii} = 0*ones(par_num(ii), 1);  % temp_units = F

ii = ii+1;
par_name{ii} = 'tmin_cbh_adj'; % monthly factor to adjust data; 
par_dim_name{ii} = {'nhru', 'nmonths'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_num(ii) = 1;
for jj = 1: length(par_dim_name{ii})
    par_num(ii) = par_num(ii) * dim_value(strcmp(dim_name, par_dim_name{ii}{jj}));
end
par_value{ii} = 0*ones(par_num(ii), 1);  % temp_units = F

ii = ii+1;
par_name{ii} = 'tmax_allrain'; % if tmax > tmax_allrain, then all rain
par_dim_name{ii} = {'nmonths'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = ones(12,1)*35;  % temp_units = F

ii = ii+1;
par_name{ii} = 'tmax_allsnow';
par_dim_name{ii} = {'one'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 32;  % temp_units = F; do not change


% -- Solar Radiation --
% ** No parameters here when using solrad_module = climate_hru **


% -- Potential ET distribution --
% ** No parameters here when using et_module = climate_hru **
% ** If et_module is pet_pt (Priestly-Taylor): **
ii = ii+1;
par_name{ii} = 'pt_alpha'; % alpha for Priestly-Taylor, ave ~1.26 but often higher in dry and windy regions (up to 2.14 or 2.47 - but this is open water)
% Crystal had 1.7 as a windy guess
par_dim_name{ii} = {'nhru', 'nmonths'};
par_num(ii) = 1;
for jj = 1: length(par_dim_name{ii})
    par_num(ii) = par_num(ii) * dim_value(strcmp(dim_name, par_dim_name{ii}{jj}));
end    
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 1.26*ones(par_num(ii),1);  % [-], default: 1.26


% -- Evapotranspiration and sublimation --
ii = ii+1;
par_name{ii} = 'potet_sublim'; % frac of PET that is sublimated from snow 
par_dim_name{ii} = {'one'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0.75;  % [-], default: 0.5, mercd: 0.101, sagehen: 0.75

ii = ii+1;
par_name{ii} = 'rad_trncf'; % transmission coeff for short-wave radiation through winter canopy
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0.5 * ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  % default 0.5

ii = ii+1;
par_name{ii} = 'soil_type'; % only for ET calc, 1: sand, 2: loam, 3: clay
par_dim_name{ii} = {'nhru'};
par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  % merced: all 1's

% Below: Assumes transp_module=transp_tindex (phenolgy based on temp)
%   Start summing max air temp on month 'transp_beg'; when sum >=
%   'transp_tmax', transp begins; transp ends on month 'transp_end' 
%   (previous month is last one with transp > 0)
% *** CHANGE FOR SPECIFIC SITE
ii = ii+1;
par_name{ii} = 'transp_beg'; % month to start summing max air temp
par_dim_name{ii} = {'nhru'};
par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 1*ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  % mercd: all 4's, 1 for transp anytime - CHIMBORAZO

% *** CHANGE FOR SPECIFIC SITE
ii = ii+1;
par_name{ii} = 'transp_end'; % month to stop transp, so previous month is last with transp
par_dim_name{ii} = {'nhru'};
par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 13*ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  % max is 13, for transp anytime - CHIMBORAZO

% *** CHANGE FOR SPECIFIC SITE
ii = ii+1;
par_name{ii} = 'transp_tmax'; % max summed temp to start transp
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
% Has ET case
par_value{ii} = 500*ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  % mercd: all 500 degF
par_value{ii} = zeros(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  % 0 degF for transp anytime - CHIMBORAZO
% No ET case
%par_value{ii} = 5E9*ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);

% -- Interception --
% *** CHANGE FOR SPECIFIC SITE
ii = ii+1;
par_name{ii} = 'cov_type'; % 0=bare soil, 1=grasses, 2=shrubs, 3=trees, 4=coniferous
                            % (0 and 4 may not be options for GSFLOW)
par_dim_name{ii} = {'nhru'};
par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 2*ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  

% *** CHANGE FOR SPECIFIC SITE
ii = ii+1;
par_name{ii} = 'covden_sum'; % summer veg cover density
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0.15*ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  

% *** CHANGE FOR SPECIFIC SITE
ii = ii+1;
par_name{ii} = 'covden_win'; % winter veg cover density
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0.2*ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  

ii = ii+1;
par_name{ii} = 'snow_intcp'; % snow interception storage capacity
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0.07*ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  % [inch]

ii = ii+1;
par_name{ii} = 'srain_intcp'; % summer rain interception storage capacity
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0.04*ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  % [inch]

ii = ii+1;
par_name{ii} = 'wrain_intcp'; % winter rain interception storage capacity
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0.04*ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  % [inch]

% -- Snow computations (based on mercd) --
ii = ii+1;
par_name{ii} = 'albset_rna';
par_dim_name{ii} = {'one'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0.8;  

ii = ii+1;
par_name{ii} = 'albset_rnm';
par_dim_name{ii} = {'one'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0.6;  

ii = ii+1;
par_name{ii} = 'albset_sna';
par_dim_name{ii} = {'one'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0.05;  

ii = ii+1;
par_name{ii} = 'cecn_coef';
par_dim_name{ii} = {'nmonths'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = ones(12,1) * 0.04876140267863427;

ii = ii+1;
par_name{ii} = 'den_init';
par_dim_name{ii} = {'one'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0.1;  

ii = ii+1;
par_name{ii} = 'den_max';
par_dim_name{ii} = {'one'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0.6;  

ii = ii+1;
par_name{ii} = 'emis_noppt';
par_dim_name{ii} = {'one'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0.76;  

ii = ii+1;
par_name{ii} = 'freeh2o_cap';
par_dim_name{ii} = {'one'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0.19; 

ii = ii+1;
par_name{ii} = 'hru_deplcrv';
par_dim_name{ii} = {'nhru'};
par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);

ii = ii+1;
par_name{ii} = 'melt_force';
par_dim_name{ii} = {'one'};
par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 90;

ii = ii+1;
par_name{ii} = 'melt_look';
par_dim_name{ii} = {'one'};
par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 90;

ii = ii+1;
par_name{ii} = 'settle_const';
par_dim_name{ii} = {'one'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0.1;

% each snow depletion curve has 11 values in increasing order ([0, 1.0]); 
% should have ndeplval=(11*ndepl) values. Below snarea_curves values are 
% used in both mercd and acf examples.
ii = ii+1;
par_name{ii} = 'snarea_curve';
par_dim_name{ii} = {'ndeplval'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = [0.05; 0.24; 0.4; 0.53; 0.65; 0.74; 0.82; 0.88; 0.93; 0.97; 1.0; ...
    0.05; 0.25; 0.4; 0.48; 0.54; 0.58; 0.61; 0.64; 0.66; 0.68; 0.7];  

% snarea_thresh is max threshold SWE below which snow depletion curve is 
% applied (using snarea_curve). Based on mercd and acf, value could be ~1
% of hru_elev.
ii = ii+1;
par_name{ii} = 'snarea_thresh';
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
hru_elev = par_value{strcmp(par_name, 'hru_elev')}; 
par_value{ii} = 0.01 * hru_elev;  

ii = ii+1;
par_name{ii} = 'tstorm_mo';
par_dim_name{ii} = {'nmonths'};
par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = [0; 0; 0; 1; 1; 1; 1; 1; 1; 0; 0; 0];  


% -- Hortonian surface runoff, infiltration, and impervious storage --
ii = ii+1;
par_name{ii} = 'carea_max';
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0.6*ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  

ii = ii+1;
par_name{ii} = 'hru_percent_imperv';
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = zeros(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  % [-]

ii = ii+1;
par_name{ii} = 'imperv_stor_max'; % max impervious area retention storage
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = zeros(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  % [-]

ii = ii+1;
par_name{ii} = 'snowinfil_max';
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 2 * ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  

% Assumes srunoff_module=runoff_smidx (or equivalently runoff_smidx_casc)
ii = ii+1;
par_name{ii} = 'smidx_coef';
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0.0011346339705706754 * ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  

ii = ii+1;
par_name{ii} = 'smidx_exp';
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0.21845105595154202 * ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  


% -- Soil zone storage, interflow, gravity drainage, dunnian surface runoff --

% - GSFLOW computational parameter
ii = ii+1; 
par_name{ii} = 'mxsziter'; % max iterations for soil zone computations
par_dim_name{ii} = {'one'};
par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 25;  % default is 15, sagehen example uses 25

% - GSFLOW computational parameter
ii = ii+1;
par_name{ii} = 'szconverge'; % convergence criteria for soil-zone
par_dim_name{ii} = {'one'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 1e-8;  % [inches] default is 1e-8, sagehen example uses 1e-4

ii = ii+1;
par_name{ii} = 'fastcoef_lin';
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0.8034819756283689 * ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  

ii = ii+1;
par_name{ii} = 'fastcoef_sq';
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0.740714266649265 * ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  

ii = ii+1;
par_name{ii} = 'pref_flow_den';
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = zeros(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  

ii = ii+1;
par_name{ii} = 'sat_threshold';
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 999 * ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  

ii = ii+1;
par_name{ii} = 'slowcoef_lin';
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0.015 * ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  

ii = ii+1;
par_name{ii} = 'slowcoef_sq';
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0.1 * ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  

ii = ii+1;
par_name{ii} = 'soil_moist_init';
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 1.5 * ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  

ii = ii+1;
par_name{ii} = 'soil_moist_max';
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 3 * ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  

ii = ii+1;
par_name{ii} = 'soil_rechr_init';
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 1 * ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  

ii = ii+1;
par_name{ii} = 'soil_rechr_max';
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 2.7 * ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  

ii = ii+1;
par_name{ii} = 'soil2gw_max';
par_dim_name{ii} = {'nhru'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0.4979401249572195 * ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  

ii = ii+1;
par_name{ii} = 'ssr2gw_exp';
par_dim_name{ii} = {'nssr'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 1 * ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  

ii = ii+1;
par_name{ii} = 'ssr2gw_rate';
par_dim_name{ii} = {'nssr'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0.1 * ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  

ii = ii+1;
par_name{ii} = 'ssstor_init';
par_dim_name{ii} = {'nssr'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0. * ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  


% -- Groundwater flow --
ii = ii+1;
par_name{ii} = 'gwflow_coef';
par_dim_name{ii} = {'ngw'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0.011716573948525877 * ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  

ii = ii+1;
par_name{ii} = 'gwsink_coef';
par_dim_name{ii} = {'ngw'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0. * ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  

ii = ii+1;
par_name{ii} = 'gwstor_init';
par_dim_name{ii} = {'ngw'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 4.287873048430077 * ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  

ii = ii+1;
par_name{ii} = 'gwstor_min';
par_dim_name{ii} = {'ngw'};
par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0 * ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  


% -- Streamflow and lake routing --
% below assumes strmflow_module=strmflow_in_out (should also work for
% strmflow, params should just be ignored)
% ****to be read in from GIS info****
ii = ii+1;
par_name{ii} = 'hru_segment'; % stream segment that hru ultimately flows to (ignored if fl_cascade=1?)
par_dim_name{ii} = {'nhru'};
par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = HRUdata.data(:, strcmp(HRUdata.colheaders, par_name{ii}));

% ****to be read in from GIS info****
ii = ii+1;
par_name{ii} = 'tosegment'; % stream segment flowing into 
par_dim_name{ii} = {'nsegment'};
par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
% par_value{ii} = segmentdata.data(:, strcmp(segmentdata.colheaders, par_name{ii}));
par_value{ii} = segmentdata.data(:, strcmp(segmentdata.colheaders, 'OUTSEG'));

ii = ii+1;
par_name{ii} = 'obsin_segment'; % index of measured streamflow station that replaces inflow to a segment (can all be 0)
par_dim_name{ii} = {'nsegment'};
par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0*ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);  


% -- Lake routing --
% ** No parameters here when not using strmflow_module = strmflow_lake **


% -- Output options --
ii = ii+1;
par_name{ii} = 'print_freq'; % 0=none, 1=run totals, 2=yrly, 4=monthly, 8=daily, or additive combos
par_dim_name{ii} = {'one'};
par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 1;

ii = ii+1;
par_name{ii} = 'print_type'; % 0=measured and simulated, 1=water bal table, 2=detailed
par_dim_name{ii} = {'one'};
par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 1;


% -- Subbasin parameters --
% ** No parameters here when using subbasin_flag=0 **
% (can map HRU's to subbasins, for subbasin statistics)

% -- Mapped results parameters --
% ** No parameters here when using mapOutON_OFF=0 **
% (can map groundwater reservoirs to grid cells)

% -- Parameters for cascading-flow simulation --
ii = ii+1;
par_name{ii} = 'cascade_flg'; % 0: allow many to many cascade links, 1: force one to one
par_dim_name{ii} = {'one'};
par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
par_value{ii} = 0;  

if dim_value(strcmp(dim_name, 'ncascade')) > 0 || dim_value(strcmp(dim_name, 'ncascdgw')) > 0 
    ii = ii+1;
    par_name{ii} = 'cascade_tol'; % cascade area below which cascade link is ignored
    par_dim_name{ii} = {'one'};
    par_type(ii) = 2; % 1=int, 2=single prec, 3=double prec, 4=char str
    par_value{ii} = 5;  % acres, unsure how to set this
 
    ii = ii+1;
    par_name{ii} = 'circle_switch'; % error check for cascade circles
    par_dim_name{ii} = {'one'};
    par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
    par_value{ii} = 1; % set to 0 for computational savings    
end
if dim_value(strcmp(dim_name, 'ncascade')) > 0 
    % ****to be read in from GIS info****
    ii = ii+1;
    par_name{ii} = 'hru_up_id'; % index of upslope HRU, -1 for far afield, ignored if goes to stream seg
    par_dim_name{ii} = {'ncascade'};
    par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
    par_value{ii} = ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);

    % ****to be read in from GIS info****
    ii = ii+1;
    par_name{ii} = 'hru_down_id'; % index of downslope HRU, -1 for far afield, ignored if goes to stream seg
    par_dim_name{ii} = {'ncascade'};
    par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
    par_value{ii} = ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);
    
    % ****to be read in from GIS info****
    ii = ii+1;
    par_name{ii} = 'hru_strmseg_down_id'; % index of downslope stream segment, 0 if not to stream
    par_dim_name{ii} = {'ncascade'};
    par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
    par_value{ii} = 0*ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);

    ii = ii+1;
    par_name{ii} = 'hru_pct_up'; % frac of HRU area contributing to downslope HRU
    par_dim_name{ii} = {'ncascade'};
    par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
    par_value{ii} = ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);

end
if dim_value(strcmp(dim_name, 'ncascdgw')) > 0 
    ii = ii+1;
    par_name{ii} = 'gw_up_id'; % index of upslope GWR, -1 for far afield, ignored if goes to stream seg
    par_dim_name{ii} = {'ncascdgw'};
    par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
    par_value{ii} = ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);

    ii = ii+1;
    par_name{ii} = 'gw_down_id'; % index of downslope GWR, -1 for far afield, ignored if goes to stream seg
    par_dim_name{ii} = {'ncascdgw'};
    par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
    par_value{ii} = ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);
    
    ii = ii+1;
    par_name{ii} = 'gw_strmseg_down_id'; % index of downslope stream segment, 0 if not to stream
    par_dim_name{ii} = {'ncascdgw'};
    par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
    par_value{ii} = 0*ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);

    ii = ii+1;
    par_name{ii} = 'gw_pct_up'; % frac of GWR area contributing to downslope HRU
    par_dim_name{ii} = {'ncascdgw'};
    par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
    par_value{ii} = ones(dim_value(strcmp(dim_name, par_dim_name{ii})),1);
end


% ii = ii+1;
% par_name{ii} = '';
% par_dim_name{ii} = {''};
% par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
% par_value{ii} = 1;  
% 
% ii = ii+1;
% par_name{ii} = '';
% par_dim_name{ii} = {''};
% par_type(ii) = 1; % 1=int, 2=single prec, 3=double prec, 4=char str
% par_value{ii} = 1;  

NumPars = ii;
par_name = par_name(1:NumPars);
par_dim_name = par_dim_name(1:NumPars);
par_type = par_type(1:NumPars); % 1=int, 2=single prec, 3=double prec, 4=char str
par_value = par_value(1:NumPars);




%% -----------------------------------------------------------------------
% Many more parameters that are not specified here.  Do a check to make
% sure not using any modules that require unspecified parameters:
nobs = dim_value(strcmp(dim_name, 'nobs'));  
if nobs > 0
    fprintf('Error! Script not meant for nobs > 0! Exiting... \n');
    return
end
nsol = dim_value(strcmp(dim_name, 'nsol'));  
if nsol > 0
    fprintf('Error! Script not meant for nsol > 0! Exiting... \n');
    return
end
fprintf('Warning!  Script assumes the following... \n');
fprintf('   climate_hru for precip_module and temp_module \n');
fprintf('   climate_hru for solrad_module \n');
fprintf('   climate_hru or pet_pt (Priestly-Taylor) for et_module (for PotET) \n');
fprintf('   transp_tindex for transp_module \n');
fprintf('   runoff_smidx for runoff_module \n');
fprintf('   strmflow_in_out for strmflow_module (should also be ok for strmflow) \n');


%% -----------------------------------------------------------------------
% Generally, do no change below here

% - Write to control file

% -- other remaing variables
for ii = 1: NumPars
    par_num_dim(ii) = length(par_dim_name{ii});
    par_num(ii) = 1;
    for jj = 1: length(par_dim_name{ii})
        par_num(ii) = par_num(ii) * dim_value(strcmp(dim_name, par_dim_name{ii}{jj}));
    end
end


% - Write to Parameter file
line1 = '####';
fmt_types = {'%d', '%f', '%f', '%s'};
fid = fopen(parfil, 'w');
fprintf(fid,'%s\n', title_str1);
fprintf(fid,'%s\n', title_str2);

% * Dimensions
dim_line = '** Dimensions **';
fprintf(fid,'%s\n', dim_line);
for ii = 1: NumDims
    % Line 1
    fprintf(fid,'%s\n', line1);
    % Line 2
    fprintf(fid,'%s\n', dim_name{ii});
    % Line 3: 
    fprintf(fid,'%d\n', dim_value(ii));
end

par_line = '** Parameters **';
fprintf(fid,'%s\n', par_line);
for ii = 1: NumPars
    % Line 1
    fprintf(fid,'%s\n', line1);
    % Line 2
    fprintf(fid,'%s\n', par_name{ii});
    % Line 3: 
    fprintf(fid,'%d\n', par_num_dim(ii));
    % line 4 to 3+NumOfDims: Name of dimensions, 1 per line 
    for jj = 1: par_num_dim(ii)
        fprintf(fid,'%s\n', par_dim_name{ii}{jj});
    end
    % line 3+NumOfDims+1: Number of values 
    fprintf(fid,'%d\n', par_num(ii));
    % line 3+NumOfDims+2: data type -> 1=int, 2=single prec, 3=double prec, 4=char str
    fprintf(fid,'%d\n', par_type(ii));
    % line 3+NumOfDims+3 to end: parameter values, 1 per line
    switch par_type(ii)
        case 1, fprintf(fid, '%d\n', par_value{ii});
        case 2, fprintf(fid, '%g\n', par_value{ii});
        case 4, 
            for jj = 1: par_num
                fprintf(fid, '%s\n', par_value{ii}{jj});
            end
    end
    
end



fclose(fid);
return
%% ------------------------------------------------------------------------
% Prepare for model execution

if ~exist(outdir, 'dir')
    mkdir(outdir);
end

fprintf('Make sure the below data file is ready: \n  %s\n', datafil);
fprintf('Make sure the below parameter file is ready: \n  %s\n', parfil);
cmd_str = [PRMS_exe, ' -C ', con_filname];
fprintf('To run command-line execution, enter at prompt: \n %s\n', cmd_str);
gui_str1 = [cmd_str, ' -print'];
gui_str2 = ['java -cp ', PRMS_java_GUI, ' oui.mms.gui.Mms ', con_filname];
fprintf('To launch GUI, enter the following 2 lines (one at a time) at prompt: \n %s\n %s\n', gui_str1, gui_str2);

