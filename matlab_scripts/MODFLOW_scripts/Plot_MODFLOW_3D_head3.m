% Plot_MODFLOW_head_flow_1D_general_quickstart.m
%
% 10/28/15 (can handle transient conditions)
%
% plots MODFLOW results: head image plots for each layer
%
% **** IN PROGRESS: PLOT WTD ***

clear all, fclose all;
close all,

% --------------------------------------------------------

% -- directory with simulation results, file names
% MOD_simdir = '/media/gcng/STORAGE3A/GSFLOW/Shullcas_Updated_gcng/outputs/MODFLOW_NWT/';
% MOD_simdir = '/home/gcng/workspace/matlab_files/GSFLOW_pre-processor/GSFLOW/outputs/MODFLOW_NWT/';
% MOD_simdir = '/media/gcng/STORAGE3A/GSFLOW/simdir_Sept2017/res_5yr_wConstHeadMODres2woConstHead_NWT/outputs/MODFLOW_NWT/';
% MOD_simdir = '/media/gcng/STORAGE3A/GSFLOW/simdir_Sept2017/res_5yr_wConstHead_NWT/outputs/MODFLOW_NWT/';
% MOD_simdir = '/media/gcng/STORAGE3A/GSFLOW/simdir_Sept2017/spinup_30yr_wConstHead_NWT/outputs/MODFLOW_NWT/';
% MOD_simdir = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/GSFLOW/Shullcas/GSFLOW/outputs/MODFLOW_NWT/';
% MOD_simdir = '/media/gcng/STORAGE3A/GSFLOW/Shullcas_not_bad_water_balance/GSFLOW/outputs/MODFLOW_NWT/';
MOD_simdir = '/media/gcng/STORAGE3A/GSFLOW/Shullcas_CrystalLauren5/outputs/MODFLOW_NWT/';

head_file = 'testhead.dat'; % head data

% MOD_simdir = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/GSFLOW/simdir/spinup30yr_constH/outputs/MODFLOW/';
% head_file = 'testhead.dat'; % head data

% MOD_simdir = '/home/gcng/workspace/Models/GSFLOW/GSFLOW_1.2.0_gcng/data/sagehen/output/modflow/';
% head_file = 'head_sagehen.out'; % head data

% ibound_file = 'ibound.dat'; % needed to get active cell info for reading water budget file
% bud_file = 'test.bud'; % water budget file (for flow lines)
% lpf_file = 'test2lay.lpf'; % read in for K inputs

% for WTD
% GIS_indir = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/Data/GIS/';
% surfz_fil = [GIS_indir, 'topo.asc'];
% GIS_indir = '/home/gcng/workspace/matlab_files/GSFLOW_pre-processor/data/GIS/';
% surfz_fil = [GIS_indir, 'stros_srtm_3arc_utm.asc'];
% GIS_indir = '/media/gcng/STORAGE3A/GSFLOW/Shullcas_Updated_gcng/Data/GIS/';
% surfz_fil = [GIS_indir, 'DEM.asc'];
% GIS_indir = '/home/gcng/workspace/ProjectFiles/AndesWaterResources/GSFLOW/Shullcas/data/GIS/';
% surfz_fil = [GIS_indir, 'DEM.asc'];
GIS_indir = '/media/gcng/STORAGE3A/GSFLOW/GSFLOW_input_Shullcas/CrystalLauren5/';
surfz_fil = [GIS_indir, 'DEM.asc'];

fl_hilite_standingwater = 1; % highlight WTD < 0 in green (dry cells in red)

% Only ONE can be 1, others 0
fl_MOD_PC = 0;
fl_MOD_USGS_RedHat = 0; 
fl_MOD_UBUNTU = 1;
if fl_MOD_PC + fl_MOD_USGS_RedHat + fl_MOD_UBUNTU ~= 1
    fprintf('ERROR!! Only one of following can be equal to 1! \n');
    fprintf('fl_MOD_PC. fl_MOD_USGS_RedHat, fl_MOD_UBUNTU \n');
    fprintf('Exiting...\n');
    return
