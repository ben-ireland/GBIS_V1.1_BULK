function [insar, obs, nObs] = loadInsarData(insar, geo, cmap)

% Function to ingest and subsample InSAR data from pre-prepared *.mat file
%
% Usage: [insar, obs, nObs] = loadInsarData(insar, geo, cmap)
% Input Parameters:
%       insar: structure with insar data and related information
%       geo: structure with local coordinates origin and bounding box
%       cmap: colormaps for plotting
%
% Output Parameters:
%       insar: structure with added subsampled data vector and radar look
%       parameters
%       obs: coordinates of observation points after subsampling
%       nObs: number of observation points
% =========================================================================
% This function is part of the:
% Geodetic Bayesian Inversion Software (GBIS)
% Software for the Bayesian inversion of geodetic data.
% Copyright: Marco Bagnardi, 2018
%
% Email: gbis.software@gmail.com
%
% Reference: 
% Bagnardi M. & Hooper A, (2018). 
% Inversion of surface deformation data for rapid estimates of source 
% parameters and uncertainties: A Bayesian approach. Geochemistry, 
% Geophysics, Geosystems, 19. https://doi.org/10.1029/2018GC007585
%
% The function may include third party software.
% =========================================================================
% Last update: 8 August, 2018


%% Initialise variables
global outputDir  % Set global variables

nPoints = 0;
LonLat = zeros(0,2);

%% Start loading data
disp 'Loading InSAR data into GBIS'
for i = 1:length(insar)
    loadedData = load(insar{i}.dataPath); % load *.mat file
