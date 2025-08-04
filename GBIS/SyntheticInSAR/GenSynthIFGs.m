function [SynData] = GenSynthIFGs(Deformation, Stratified, Turbulent, Wrapped, Quake, Dyke, Sill, Mogi, Penny, Heading, Incidence, wavelength, Source_Type, k, ID, CoherenceMask)   
% Ben Ireland, University of Bristol
%   November 2023 - modified from scripts compiled by Pui Anantrasirichai
%   https://github.com/pui-nantheera/Synthetic_InSAR_image

% Script to generate individual sythetic interferograms with deformation
% and/or stratified noise and/or turbulent noise

% Paths to subfolders need to be generated before the script is run for the
% first time e.g.
% "(addpath(genpath('directory/Synthetic_InSAR_image-main-mod'));"

% TO ADD:
% 1. SAVING OF THE ORIGINAL PARAMETERS USED IN THE SYNTHETIC IFG

%CHANGE EACH RUN: Source type, heading and incidence angle, gap time (days), links
%for the GACOS files, mask number and option, save directory, save name

%ALL UNITS ARE IN RADIANS

% Load in colormaps for plotting InSAR data
cmap.Seismo = colormap_cpt('GMT_seis.cpt', 100); % GMT Seismo colormap for wrapped interferograms
cmap.redToBlue = colormap_cpt('polar.cpt', 100); % Red to Blue colormap for unwrapped interferograms
disp(num2str(k))

% UNIT CONVESIONS
m2rad = 4.*pi./wavelength;
rad2m = (wavelength./(4.*pi));
zen2los = 1./cos(Incidence./180.*pi);

% Initialise directory structures
if ~exist([pwd,'/SyntheticIFGs'],'dir')
    mkdir(pwd,'SyntheticIFGs')
    addpath([pwd,'/SyntheticIFGs'])
end

%% Deformation
if Deformation == 1
    
    % Source type
    if Source_Type ==1
        Source = 'Quake';
        Parameters = Quake;
    elseif Source_Type ==2
        Source = 'Dyke';
        Parameters = Dyke;
    elseif Source_Type ==3
        Source = 'Rectangular Sill';
        Parameters = Sill;
    elseif Source_Type ==4
        Source = 'Mogi';
        Parameters = Mogi;
    elseif Source_Type ==5
        Source = 'Penny';
        Parameters = Penny;
    else
        error('Incorrect source type value')
    end

    if ~exist([pwd,'/SyntheticIFGs/',Source,'_',Mogi.ID],'dir')
        mkdir([pwd,'/SyntheticIFGs'],strcat(Source,'_',Mogi.ID))
        addpath([pwd,'/SyntheticIFGs/',Source,'_',Mogi.ID])
    end
    imageSize = 500; %Image resolution in pixels

    x=[-25000:100:25000-100];
    y=[-25000:100:25000-100];

    [los_grid_wrap, los_grid] = generateDeformation(Source_Type, x, y, Quake, Dyke, Sill, Mogi, Penny, Heading, Incidence);
    los_grid = los_grid/(wavelength/2)*2*pi; %Convert to radians from m

    Deform = 'def';
else
    los_grid = 0;
    Deform = '';
end

%% Stratified noise
if Stratified == 1
    
    %Files without the .ztd extension
    filename1 = 'Path/to/GACOS/at/Start/Date';
    filename2 = 'Path/to/GACOS/at/End/Date';
    
    [~,~,atmo1] = read_GACOS(filename1); %First image (binary images tasked from GACOS)
    [~,~,atmo2] = read_GACOS(filename2); %Second image
    
    atmo = (atmo2-atmo1).*zen2los.*m2rad;
    atmo = imresize(atmo, [imageSize imageSize]);
    mask = imerode(atmo~=0,strel('disk',3));
    mask = mask(end:-1:1,:);
    
    % Compare GACOS signals
    figure()
    imagesc(atmo)
    Strat = 'strat';
else
    Strat = '';
    atmo = 0;
end

%% Turbulent noise
if Turbulent.Signal == 1
    
    % input parameters
    rows = 100;
    cols = 100;
    psizex = 1;
    psizey = 1;
    covmodel_type = 0; %0=exponential; 1=expcos; 2=ebessel
    maxvar = 1000*rad2m*Turbulent.NoiseLevel; % Average pre-GACOS turbulent noise in timeseries from Morishita et al. (2020) in mm
    %maxvar = 7.5; %maximum covariance (mm) (Sill)
    alpha = 0.008; %decay constant (range - mm^2)
%     nugget = 0.005; %nugget value (mm^2)
    %atm_pets = pcmc_atmNugget(rows,cols,maxvar,alpha,nugget,covmodel_type,N,psizex,psizey);
    atm_pets = pcmc_atm(rows,cols,maxvar,alpha,covmodel_type,1,psizex,psizey);

    curTur = imresize(atm_pets,[imageSize imageSize]);
    curTur = m2rad.*(curTur/1000);
    RMSE = sqrt(sum(curTur(:).^2/numel(curTur)))*rad2m; %RMSE in m of turbulent noise

    Turb = 'tur';
else
    Turb = '';
    curTur=0;
end

%% Combine signals
combined = los_grid + atmo + curTur; 

%Add coherence mask
combined(CoherenceMask~=1) = NaN;