end

% -- get surface elevations [m] (to plot WTD)
fid = fopen(surfz_fil, 'r');
D = textscan(fid, '%s %f', 6); 
NSEW = D{2}(1:4);
NROW = D{2}(5);
NCOL = D{2}(6);
% space discretization
DELR = (NSEW(3)-NSEW(4))/NCOL; % width of column [m]
DELC = (NSEW(1)-NSEW(2))/NROW; % height of row [m]
% set TOP to surface elevation [m]
D = textscan(fid, '%f'); 
fclose(fid);
TOP = reshape(D{1}, NCOL, NROW)'; % NROW x NCOL


% =========================================================================
if ispc 
    slashstr = '\';
elseif isunix
    slashstr = '/';
end


fl_binary = 1;  % 1 for binary
fl_dble = 0;  % 1 for dble prec, 0 for single prec

dry_cell = 1e30;
inactive_cell = -999.99;

% NOTE: for some reason, int w/ bit-length info is trailed by 0!!! (USGS linux)
% windows no bit-length info 
if fl_MOD_USGS_RedHat
    nbitread = 2;
elseif fl_MOD_PC
    nbitread = 0;
elseif fl_MOD_UBUNTU % ubuntu
    nbitread = 1;
end

prec = 4; prec_str = 'real*4';
if fl_dble, prec = 8; prec_str = 'real*8'; end

% -- Get head data and plot it as contour image plots
fid = fopen([MOD_simdir, slashstr, head_file], 'r');

ctr = 0;
while(1)
    % NOTE: for some reason, int w/ bit-length info is trailed by 0!!!
    a_info = fread(fid, nbitread, 'integer*4');
    kstp = fread(fid, 1, 'integer*4');
    if isempty(kstp)
        break
    end
    kper = fread(fid, 1, 'integer*4');
    pertim = fread(fid, 1, 'real*4');
    totim = fread(fid, 1, 'real*4');
    label = fread(fid, 16, 'char');  label = char(label); %*** ORIG
    % label = fread(fid, 15, 'char');  label = char(label);
    ncol = fread(fid, 1, 'integer*4');
    nrow = fread(fid, 1, 'integer*4');
    ilay = fread(fid, 1, 'integer*4');
    a_info = fread(fid, nbitread, 'integer*4');

    a_data = fread(fid, nbitread, 'integer*4');
    if nbitread == 0, 
        nn = ncol*nrow;
    else
        nn = a_data(1)/prec;
    end
    data = fread(fid, nn, prec_str);
    a_data = fread(fid, nbitread, 'integer*4');

    data_head = reshape(data,ncol,nrow)';
    data_WTD = TOP - data_head;
    data_WTD(data_head < -999) = nan;
    data_WTD(data_head > 0.9e30) = nan;
     
    % grow array if needed
    if ctr == 0
        data_head_all = zeros(nrow,ncol,100);
        data_WTD_all = zeros(nrow,ncol,100);
        time_info = zeros(4,100); % kstp, kper, pertim, totim
        lay_info = zeros(1,100); % layi
    elseif mod(ctr,100) == 0
        data_head_all2 = zeros(nrow,ncol,ctr+100);
        data_head_all2(:,:,1:ctr) = data_head_all;
        data_head_all = data_head_all2;
        time_info2 = zeros(4,ctr+100); % kstp, kper, pertim, totim
        time_info2(:,1:ctr) = time_info;
        time_info = time_info2;
        lay_info2 = zeros(1,ctr+100); % kstp, kper, pertim, totim
        lay_info2(:,1:ctr) = lay_info;
        lay_info = lay_info2;
    end
    ctr = ctr + 1;
    data_head_all(:,:,ctr) = data_head;
    data_WTD_all(:,:,ctr) = data_WTD;
    time_info(:,ctr) = [kstp, kper, pertim, totim];
    lay_info(ctr) = ilay;
