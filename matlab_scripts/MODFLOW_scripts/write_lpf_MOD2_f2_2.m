% write_lpf_MOD
% 11/17/16

function write_lpf_MOD2_f2_2(GSFLOW_indir, infile_pre, surfz_fil, NLAY)

% % =========== TO RUN AS SCRIPT ===========================================
% clear all, close all, fclose all;
% % - directories
% % MODFLOW input files
% GSFLOW_indir = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/GSFLOW/inputs/MODFLOW/';
% % MODFLOW output files
% GSFLOW_outdir = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/GSFLOW/outputs/MODFLOW/';
% 
% % infile_pre = 'test1lay';
% % NLAY = 1;
% % DZ = 10; % [NLAYx1] ***temporary: constant 10m thick single aquifer (consider 2-layer?)
% 
% infile_pre = 'test2lay';
% NLAY = 2;
% DZ = [50; 50]; % [NLAYx1] ***temporary: constant 10m thick single aquifer (consider 2-layer?)
% 
% GIS_indir = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/Data/GIS/';
% 
% % for various files: ba6, dis, uzf, lpf
% surfz_fil = [GIS_indir, 'topo.asc'];
% % for various files: ba6, uzf
% mask_fil = [GIS_indir, 'basinmask_dischargept.asc'];
% 
% % for sfr
% reach_fil = [GIS_indir, 'reach_data.txt'];
% segment_fil_all = cell(3,1);
% segment_fil_all{1} = [GIS_indir, 'segment_data_4A_INFORMATION.txt'];
% segment_fil_all{2} = [GIS_indir, 'segment_data_4B_UPSTREAM.txt'];
% segment_fil_all{3} = [GIS_indir, 'segment_data_4C_DOWNSTREAM.txt'];

buffer_fil = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/Data/GIS/segments_buffer2.asc';
% % ====================================================================

% - write to this file
% GSFLOW_dir = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/GSFLOW/inputs/MODFLOW/';
% lpf_file = 'test.lpf';
lpf_file = [infile_pre, '.lpf'];
slashstr = '/';

% - domain dimensions, maybe already in surfz_fil and botm_fil{}?
% NLAY = 2;
% surfz_fil = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/Data/GIS/topo.asc';
fid = fopen(surfz_fil, 'r');
D = textscan(fid, '%s %f', 6); 
NSEW = D{2}(1:4);
NROW = D{2}(5);
NCOL = D{2}(6);
% - space discretization
DELR = (NSEW(3)-NSEW(4))/NCOL; % width of column [m]
DELC = (NSEW(1)-NSEW(2))/NROW; % height of row [m]
% - set TOP to surface elevation [m]
D = textscan(fid, '%f'); 
fclose(fid);
fprintf('Done reading...\n');
TOP = reshape(D{1}, NCOL, NROW)'; % NROW x NCOL


% get buffer info
fid = fopen(buffer_fil, 'r');
D = textscan(fid, '%s %f', 6); 
NSEW = D{2}(1:4);
NROW = D{2}(5);
NCOL = D{2}(6);
D = textscan(fid, '%f'); 
buffer = reshape(D{1}, NCOL, NROW)'; % NROW x NCOL
fclose(fid);

% -- Base hydcond, Ss (all layers), and Sy (top layer only) on data from files
% (temp place-holder)
hydcond = ones(NROW,NCOL,NLAY)*2; % m/d (Sagehen: 0.026 to 0.39 m/d, lower K under ridges for volcanic rocks)
% hydcond(:,:,2) = 0.5; % m/d (Sagehen: 0.026 to 0.39 m/d, lower K under ridges for volcanic rocks)
% hydcond(:,:,2) = 0.1; % m/d (Sagehen: 0.026 to 0.39 m/d, lower K under ridges for volcanic rocks)
hydcond(:,:,1) = 0.1; % m/d (Sagehen: 0.026 to 0.39 m/d, lower K under ridges for volcanic rocks)
% hydcond(:,:,1) = 0.01; % m/d (Sagehen: 0.026 to 0.39 m/d, lower K under ridges for volcanic rocks)
hydcond(:,:,2) = 0.01; % m/d (Sagehen: 0.026 to 0.39 m/d, lower K under ridges for volcanic rocks)
Ss = ones(NROW,NCOL,NLAY)* 2e-6; % constant 2e-6 /m for Sagehen
Sy = ones(NROW,NCOL,NLAY)*0.15; % 0.08-0.15 in Sagehen (lower Sy under ridges for volcanic rocks)
WETDRY = Sy; % = Sy in Sagehen (lower Sy under ridges for volcanic rocks)

% % use buffer (and elev?)
% K = buffer; % 0: very far from stream, 5: farthest from stream in buffer, 1: closest to stream
% K(buffer==0) = 0.04; % very far from streams
% K(buffer==0 & TOP>5000) = 0.03; % very far from streams
% K(buffer>=1) = 0.5; % close to streams
% K(buffer>=2) = 0.4;
% K(buffer>=3) = 0.3;
% K(buffer>=4) = 0.15;
% K(buffer==5) = 0.08; % farthest from stream and high
% hydcond(:,:,1) = K;
% hydcond(:,:,2) = 0.01;

