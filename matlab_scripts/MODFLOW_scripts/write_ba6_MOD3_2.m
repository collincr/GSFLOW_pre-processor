% write_ba6_MOD
% 11/17/16
function write_ba6_MOD3(GSFLOW_indir, infile_pre, mask_fil)
% % ==== TO RUN AS SCRIPT ===================================================
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
% % =========================================================================
%%
% - write to this file
% GSFLOW_dir = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/GSFLOW/inputs/MODFLOW/';
ba6_file = [infile_pre, '.ba6'];
slashstr = '/';

% - domain dimensions, maybe already in surfz_fil and botm_fil{}?
% NLAY = 1;
% NROW = 50;
% NCOL = 50;

% -- IBOUND(NROW,NCOL,NLAY): <0 const head, 0 no flow, >0 variable head
% use basin mask (set IBOUND>0 within watershed, =0 outside watershed, <0 at discharge point and 2 neighboring pixels)
% mask_fil = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/Data/GIS/basinmask_dischargept.asc';
fid = fopen(mask_fil, 'r');
D = textscan(fid, '%s %f', 6); 
NSEW = D{2}(1:4);
NROW = D{2}(5);
NCOL = D{2}(6);
D = textscan(fid, '%f'); 
IBOUND = reshape(D{1}, NCOL, NROW)'; % NROW x NCOL
D = textscan(fid, '%s %s %f %s %f'); 
dischargePt_rowi = D{3};
dischargePt_coli = D{5};
fclose(fid);

% - force some cells to be active to correspond to stream reaches
IBOUND(14,33) = 1;
IBOUND(11,35) = 1;
IBOUND(12,34) = 1;
IBOUND(7,43) = 1;

% find boundary cells
IBOUNDin = IBOUND(2:end-1,2:end-1);
IBOUNDu = IBOUND(1:end-2,2:end-1); % up
IBOUNDd = IBOUND(3:end,2:end-1); % down
IBOUNDl = IBOUND(2:end-1,1:end-2); % left
IBOUNDr = IBOUND(2:end-1,3:end); % right
% - inner boundary is constant head
ind_bound = IBOUNDin==1 & (IBOUNDin-IBOUNDu==1 | IBOUNDin-IBOUNDd==1 | ...
    IBOUNDin-IBOUNDl==1 | IBOUNDin-IBOUNDr==1);
% - outer boundary is constant head
% ind_bound = IBOUNDin==0 & (IBOUNDin-IBOUNDu==-1 | IBOUNDin-IBOUNDd==-1 | ...
%     IBOUNDin-IBOUNDl==-1 | IBOUNDin-IBOUNDr==-1);


% -- init head: base on TOP and BOTM
dis_file = [GSFLOW_indir, '/', infile_pre, '.dis'];
fid = fopen(dis_file);
for ii = 1:2, cmt = fgets(fid); end
line0 = fgets(fid);
D = textscan(line0, '%d', 6);
NLAY = D{1}(1); NROW = D{1}(2); NCOL = D{1}(3);
NPER = D{1}(4); ITMUNI = D{1}(5); LENUNI = D{1}(6);
line0 = fgets(fid);
D = textscan(line0, '%d');
LAYCBD = D{1}; % 1xNLAY (0 if no confining layer)

line0 = fgets(fid);
D = textscan(line0, '%s %d');    DELR = D{2}; % width of column
line0 = fgets(fid);
D = textscan(line0, '%s %d');    DELC = D{2}; % height of row

TOP = nan(NROW,NCOL);
line0 = fgets(fid);
for irow = 1: NROW
    line0 = fgets(fid);
    D = textscan(line0, '%f');
    TOP(irow,:) = D{1}(1:NCOL);
end

BOTM = nan(NROW, NCOL, NLAY);
for ilay = 1: NLAY
    line0 = fgets(fid); 
    for irow = 1: NROW
        line0 = fgets(fid);
        D = textscan(line0, '%f');
        BOTM(irow,:,ilay) = D{1}(1:NCOL);
    end
end
fclose(fid);

% - make boundary cells constant head above a certain elevation
% IBOUNDin(ind_bound & TOP(2:end-1,2:end-1) > 4500) = -1;
IBOUNDin(ind_bound & TOP(2:end-1,2:end-1) > 3500) = -1;
IBOUND(2:end-1,2:end-1,1) = IBOUNDin;

% - make discharge point and neighboring cells constant head
IBOUND(dischargePt_rowi,dischargePt_coli,1) = -2; % downgrad of discharge pt
% IBOUND(dischargePt_rowi-1,dischargePt_coli,1) = -1; % neighbor points
IBOUND(dischargePt_rowi+1,dischargePt_coli,1) = -1;
IBOUND(dischargePt_rowi,dischargePt_coli+1,1) = -2; % downgrad of discharge pt
IBOUND(dischargePt_rowi-1,dischargePt_coli+1,1) = -1; % neighbor points
IBOUND(dischargePt_rowi+1,dischargePt_coli+1,1) = -1;
IBOUND(dischargePt_rowi,dischargePt_coli,1) = 1; % downgrad of discharge pt

IBOUND = repmat(IBOUND, [1 1 NLAY]); 


% - initHead(NROW,NCOL,NLAY) 
initHead = BOTM(:,:,1) + (TOP-BOTM(:,:,1))*0.9; % within top layer
% % (no more than 10m below top):
% Y = nan(NROW,NCOL,2); Y(:,:,1) = initHead; Y(:,:,2) = TOP-10; 
% initHead = max(Y,[],3);
initHead = repmat(initHead, [1, 1, NLAY]);

% - assumed values
HNOFLO = -999.99;


%% ------------------------------------------------------------------------
% -- Write ba6 file
fil_ba6_0 = [GSFLOW_indir, slashstr, ba6_file];
fmt1 = [repmat('%4d ', 1, NCOL), '\n']; % for IBOUND 
fmt2 = [repmat('%7g ', 1, NCOL), '\n']; % for initHead

fid = fopen(fil_ba6_0, 'wt');
fprintf(fid, '# basic package file --- %d layers, %d rows, %d columns\n', NLAY, NROW, NCOL);
fprintf(fid, 'FREE\n');
for ilay = 1: NLAY
    fprintf(fid, 'INTERNAL          1 (FREE)  3         IBOUND for layer %d \n', ilay); % 1: CNSTNT multiplier, 3: IPRN>0 to print input to list file
    fprintf(fid, fmt1, IBOUND(:,:,ilay)');
end
fprintf(fid, '    %f  HNOFLO\n', HNOFLO);
for ilay = 1: NLAY
    fprintf(fid, 'INTERNAL          1 (FREE)  3         init head for layer %d \n', ilay); % 1: CNSTNT multiplier, 3: IPRN>0 to print input to list file
    fprintf(fid, fmt2, initHead(:,:,ilay)');
end
fclose(fid);

% -- Plot basics
for ii = 1:2
    if ii == 1, 
        X0 = IBOUND; ti0 = 'IBOUND';
    elseif ii == 2
        X0 = initHead; ti0 = 'init head';
    end
    figure
    for ilay = 1:NLAY
        subplot(2,2,double(ilay))
        X = X0(:,:,ilay);
        m = X(X>0); m = min(m(:));
        imagesc(X), %caxis([m*0.9, max(X(:))]), 
        cm = colormap;
%         cm(1,:) = [1 1 1];
        colormap(cm);
        colorbar
        title([ti0, ' lay', num2str(ilay)]);
    end
end