end
fclose(fid);

data_head_all = data_head_all(:,:,1:ctr);
data_WTD_all = data_WTD_all(:,:,1:ctr);
time_info = time_info(:,1:ctr);
lay_info = lay_info(1:ctr);

data_head_all_orig = data_head_all;

% NOTE: head = -999.99 for no flow cells; ignore these
data_WTD_all(data_head_all_orig < -999.) = nan;
data_WTD_all(round(data_head_all_orig) > 0.9e30) = nan;    
data_head_all(data_head_all_orig < -999.) = nan;
data_head_all(round(data_head_all_orig) > 0.9e30) = nan; % dry cell
    
data_WTD_all_nan = data_WTD_all;
data_head_all_nan = data_head_all;

n_cm = 64;
dd_WTD = (max(data_WTD_all_nan(:)) - min(data_WTD_all_nan(:))) / (n_cm-1);
% return
data_WTD_all(data_head_all_orig < -999) = min(data_WTD_all(:)) - dd_WTD;
data_WTD_all(round(data_head_all_orig) > 0.9e30) = min(data_WTD_all(:)) - 2*dd_WTD;
cax_WTD = [min(data_WTD_all_nan(:))-dd_WTD/2-2*dd_WTD max(data_WTD_all_nan(:))+dd_WTD/2];

% % quick fix to make standing water red in plots:
% data_WTD_all(data_WTD_all<0) = min(data_WTD_all(:)) - 2*dd_WTD;

if fl_hilite_standingwater
    data_WTD_all(data_WTD_all_nan<0) = min(data_WTD_all(:)) - 3*dd_WTD;
    cax_WTD(1) = min(data_WTD_all_nan(:))-dd_WTD/2-3*dd_WTD;
end

dd_head = (max(data_head_all(:)) - min(data_head_all(:))) / (n_cm-1);
data_head_all(data_head_all_orig < -999) = min(data_head_all(:)) - dd_head;
data_head_all(round(data_head_all_orig) > 0.9e30) = min(data_head_all(:)) - 2*dd_head;
cax_head = [min(data_head_all_nan(:))-dd_head/2-2*dd_head max(data_head_all_nan(:))+dd_head/2];


% Plot start and end -WTD on single figure, for layers 1 and 2
figure(100)
i = 0;
for ctr_i = [1, ctr-1, 2, ctr]
    i = i+1;
    subplot(2,2,i),
    n_contours = 50;
    % NOTE: a couple annoying aspects about imagesc() in Matlab:
    %   - it always want to plot the y-axis in downward ascending
    %   order, hence the need to flip etc
    %   - it plots nan ("Not a number") as the lowest value on 
    %   colorbar. There is a work-around for this, but we won't
    %   bother with it here.
%                 h = imagesc(col_coord(1,:), -lay_coord(end:-1:1,1), data_head(end:-1:1,:)); 
    X = -data_WTD_all;
    h = imagesc(X(:,:,ctr_i)); 
    ytickv = get(gca,'YTick');
    yticklab = cell(size(ytickv));

    for ii = 1: length(ytickv)
        yticklab{ii} = num2str(-ytickv(ii));
    end
    set(gca, 'YTick', ytickv, 'YTickLabel', yticklab);
    m = X(X>0);
    %             m = data_head_all;
    m1 = min(m(:)); m2 = max(m(:)); 
    %             caxis([m1*.9 m2])
    %             cm = colormap;
    %             cm(1,:) = [1 1 1];
    %             colormap(cm)

    caxis(-cax_WTD(end:-1:1))
    cm = colormap(parula(n_cm));
    cm = [cm; 1 1 1; 1 0 0]; % dry cells are red
    if fl_hilite_standingwater
        cm = [cm; 0 1 0];
    end
    colormap(cm)

    colorbar;
    
    xlabel('x [m]'), ylabel('elev [m]')
    %             time_info(:,ctr_i) % kstp, kper, pertim, totim
    title(['-WTD [m] lay', num2str(lay_info(ctr_i)), ', kper ', num2str(time_info(2,ctr_i)), ', kstp ', num2str(time_info(1,ctr_i))]);