%     Apply bounding box and remove data points outside the AOI
    iOutBox = find(loadedData.Lon < geo.boundingBox(1) | loadedData.Lon > geo.boundingBox(3) | loadedData.Lat > geo.boundingBox(2) | loadedData.Lat < geo.boundingBox(4));
    if sum(iOutBox)>0
        loadedData.Phase(iOutBox) = [];
        loadedData.Lat(iOutBox) = [];
        loadedData.Lon(iOutBox) = [];
        loadedData.Heading(iOutBox) = [];
        loadedData.Inc(iOutBox) = [];
    end
    OptimalX = isfield(loadedData, 'MidLoni');
    OptimalY = isfield(loadedData, 'MidLati');

    if OptimalX ==1 & OptimalY ==1
        %   Find new indexes of the middle lat and lon values
        [~, MidLati2] = min(abs(loadedData.Lat-loadedData.MidLat));
        [~, MidLoni2] = min(abs(loadedData.Lon-loadedData.MidLon));
    end
 %% Start loading data (pt 2)
    
    convertedPhase = (loadedData.Phase / (4*pi) )  * insar{i}.wavelength;    % Convert phase from radians to m
    los = single(-convertedPhase);  % Convert to Line-of-sigth displacement in m
    ll = [single(loadedData.Lon) single(loadedData.Lat)];   % Create Longitude and Latitude 2Xn matrix
    xy = llh2local(ll', geo.referencePoint);    % Transform from geografic to local coordinates
    
    nPointsThis = size(ll, 1);   % Calculate length of current InSAR data vector
    xy = double([(1:nPointsThis)', xy'*1000]);   % Add ID number column to xy matrix with local coordinates
    
    % Extract filename to be included in figure names
    [path, name, ext] = fileparts(insar{i}.dataPath);

    if geo.QT ~=1
        disp 'Creating wrapped summary InSAR figures'
        % Plot wrapped interferogram
        figure('Position', [1, 1, 700, 700]);
        plotInsarWrapped(xy, los, insar{i}.wavelength, cmap, name);
        saveas(gcf, [pwd,'/Inversion_Results/',outputDir,'/Figures/Wrapped_', name, '.png'])
        
        disp 'Creating unwrapped summary InSAR figures'
        % Plot unwrapped interferogram
        figure('Position', [1, 1, 700, 700]);
        plotInsarUnwrapped(xy, los, cmap, name);
        saveas(gcf,[pwd,'/Inversion_Results/',outputDir,'/Figures/Unwrapped_',name,'.png'])
    end
    disp 'Loading RAW InSAR data'
    %% Load raw InSAR data - added:
    rawData = load(insar{i}.rawDataPath); % load *.mat file
    
%     Apply bounding box and remove data points outside the AOI
    iOutBox = find(rawData.Lon < geo.boundingBox(1) | rawData.Lon > geo.boundingBox(3) | rawData.Lat > geo.boundingBox(2) | rawData.Lat < geo.boundingBox(4));
    if sum(iOutBox)>0
        rawData.Phase(iOutBox) = [];
        rawData.Lat(iOutBox) = [];
        rawData.Lon(iOutBox) = [];
        rawData.Heading(iOutBox) = [];
        rawData.Inc(iOutBox) = [];
    end
    
    %Process and display raw InSAR data
    
    convertedPhase_raw = (rawData.Phase / (4*pi) )  * insar{i}.wavelength;    % Convert phase from radians to m
    los_raw = single(-convertedPhase_raw);  % Convert to Line-of-sigth displacement in m
    ll_raw = [single(rawData.Lon) single(rawData.Lat)];   % Create Longitude and Latitude 2Xn matrix
    xy_raw = llh2local(ll_raw', geo.referencePoint);    % Transform from geografic to local coordinates
    nPointsThis_raw = size(ll_raw, 1);   % Calculate length of current InSAR data vector
    xy_raw = double([(1:nPointsThis_raw)', xy_raw'*1000]);   % Add ID number column to xy matrix with local coordinates
    
    % Extract filename to be included in figure names
    [path_raw, name_raw, ext_raw] = fileparts(insar{i}.rawDataPath);
    disp 'Plotting wrapped input interferogram'
    % Plot wrapped interferogram
    figure('Position', [1, 1, 700, 700]);
    plotInsarWrappedRaw(xy_raw, los_raw, insar{i}.wavelength, cmap, name_raw);
    saveas(gcf, [pwd,'/Inversion_Results/',outputDir,'/Figures/Wrapped_', name_raw, '.png'])
    disp 'Plotting unwrapped input interferogram'
    % Plot unwrapped interferogram
    figure('Position', [1, 1, 700, 700]);
    plotInsarUnwrappedRaw(xy_raw, los_raw, cmap, name_raw);
    saveas(gcf,[pwd,'/Inversion_Results/',outputDir,'/Figures/Unwrapped_',name_raw,'.png'])
    
    %Save raw data to 'insar' data structure
    insar{i}.obs_raw = xy_raw'; %added
    insar{i}.dLos_raw = los_raw'; %added
    Heading_raw = rawData.Heading; %Added
    Incidence_raw = rawData.Inc; %Added
    insar{i}.dHeading_raw = Heading_raw'; %Added
    insar{i}.dIncidence_raw = Incidence_raw'; %Added

    %% Run data vector subsampling using Quadtree and display
    if geo.QT==1
        disp 'Downsampling with Quadtree'
        [nb, err, nPts, centers, dLos, polys, xLims, yLims] = quadtree(xy, los', insar{i}.quadtreeThresh, 1000, 1); % Run Quadtree on los vector
        c = max(abs([min(los), max(los)])); % Calculate maximu value for symmetric colormap
        caxis([-c c])
        axis equal; axis tight;
        axis square;
        cbar = colorbar; ylabel(cbar, 'Line-of-sight displacement m','FontSize', 14);
        %colormap(jet)
        colormap(cmap.redToBlue)
        xlabel('X distance from local origin (m)','FontSize', 14)
        ylabel('Y distance from local origin (m)','FontSize', 14)
        t = title(['Subsampled data. Number of data points used:', num2str(nb)],'FontSize', 18);
        set(t,'Position',get(t,'Position')+[0 1000 0]);
        drawnow
        saveas(gcf, [pwd,'/Inversion_Results/',outputDir,'/Figures/Subsampled_', name, '.png'])
        
        K = convhull(xy(:,2), xy(:,3));
        
        figure()
        pointsize = 100;
        scatter(xy(:,2),xy(:,3),pointsize,los,"o","filled")
        %colormap(jet)
        colormap(cmap.redToBlue)
        hold on
        pointsize = 150;
        scatter(centers(:,1), centers(:,2),pointsize, dLos,"square","filled",'MarkerEdgeColor','k','LineWidth',2)

        % Extract radar look vector information for subsampled points
        disp 'Extracting radar look vector parameters ...'
        [dHeading] = quadtreeExtract(xy, loadedData.Heading, xLims, yLims);    % Extract heading angle values based on quadtree partition
        disp(['Mean heading angle: ', num2str(mean(dHeading)), ' degrees'])
        [dIncidence] = quadtreeExtract(xy, loadedData.Inc, xLims, yLims);  % Extract values based on quadtree partition
        disp(['Mean incidence angle: ', num2str(mean(dIncidence)), ' degrees'])
        disp(['Max and min LoS displacement in m:', num2str(max(dLos)), '  ', num2str(min(dLos))]) %edit
        disp 'Extracting observation points height ...'
        disp (['Number of quadtree points: ' ,num2str(nb)])
        pts.xy = [(1:nb)', centers];    % Generate Nx3 [# x y] matrix with local coordinates of data points (centers of Quadtree cells)
        pts.LonLat = local2llh(pts.xy(:,2:3)'/1000, geo.referencePoint)'; % Convert x and y coordinates into Lon Lat coordinates

        % Include Quadtree results into insar structure
        insar{i}.obs = pts.xy(:,2:3);
        insar{i}.dLos = dLos;
        insar{i}.dHeading = dHeading;
        insar{i}.dIncidence = dIncidence;
    
%% Create inverse of covariance matrix
    
        obs = pts.xy(:,2:3);
    else
        disp(['Max and min LoS displacement in m:', num2str(max(los)), '  ', num2str(min(los))]) %edit
        insar{i}.obs = xy'; %edit
        insar{i}.dLos = los'; %edit
        Heading = loadedData.Heading; %Added
        Incidence = loadedData.Inc; %Added
        insar{i}.dHeading = Heading'; %Added
        insar{i}.dIncidence = Incidence'; %Added
    end

    if geo.QT==0
        obs = llh2local(ll', geo.referencePoint)*1000; %Added
        [X1,X2] = meshgrid(obs(1,:)); % Create square matrices of Xs %edited
        [Y1,Y2] = meshgrid(obs(2,:)); % Create square matrices of Ys %edited
    else

        [X1,X2] = meshgrid(obs(:,1)); % Create square matrices of Xs
        [Y1,Y2] = meshgrid(obs(:,2)); % Create square matrices of Ys
    end

    H = sqrt((X1-X2).^2 + (Y1 - Y2).^2); % Calculate distance between points
    
    % Assign default values if sill, range and nugget are not provided
    if  ~isfield(insar{i},'sillExp')
        disp 'sillExp value not found, assigning default value 0.04^2'
        insar{i}.sillExp = 0.04^2;
    end
    
    if ~isfield(insar{i},'nugget')
        disp 'nugget value not found, assigning default value 0.002^2'
        insar{i}.nugget = 0.002^2;
    end
    
    if ~isfield(insar{i},'range')
        disp 'range value not found, assigning default value 5000'
        insar{i}.range = 5000;
    end
    
    if geo.QT==0
        %nb = nPoints; %Added
        nb = length(insar{i}.dLos); %Added (nb = number of polygons from Quadtree normally)
    end
    
    covarianceMatrix = insar{i}.sillExp * exp(-H/insar{i}.range) + insar{i}.nugget*eye(nb); % Calculate covariance matrix for exponential model with nugget
    %covarianceMatrix = insar{i}.sillExp * exp(-3*H/insar{i}.range) + insar{i}.nugget*eye(nb); % Added from GBIS v3.0 (-H changed to -3*H)
    insar{i}.invCov = inv(covarianceMatrix); % Calculate inverse of covariance matrix

    %% Create output figure of convariance matrices (Added Ben Ireland, August 2025)
    f = figure();
    TLCov = tiledlayout(1,3)
    nexttile
    imagesc(H)
    axis image
    c = colorbar;
    c.Label.String = 'Distance between points (m)';
    title(['Sill: ',num2str(insar{i}.sillExp)])
    subtitle('Distance between points')
    set(gca,'fontsize',7)

    nexttile
    imagesc(covarianceMatrix)
    axis image
    colorbar;
    title(['Range: ',num2str(insar{i}.range)])
    subtitle('Covariance matrix')
    set(gca,'fontsize',7)

    nexttile
    imagesc(insar{i}.invCov)
    axis image
    colorbar;
    title(['Nugget: ',num2str(insar{i}.nugget)])
    subtitle('Weighting matrix')
    set(gca,'fontsize',7)

    saveas(f,[pwd,'/Inversion_Results/',outputDir,'/Figures/Covariance_', name, '.png'])

    f2 = figure()
    scatter(xy(:,2),xy(:,3),50,diag(insar{i}.invCov))
    colorbar
    box on
    title('Approx. weighting (diag of invCov matrix)')
    saveas(f2,[pwd,'/Inversion_Results/',outputDir,'/Figures/Weighting_', name, '.png'])

    %% ADDED - Find optimal lat and lon values if synthetic values
    OptMethod = 2; % Method for optimal Lat/Lon - 1 = on mid lat/lon | 2 = on max displacement
    if contains(insar{i}.dataPath,'unwrapped_') % Identify if input data is synthetic
        disp 'Synthetic input data - Saving optimal x/y locations for accuracy comparison'
        if OptMethod ==1
            if OptimalX ==1 && OptimalY ==1
                OptX = obs(1,loadedData.MidLoni);
                OptY = obs(2,loadedData.MidLati);

                OptX2 = obs(1,MidLoni2);
                OptY2 = obs(2,MidLati2);

                MidLat = loadedData.MidLat;
                MidLon = loadedData.MidLon;
                save([pwd,'/Inversion_Results/',outputDir,'/','OptXY_',name,'.mat'],'MidLati2','MidLoni2','MidLat','MidLon','OptX','OptY','OptX2','OptY2'); %Added
            end
        elseif OptMethod ==2
            if geo.QT ==1
                [~, MaxDispI] = max(dLos);
            else
                [~, MaxDispI] = max(los);
            end
            OptX = obs(1,MaxDispI);
            OptY = obs(2,MaxDispI);
            save([pwd,'/Inversion_Results/',outputDir,'/','OptXY_',name,'.mat'],'OptX','OptY'); %Added
        end
    end

    clear X1 X2 Y1 Y2 obs H covarianceMatrix

    insar{i}.ix = nPoints+1:nPoints+nb; % Extract index of data points in obs vector for this interferogram
    
    if geo.QT==1     
        nPoints = nPoints + nb; % Number of data points
    else
        nPoints = nPoints + nb; % Added
    end

    if geo.QT==1    
         LonLat = [LonLat; pts.LonLat]; % Longitude Latitude matrix
    else
         LonLat = [LonLat; ll]; % Added
    end
end

obs = llh2local([LonLat'; zeros(1,nPoints)],geo.referencePoint')*1000;
obs = [obs; zeros(1, size(obs,2))]; % Coordinates of observation points
nObs = size(obs,2); % Total number of observation points

