clearvars; clc; close all

addpath(genpath('/home/jl20461/GBIS_V1.1_Mod4/ICA'));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% show the data using ncdisp(;
DATA                = permute(ncread('corbetti_079D_08294_131313.nc','DATA'),[2 1 3])*100;
Lon_alb             = ncread('corbetti_079D_08294_131313.nc','lon');
Lat_alb             = ncread('corbetti_079D_08294_131313.nc','lat');
Time                = ncread('corbetti_079D_08294_131313.nc','time');
Dates               = datenum('2015-01-15','yyyy-mm-dd') + Time;

%% Clip SAR image
dimx_space          =   [160:320];
dimy_space          =   [160:320];
time_range          =   [1:114];

TS                  =   DATA(dimy_space,dimx_space,time_range);
[nx,ny,nifgm]       =   size(TS);   % Number of observations

%% Pixels to plot timeseries
pix_x               = 100;              % pixel location (x)
pix_y               = 85;               % pixel location (y) 

%% ICA Inputs
ICA_method          = "Direct";         % Whitened or Direct
nlastEig_space      = 4;                % index of the last (smallest) eigenvalue to be retained (PCA)
ncomp               = nifgm-1;          % Number of independent components to be estimated

pixel               = permute(TS(pix_y,pix_x,:),[3 1 2]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Fast ICA (Explanation)
% Sets up the data so that each row is a interferogram and each column is an pixel timeseries (observation)
% ICA [icasig, A, W] based on reduction of dimension determined by eignvalues used
% Outputs:    icasig  =   Independent components
%             A       =   Corresponding mixing matrix
%             W       =   Separating matrix
% help fastica > to get more information about fastica

mixedsig_sICA           = reshape(TS,nx*ny,nifgm)';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ICA with whitened data
if ICA_method == "Whitened";
    [whitesig, WM ,DWM]         = fastica(mixedsig_sICA,'only','white','lastEig',nlastEig_space);
    [ica, mixing, unmixing]         = fastica(mixedsig_sICA,'whiteSig',whitesig,'whiteMat', WM,'dewhiteMat', DWM,'numOfIC',ncomp);
end

% Directly ICA
if ICA_method == "Direct"; 
    [ica, mixing, unmixing]         = fastica(mixedsig_sICA,'numOfIC',ncomp,'lastEig',nlastEig_space); 
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Reconstruct ICA
for k = 1:size(ica,1)
    ICA_Reconstructed(:,:,k)    = mixing(:,k) * ica(k,:);
end

%% Creates mask
Mask            = TS(:,:,nifgm);

%% Visualising reconstructed IC
% Setup figure
ICA_Synth       = figure(5); clf(); ICA_Synth.Position = [33 81 981 896];
Spatial_pos     = (1:size(ICA_Reconstructed,3))*3-2;
Timecourse_pos  = [(1:size(ICA_Reconstructed,3))*3-1;(1:size(ICA_Reconstructed,3))*3]';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fully reconstructed signal
FullReconstructed   = permute(reshape(mixing * ica,nifgm,nx,ny),[2 3 1]);

subplot(numel(Spatial_pos)+1, 3,1)
imagesc(FullReconstructed(:,:,nifgm),'AlphaData',Mask); axis image; colorbar; hold on; 
caxis([-max(FullReconstructed(:)) max(FullReconstructed(:))])
plot(pix_x,pix_y,'kp','MarkerFaceColor','k','MarkerSize',10)
colormap(gcf, flipud(cbrewer2('RdYlBu', 256))); 
set(gca,'YTick',[],'XTick',[])
title('Fully Reconstructed')
yline(0,'--'); 

subplot(numel(Spatial_pos)+1, 3, [2:3]);
plot(Dates, permute(FullReconstructed(pix_y,pix_x,:),[3 1 2]),'ko','LineWidth',1,'MarkerFaceColor','k','MarkerSize',4); hold on; 
xlim([Dates(1) Dates(numel(Dates))])
datetick('x','mm/yy','keeplimits')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Individual ICs %
for k   = 1:length(Spatial_pos)
    
    subplot(numel(Spatial_pos)+1, 3, Spatial_pos(k)+3);
    FullReconstructed    = permute(reshape(ICA_Reconstructed(:,:,k),nifgm,nx,ny),[2 3 1]);

    % Spatial Plot
    imagesc(FullReconstructed(:,:,nifgm),'AlphaData',Mask); axis image; colorbar; hold on; 
    plot(pix_x,pix_y,'kp','MarkerFaceColor','k','MarkerSize',10)
    caxis([-max(FullReconstructed(:)) max(FullReconstructed(:))])
    colormap(gcf, flipud(cbrewer2('RdYlBu', 256)));
    title(sprintf('Independent Comp. %0.0f',k))
    set(gca,'YTick',[],'XTick',[])
    yline(0,'--'); 

    % Time Course
    subplot(numel(Spatial_pos)+1, 3, Timecourse_pos(k,:)+3);
    plot(Dates, permute(FullReconstructed(pix_y,pix_x,:),[3 1 2]),'ko','LineWidth',1,'MarkerFaceColor','k','MarkerSize',4); hold on; 
    xlim([Dates(1) Dates(numel(Dates))])
    datetick('x','mm/yy','keeplimits')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(ICA_Synth, 'color', 'w');
fontsize(ICA_Synth, 20, 'pixels');