end


% Plot start and end head on single figure, for layers 1 and 2
figure(101)
i = 0;
for ctr_i = [1, ctr-1, 2, ctr]
    i = i+1;
    subplot(2,2,i),
    n_contours = 50;
    % NOTE: a couple annoying aspects about imagesc() in Matlab:
    %   - it always want to plot the y-axis in downward ascending
    %   order, hence the need to flip etc
    %   - it plots nan ("Not a number") as the lowest value on 
    %   colorbar. There is a work-around for this, but we won't
    %   bother with it here.
    
%                 h = imagesc(col_coord(1,:), -lay_coord(end:-1:1,1), data_head(end:-1:1,:)); 
        h = imagesc(data_head_all(:,:,ctr_i)); 
        ytickv = get(gca,'YTick');
        yticklab = cell(size(ytickv));

        for ii = 1: length(ytickv)
            yticklab{ii} = num2str(-ytickv(ii));
        end
        set(gca, 'YTick', ytickv, 'YTickLabel', yticklab);
%         m = data_head_all(data_head_all>0);
% %             m = data_head_all;
%         m1 = min(m(:)); m2 = max(m(:)); 
%         caxis([m1*.9 m2])
%         cm = colormap;
%         cm(1,:) = [1 1 1];
%         colormap(cm)

        caxis(cax_head)
        cm = colormap(parula(n_cm));
        cm = [1 0 0; 1 1 1; cm];
        
        colormap(cm)
    
        colorbar;
        xlabel('x [m]'), ylabel('elev [m]')
%             time_info(:,ctr_i) % kstp, kper, pertim, totim
        title(['head [m] lay', num2str(lay_info(ctr_i)), ', kper ', num2str(time_info(2,ctr_i)), ', kstp ', num2str(time_info(1,ctr_i))]);
end
% return

for ctr_i = 1:ctr
% for ctr_i = [ctr-2, ctr]
    if ncol == 1
        plot(data_head, lay_coord);
        ylabel('elev [m]');
        xlabel('head');
        pause
        hold on
    else
        % head plots
        for loop = 2
            figure(loop)
            subplot(2,2,lay_info(ctr_i)),
            n_contours = 50;
            if loop == 1            
                [C h] = contour(col_coord, lay_coord, data_head, n_contours);            
                colormap 'cool';
    %                 pause
            else
                % NOTE: a couple annoying aspects about imagesc() in Matlab:
                %   - it always want to plot the y-axis in downward ascending
                %   order, hence the need to flip etc
                %   - it plots nan ("Not a number") as the lowest value on 
                %   colorbar. There is a work-around for this, but we won't
                %   bother with it here.
    %                 h = imagesc(col_coord(1,:), -lay_coord(end:-1:1,1), data_head(end:-1:1,:)); 
                h = imagesc(data_head_all(:,:,ctr_i)); 
                ytickv = get(gca,'YTick');
                yticklab = cell(size(ytickv));
                
                for ii = 1: length(ytickv)
                    yticklab{ii} = num2str(-ytickv(ii));
                end
                set(gca, 'YTick', ytickv, 'YTickLabel', yticklab);
            end
            m = data_head_all(data_head_all>0);
%             m = data_head_all;
            m1 = min(m(:)); m2 = max(m(:)); 
            
            caxis(cax_head)
            cm = colormap(parula(n_cm));
            cm = [1 0 0; 1 1 1; cm];
            colormap(cm)

            colorbar;
            xlabel('x [m]'), ylabel('elev [m]')
