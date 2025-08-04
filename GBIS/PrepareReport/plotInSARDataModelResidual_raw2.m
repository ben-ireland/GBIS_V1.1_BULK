function [xy_raw, residual_raw] = plotInSARDataModelResidual_raw2(insar, geo, invpar, invResults, modelinput, saveName)

% Function to generate plot with comparison between InSAR data, model, and
% residuals
%
% Usage: plotInSARDataModelResidual(insar, geo, invpar, invResults, modelinput, saveName, fidHTML, saveflag)
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
%%
global outputDir  % Set global variables
global inputFileN

% Create colormaps for plotting InSAR data
cmap.seismo = colormap_cpt('GMT_seis.cpt', 100); % GMT Seismo colormap for wrapped interferograms
cmap.redToBlue = colormap_cpt('polar.cpt', 100); % Red to Blue colormap for unwrapped interferograms

for i=1:length(insar)
    % Load and display DATA
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
    
    % Patch scattered data for faster plotting
    edge = round(min(abs(diff(xy_raw(:,3)))))+2; % Size of patch set to minumum distance between points
    if edge < 50
        edge = 50;
    end
    xs = [xy_raw(:,2)'; xy_raw(:,2)'+edge; xy_raw(:,2)'+edge; xy_raw(:,2)']; % Coordinates of four vertex of patch
    ys = [xy_raw(:,3)'; xy_raw(:,3)'; xy_raw(:,3)'+edge; xy_raw(:,3)'+edge];
    
    % Extract filename to be included in figure name
    [path_raw, name_raw, ext_raw] = fileparts(insar{i}.rawDataPath);
    
    % Display wrapped DATA interferogram at 5.6 cm wavelength
    figure('Position', [1, 1, 1200, 1000]);
    ax1 = subplot(2,3,1);
    plotInsarWrappedRaw(xy_raw,los_raw, insar{i}.wavelength, cmap, 'DATA');
    colormap(ax1,cmap.seismo)
    freezeColors
    
    % Display DATA unwrapped interferogram
    ax2 = subplot(2,3,4);
    plotInsarUnwrappedRaw(xy_raw,los_raw, cmap, 'DATA');
    c = max(abs([min(los_raw), max(los_raw)])); % Calculate maximum value for symmetric colormap
    caxis([-c c])
    colormap(ax2,cmap.redToBlue)
    freezeColors
       
    % Calculate MODEL
    constOffset = 0;
    xRamp = 0;
    yRamp = 0;
    
    if i == 1
        if insar{i}.constOffset == 'y'
            constOffset = invResults.model.mIx(end);
            invResults.model.mIx(end) = invResults.model.mIx(end)+1;
        end
        if insar{i}.rampFlag == 'y'
            xRamp = invResults.model.mIx(end);
            yRamp = invResults.model.mIx(end)+1;
            invResults.model.mIx(end) = invResults.model.mIx(end)+2;
        end
    end
    
   if i > 1
        if insar{i}.constOffset == 'y'
            constOffset = invResults.model.mIx(end);
            invResults.model.mIx(end) = invResults.model.mIx(end)+1;
        end
        if insar{i}.rampFlag == 'y'
            xRamp = invResults.model.mIx(end);
            yRamp = invResults.model.mIx(end)+1;
            invResults.model.mIx(end) = invResults.model.mIx(end)+2;
        end
    end
       
    modLos_raw = forwardInsarModel(insar{i},xy_raw,invpar,invResults,modelinput,geo,rawData.Heading,rawData.Inc,constOffset,xRamp,yRamp); % Modeled InSAR displacements
    
    % Display MODEL wrapped interferogram at 5.6 cm wavelength
    ax3=subplot(2,3,2);
    plotInsarWrappedRaw(xy_raw,modLos_raw',insar{i}.wavelength,  cmap, 'MODEL');
    colormap(ax3,cmap.seismo)
    freezeColors
    
    % Display MODEL unwrapped interferogram
    ax4=subplot(2,3,5);
    plotInsarUnwrappedRaw(xy_raw,modLos_raw', cmap, 'MODEL');
    caxis([-c c])
    colormap(ax4,cmap.redToBlue)
    freezeColors
    
    % Display RESIDUAL wrapped interferogram at 5.6 cm wavelength
    residual_raw = los_raw-modLos_raw';
    ax5=subplot(2,3,3);
    plotInsarWrappedRaw(xy_raw,residual_raw, insar{i}.wavelength, cmap, 'RESIDUAL');
    colormap(ax5,cmap.seismo)
    freezeColors
    
    % Display RESIDUAL unwrapped interferogram
    ax6=subplot(2,3,6);
    plotInsarUnwrappedRaw(xy_raw,residual_raw, cmap, 'RESIDUAL');
    caxis([-c c])
    colormap(ax6,cmap.redToBlue)
    freezeColors
    
    img = getframe(gcf);
%     if saveflag=='y'
%         imwrite(img.cdata,[outputDir,'/','Summary_Figures/',inputFileN,'/',saveName,'/InSAR_Data_Model_Residual_',name_raw,'.png']); %Edited
%         
%         % Add image to html report
%         fprintf(fidHTML, '%s\r\n', '<BR></BR><H3>Comparison Raw InSAR Data - Model - Residual</H3>');
%         filepath = [outputDir,'/','Summary_Figures/',inputFileN,'/',saveName,'/InSAR_Data_Model_Residual_',name_raw,'.png']; %Added
%         fprintf(fidHTML, '<img src="%s" alt="HTML5 Icon">\n', filepath) %Edited
%         
%         save([outputDir,'/Residual/Residual','raw_',name_raw,saveName,'.mat'],'residual_raw','xy_raw'); %Added
%         save([outputDir,'/Model/Model','raw_',name_raw,saveName,'.mat'],'modLos_raw','xy_raw'); %Added
%     end
    
    
    insar_ix = i;
end