%% Save and plot unwrapped signals
if ~exist(strcat(pwd,'/SyntheticIFGs/',Source,'/',ID,num2str(k)),'dir')
    mkdir(strcat(pwd,'/SyntheticIFGs/',Source),strcat(ID,num2str(k)))
    addpath(strcat(pwd,'/SyntheticIFGs/',Source,'/',ID,num2str(k)))
end

savedir = strcat(pwd,'/SyntheticIFGs/',Source,'/',ID,num2str(k),'/');
imwrite(los_grid,strcat(savedir,'los',num2str(k),'.png'));
imwrite(atmo,strcat(savedir,'atmo',num2str(k),'.png'));
imwrite(curTur,strcat(savedir,'cur',num2str(k),'.png'));
imwrite(combined,strcat(savedir,'combined',num2str(k),'.png'));
save(strcat(savedir,'unwrapped_los','_',Source,'_',Mogi.ID,'_',Deform,'_',Strat,'_',Turb,'_',num2str(k),'.mat'),'los_grid','atmo','curTur','combined','Parameters','Heading', 'Incidence', 'wavelength');

% Figure
clim = max(abs([min(combined(:)), max(combined(:))])); % Calculate maximum value for symmetric colormap
figure()
subplot(2,2,1)
imagesc(los_grid)
title('Deformation)')
colormap(cmap.redToBlue)
axis square
caxis([-clim, clim])
subplot(2,2,2)
imagesc(atmo)
title('Stratified noise')
colormap(cmap.redToBlue)
axis square
caxis([-clim, clim])
subplot(2,2,3)
imagesc(curTur)
title('Turbulent noise')
colormap(cmap.redToBlue)
axis square
caxis([-clim, clim])
subplot(2,2,4)
imagesc(combined)
title('Full interferogram')
colormap(cmap.redToBlue)
axis square
caxis([-clim, clim])
c = colorbar;
c.Label.String = 'unwrapped phase (radians)';
%sgtitle(['Source type: ',Source,'   ','Volume (m^3): ',sprintf('%2e',Mogi.Volume),'      ',' Depth (km): ',num2str(Mogi.Depth)]);
saveas(gcf,strcat(savedir,'unwrappedFig_',num2str(k),'.png'));

% Save and plot wrapped signals (optional)
if Wrapped == 1

    if Deformation == 1
        los_grid_wrap = wrapTo2Pi(los_grid);
        %los_grid_wrap = (los_grid_wrap-min(los_grid_wrap(:)))/range(los_grid_wrap(:));
    end
    
    if Stratified == 1 
        atmo = wrapTo2Pi(atmo);
        %atmo = (atmo-min(atmo(:)))/range(atmo(:)).*mask;
    end
    
    if Turbulent.Signal == 1 
        curTur = wrapTo2Pi(curTur);
        %curTur = (curTur-min(curTur(:)))/range(curTur(:));
    end
    
    combinedWrap = wrapTo2Pi(combined);

    cmin = 0;
    cmax = 2*pi;
    tickPositions = [0, pi, 2*pi];
    tickLabels = {'0','\pi','2\pi'};
    
    % Figure
    figure()
    subplot(2,2,1)
    imagesc(los_grid_wrap)
    title('Deformation)')
    colormap(cmap.Seismo)
    axis square
    subplot(2,2,2)
    imagesc(atmo)
    title('Stratified noise')
    colormap(cmap.Seismo)
    axis square
    subplot(2,2,3)
    imagesc(curTur)
    title('Turbulent noise')
    colormap(cmap.Seismo)
    axis square
    subplot(2,2,4)
    imagesc(combinedWrap)
    title('Full interferogram')
    colormap(cmap.Seismo)
    axis square
    c = colorbar;
    caxis([cmin, cmax]);
    c.Ticks = tickPositions;
    c.TickLabels = tickLabels;
    c.Label.String = 'wrapped phase (radians)';
    %sgtitle(['Source type: ',Source,'   ','Volume (m^3): ',sprintf('%2e',Mogi.Volume),'      ',' Depth (km): ',num2str(Mogi.Depth)]);
    saveas(gcf,strcat(savedir,'wrappedFig_',num2str(k),'.png'));
    
    imwrite(los_grid_wrap,strcat(savedir,'los_wrap',num2str(k),'.png'));
    imwrite(atmo,strcat(savedir,'atmo_wrap',num2str(k),'.png'));
    imwrite(curTur,strcat(savedir,'curTur_wrap',num2str(k),'.png'));
    imwrite(combinedWrap,strcat(savedir,'combined_wrap',num2str(k),'.png'));
    save(strcat(savedir,'wrapped_los','_',Source,'_',Mogi.ID,'_',Deform,'_',Strat,'_',Turb,'_',num2str(k),'.mat'),'los_grid_wrap','atmo','curTur','combinedWrap','Parameters','Heading', 'Incidence', 'wavelength');
end
%% Write output variables
SynData.def = los_grid;
SynData.strat = atmo;
SynData.turb = curTur;
SynData.combined = combined;
SynData.sourceType = Source;
SynData.filepath = strcat(savedir,'unwrapped_los','_',Source,'_',Mogi.ID,'_',Deform,'_',Strat,'_',Turb,'_',num2str(k),'.mat');

end