%             time_info(:,ctr_i) % kstp, kper, pertim, totim
            title(['head [m] lay', num2str(lay_info(ctr_i)), ', kper ', num2str(time_info(2,ctr_i)), ', kstp ', num2str(time_info(1,ctr_i))]);
        end
        
        % WTD plots
        for loop = 2
            figure(loop+1)
            subplot(2,2,2+lay_info(ctr_i)),
            n_contours = 50;
            if loop == 1            
                [C h] = contour(col_coord, lay_coord, data_WTD_all, n_contours);            
                colormap 'cool';
    %                 pause
            else
                % NOTE: a couple annoying aspects about imagesc() in Matlab:
                %   - it always want to plot the y-axis in downward ascending
                %   order, hence the need to flip etc
                %   - it plots nan ("Not a number") as the lowest value on 
                %   colorbar. There is a work-around for this, but we won't
                %   bother with it here.
    %                 h = imagesc(col_coord(1,:), -lay_coord(end:-1:1,1), data_head(end:-1:1,:)); 
                X = -data_WTD_all;
                h = imagesc(X(:,:,ctr_i)); 
                ytickv = get(gca,'YTick');
                yticklab = cell(size(ytickv));
                
                for ii = 1: length(ytickv)
                    yticklab{ii} = num2str(-ytickv(ii));
                end
                set(gca, 'YTick', ytickv, 'YTickLabel', yticklab);
            end
            m = X(X>0);
%             m = data_head_all;
            m1 = min(m(:)); m2 = max(m(:)); 
%             caxis([m1*.9 m2])
%             cm = colormap;
%             cm(1,:) = [1 1 1];
%             colormap(cm)

            caxis(-cax_WTD(end:-1:1))
            cm = colormap(parula(n_cm));
            cm = [cm; 1 1 1; 1 0 0];
            colormap(cm)

            colorbar;
            xlabel('x [m]'), ylabel('elev [m]')
%             time_info(:,ctr_i) % kstp, kper, pertim, totim
            title(['-WTD [m] lay', num2str(lay_info(ctr_i)), ', kper ', num2str(time_info(2,ctr_i)), ', kstp ', num2str(time_info(1,ctr_i))]);
        end        
    end
%     drawnow
    pause
%     pause(0.1)
end


return



% =========================================================================
% -- Get flow data and plot it as quiver plots
% Read MODFLOW results for flow
% (only right and lower face flows, not front face flow b/c 2D cross section)

% - adjust this value... depends on how many constant head cells 
% - Get number of const head cells from ibound output file
fmt = [repmat('%4d',1,20), '\n'];
fid = fopen([MOD_simdir, slashstr, ibound_file], 'r');
ibound = fscanf(fid,fmt);
fclose(fid);
ibound = reshape(ibound, ncol, nrow)';
nConstHeadCells = length(find(ibound <0));
% (number of constant head cells + 2)
% NN = 22;  
% NN = 12;
NN = nConstHeadCells + 2;

% return

fid = fopen([MOD_simdir, slashstr, bud_file], 'r');

% - Constant head (subroutine UBUDSV)
% *** WHAT IS THIS VALUE???  
% NOTE: for some reason, int w/ bit-length info is trailed by 0!!!
a_info_i = fread(fid, nbitread, 'integer*4'); 
kstp = fread(fid, 1, 'integer*4');
kper = fread(fid, 1, 'integer*4');
label = fread(fid, 16, 'char');  label = char(label);
ncol = fread(fid, 1, 'integer*4');
nrow = fread(fid, 1, 'integer*4');
nlay = -fread(fid, 1, 'integer*4');
a_info_f = fread(fid, nbitread, 'integer*4'); 
len = zeros(NN,1);
for ii = 1:NN
    a_data_i = fread(fid, nbitread, 'integer*4'); 
    % weird... seems like mix of int and real?
%     dataconstH = fread(fid, a_data_i(1)/prec, prec_str)
    if nbitread == 0, 
        if ii == 1
            nn = 4;
        elseif ii == 2
            nn = 1;
        else
            nn = 2;
        end
    else
        nn = a_data_i(1)/4;
    end
    dataconstH = fread(fid, nn, 'integer*4');
    a_data_f = fread(fid, nbitread, 'integer*4');
    if nbitread > 0, len(ii) = a_data_i(1); end