% use buffer (and elev?)
K = buffer; % 0: very far from stream, 5: farthest from stream in buffer, 1: closest to stream
K(buffer==0) = 0.04; % very far from streams
K(buffer==0 & TOP>5000) = 0.03; % very far from streams
% K(buffer>=1) = 0.5; % close to streams
K(buffer>=1) = 0.25; % close to streams
K(buffer>=2) = 0.15;
K(buffer>=3) = 0.08;
K(buffer>=4) = 0.08;
K(buffer==5) = 0.08; % farthest from stream and high
hydcond(:,:,1) = K;
hydcond(:,:,2) = 0.01;

% -- assumed input values
flow_filunit = 34; % make sure this matches namefile!!
hdry = 1e30;  % head assigned to dry cells
nplpf = 0;    % number of LPF parameters (if >0, key words would follow)
laytyp = zeros(NLAY,1); laytyp(1) = 1;  % flag, top>0: "covertible", rest=0: "confined"
layave = zeros(NLAY,1);  % flag, layave=1: harmonic mean for interblock transmissivity
chani = ones(NLAY,1);   % flag, chani=1: constant horiz anisotropy mult factor (for each layer)
layvka = zeros(NLAY,1);  % flag, layvka=0: vka is vert K; >0 is vertK/horK ratio
VKA = hydcond;
laywet = zeros(NLAY,1); laywet(1)=1;  % flag, 1: wetting on for top convertible cells, 0: off for confined
fl_Tr = 1; % flag, 1 for at least 1 transient stress period (for Ss and Sy)
WETFCT = 1.001; % 1.001 for Sagehen, wetting (convert dry cells to wet)
IWETIT = 4; % number itermations for wetting 
IHDWET = 0; % wetting scheme, 0: equation 5-32A is used: h = BOT + WETFCT (hn - BOT)

%% ------------------------------------------------------------------------


fmt1 = repmat('%2d ', 1, NLAY);

fil_lpf_0 = [GSFLOW_indir, slashstr, lpf_file];
fid = fopen(fil_lpf_0, 'wt');
fprintf(fid, '# LPF package inputs\n');
fprintf(fid, '%d %g %d    ILPFCB,HDRY,NPLPF\n', flow_filunit, hdry, nplpf);
fprintf(fid, [fmt1, '     LAYTYP\n'], laytyp);
fprintf(fid, [fmt1, '     LAYAVE\n'], layave);
fprintf(fid, [fmt1, '     CHANI \n'], chani);
fprintf(fid, [fmt1, '     LAYVKA\n'], layvka);
fprintf(fid, [fmt1, '     LAYWET\n'], laywet);
if ~isempty(find(laywet,1))
    fprintf(fid, '%g %d %d       WETFCT, IWETIT, IHDWET\n', WETFCT, IWETIT, IHDWET);
end

% -- Write HKSAT and Ss, Sy (if Tr) in .lpf file
format0 = [repmat(' %4.2f ', 1, NCOL), '\n'];
format1 = [repmat(' %4.2e ', 1, NCOL), '\n'];
% loop thru layers (different entry for each layer)
for lay = 1: NLAY
    fprintf(fid, 'INTERNAL   1.000E-00 (FREE)    0            HY layer  %d\n', lay); % horizontal hyd cond
    fprintf(fid, format1, hydcond(:,:,lay)');

    fprintf(fid, 'INTERNAL   1.000E-00 (FREE)    0            VKA layer  %d\n', lay); % vertical hyd cond
    fprintf(fid, format1, VKA(:,:,lay)');
    
    if fl_Tr
        fprintf(fid, 'INTERNAL   1.000E-00 (FREE)    0            Ss layer  %d\n', lay);
        fprintf(fid, format1, Ss(:,:,lay)');
        if laytyp(lay) > 0 % convertible, i.e. unconfined
            fprintf(fid, 'INTERNAL   1.000E-00 (FREE)    0            Sy layer  %d\n', lay);
            fprintf(fid, format1, Sy(:,:,lay)');
            if laywet(lay) > 0
                fprintf(fid, 'INTERNAL   1.000E-00 (FREE)    0            WETDRY layer  %d\n', lay);
                fprintf(fid, format0, WETDRY(:,:,lay)');
            end
        end
    end
end
fprintf(fid, '\n');
fclose(fid);

figure
for ilay = 1:NLAY
    subplot(2,2,double(ilay))
    X = hydcond(:,:,ilay);
    m = X(X>0); m = min(m(:));
    imagesc(X), %caxis([m*0.9, max(X(:))]), 
    cm = colormap;
%         cm(1,:) = [1 1 1];
    caxis([0 max(X(:))])
    colormap(cm);
    colorbar
    title(['hydcond', num2str(ilay)]);
end