end
% data = reshape(data,ncol,nrow,nlay);

% - cell-by-cell flow, right face (subroutine UBDSV1)
% NOTE: for some reason, int w/ bit-length info is trailed by 0!!!
a_info_i = fread(fid, nbitread, 'integer*4');
kstp = fread(fid, 1, 'integer*4');
kper = fread(fid, 1, 'integer*4');
label = fread(fid, 16, 'char');  label_right = char(label);
ncol = fread(fid, 1, 'integer*4');
nrow = fread(fid, 1, 'integer*4');
nlay = -fread(fid, 1, 'integer*4');
a_info_f = fread(fid, nbitread, 'integer*4');
a_info2_i = fread(fid, nbitread, 'integer*4');
a = fread(fid, 1, 'integer*4');  % 1
delt = fread(fid, 1, 'real*4');
pertim = fread(fid, 1, 'real*4');
totim = fread(fid, 1, 'real*4');
a_info2_f = fread(fid, nbitread, 'integer*4');
a_data = fread(fid, nbitread, 'integer*4');
if nbitread == 0
    nn = ncol*nlay;
else
    nn = a_data(1)/prec;
end
data = fread(fid, nn, prec_str);
a_data = fread(fid, nbitread, 'integer*4');
if nrow == 1, 
    data_right = reshape(data,ncol,nlay)'; 
else
    data_right = reshape(data,ncol,nrow,nlay); 
end
% data_right = permute(data_right, [2 1]);
% return

% - cell-by-cell flow, lower face (subroutine UBDSV1)
% NOTE: for some reason, int w/ bit-length info is trailed by 0!!!
a_info = fread(fid, nbitread, 'integer*4');
kstp = fread(fid, 1, 'integer*4');
kper = fread(fid, 1, 'integer*4');
label = fread(fid, 16, 'char');  label_lower = char(label);
ncol = fread(fid, 1, 'integer*4');
nrow = fread(fid, 1, 'integer*4');
nlay = -fread(fid, 1, 'integer*4');
a_info = fread(fid, nbitread, 'integer*4');
a_info2 = fread(fid, nbitread, 'integer*4');
a = fread(fid, 1, 'integer*4');  % 1
delt = fread(fid, 1, 'real*4');
pertim = fread(fid, 1, 'real*4');
totim = fread(fid, 1, 'real*4');
a_info2 = fread(fid, nbitread, 'integer*4');
a_data = fread(fid, nbitread, 'integer*4');
if nbitread == 0
    nn = ncol*nlay;
else
    nn = a_data(1)/prec;
end
data = fread(fid, nn, prec_str);
a_data = fread(fid, nbitread, 'integer*4');
if nrow == 1, % x-section
    data_lower = reshape(data,ncol,nlay)'; 
else
    data_lower = reshape(data,ncol,nrow,nlay); 
end
% data_lower = permute(data_lower, [2 1]);

% Assuming flows are volumetric... get 1D flow
dz = [TOP - BOTM(1); BOTM(1:end-1)-BOTM(2:end)];
dz_top = data_head(1,:) - BOTM(1);
if ~isempty(find(dz_top(:) < 0, 1))
    fprintf('Head dropped below top layer! Exiting.... \n');
    return
end
if nrow == 1 % x-section
    dz0 = repmat(dz, 1, ncol);
    dz0(1,:) = dz_top;
    dx0 = ones(nlay, ncol) * DELR;  % horiz
    dy0 = ones(nlay, ncol) * DELC;  % into page
else
    dz0 = reshape(dz, [1 1 nlay]);
    dz0 = repmat(dz0, [ncol, nrow, 1]);
    dz0(:,:,1) = dz_top;
    dx0 = ones(ncol, nrow, nlay) * DELR; % horiz
    dy0 = ones(ncol, nrow, nlay) * DELC; % into page
end
data_right_1D = data_right ./ (dz0 .* dy0);
data_lower_1D = data_lower ./ (dx0 .* dy0);

fclose(fid);
% return
fig_v = [10 10 12 12 11]; % head contour, head imagesc, K
p_v = [1 2 1 2 1];  % subplot index
for loop = [2 4 5]

    % -- Draw pretty streamlines 
    figure(fig_v(loop))
    subplot(2,1,p_v(loop)), hold on
    % col_coord = repmat([DELR/2: DELR: domain_len], nlay, 1); % (x)
    % col_coord = col_coord+out_x_offset;
    % lay_coord = -([TOP; BOTM(1:end-1)] + BOTM)/2;  lay_coord = repmat(lay_coord, 1, ncol); % (z)
%     lay_coord = -abs(lay_coord);
    lay_coord_lower0 = lay_coord_lower;
    if loop > 1 % flip y-axis for imagesc plots only!!
        lay_coord_lower0 = -lay_coord_lower;
    end

    % - where to start streamlines
    if loop > 1 % flip y-axis for imagesc plots only!!
        b = -[-19:2:0]';
    else
        b = [-19:2:0]';
    end
    a = [col_coord_right(1,1): 30: 343]';
    start_col_coord = [a; ones(size(b))*a(1)]; 
    start_lay_coord = [ones(size(a))*b(end); b];
    start_col_coord2 = []; 
    start_lay_coord2 = [];

    start_col_coord0 = [start_col_coord; start_col_coord2];
    start_lay_coord0 = [start_lay_coord; start_lay_coord2];
    h =streamline(col_coord_right,lay_coord_lower0,data_right_1D,data_lower_1D,start_col_coord0,start_lay_coord0);
    % h = streamslice(col_coord_right,lay_coord,data_right_1D,-data_lower_1D); % this has bad arrow sizes...
    % set(gca,'XLim',[DELR/2 260], 'YLim', [417 424]);

    % plot streamlines
    xlabel('x [m]'), ylabel('z [m below max water table elev.]');
    % title('Streamlines')
    
    % plot quiver (arrows)
    Xdata0 = get(h, 'XData'); Ydata0 = get(h, 'YData');
    hold on,
    N = length(Xdata0);
    scale=0.1; % orig
%     scale=0.5;
%     if loop == 1 || loop == 2 || loop == 3
        for ii = 1:N
        %     NN = length(Xdata0{ii});
        %     n = [1:round(NN/20):NN];
        % %     [Xdata, ind] = sort(Xdata0{ii}, 'ascend');
        % %     Ydata = Ydata0{ii}(ind);
            Xdata = Xdata0{ii};
            Ydata = Ydata0{ii};

            ind = ~isnan(Xdata) & ~isnan(Ydata);
            Xdata = Xdata(ind); Ydata = Ydata(ind);

            NN = length(Xdata);
            n = [1:round(NN/20):NN];

            Zdata_right_1D = interp2(col_coord_right, lay_coord_lower0, data_right_1D, Xdata, Ydata);
            Zdata_lower_1D = interp2(col_coord_right, lay_coord_lower0, data_lower_1D, Xdata, Ydata);
            quiver(Xdata(n), Ydata(n), Zdata_right_1D(n), Zdata_lower_1D(n), scale, 'Color', 'b'); %set(gca,'YDir', 'Reverse');   

%         end
    end
    if loop == 5
        set(gca,'YDir', 'Reverse');
        ylabtick_neg = get(gca,'YTick');
        ylab = cell(size(ylabtick_neg));
        for ii = 1: length(ylabtick_neg)
            ylab{ii} = num2str(-ylabtick_neg(ii));
        end
        set(gca,'YTick', ylabtick_neg, 'YTickLabel', ylab);
    end
end

% print('-dtiff', '-f10', headflowfigfile);
% print('-dtiff', '-f11', Ksatfigfile);

