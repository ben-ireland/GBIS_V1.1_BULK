function [xy, residual] =plotInSARDataModelResidual2(insar, geo, invpar, invResults, modelinput, saveName)

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
    loadedData = load(insar{i}.dataPath); % load *.mat file
    
    % Apply bounding box and remove data points outside it
    iOutBox = find(loadedData.Lon<geo.boundingBox(1) | loadedData.Lon>geo.boundingBox(3) | loadedData.Lat>geo.boundingBox(2) | loadedData.Lat<geo.boundingBox(4));
    if sum(iOutBox)>0
        loadedData.Phase(iOutBox) = [];
        loadedData.Lat(iOutBox) = [];
        loadedData.Lon(iOutBox) = [];
        loadedData.Heading(iOutBox) = [];
        loadedData.Inc(iOutBox) = [];
    end
    
    convertedPhase = (loadedData.Phase/(4*pi))*insar{i}.wavelength;    % Convert phase from radians to m
    los = -convertedPhase;  % Convert phase from cm to Line-of-sigth displacement in m
    Heading = loadedData.Heading;
    Inc = loadedData.Inc;
    ll = [single(loadedData.Lon) single(loadedData.Lat)];   % Create Longitude and Latitude matrix
    xy = llh2local(ll', geo.referencePoint);    % Transform from geographic to local coordinates
    
    nPointsThis = size(ll,1);   % Calculate length of current data vector
    xy = double([[1:nPointsThis]',xy'*1000]);   % Add ID number column to xy matrix with local coordinates
    
    % Patch scattered data for faster plotting
    edge = round(min(abs(diff(xy(:,3)))))+2; % Size of patch set to minumum distance between points
    if edge < 50
        edge = 50;
    end
    xs = [xy(:,2)'; xy(:,2)'+edge; xy(:,2)'+edge; xy(:,2)']; % Coordinates of four vertex of patch
    ys = [xy(:,3)'; xy(:,3)'; xy(:,3)'+edge; xy(:,3)'+edge];
    
    % Extract filename to be included in figure name
    [pathstr,name,ext] = fileparts(insar{i}.dataPath);
    
    % Display wrapped DATA interferogram at 5.6 cm wavelength
    figure('Position', [1, 1, 1200, 1000]);
    ax1 = subplot(2,3,1);
    plotInsarWrapped(xy,los, insar{i}.wavelength, cmap, 'DATA');
    colormap(ax1,cmap.seismo)
    freezeColors
    
    % Display DATA unwrapped interferogram
    ax2 = subplot(2,3,4);
    plotInsarUnwrapped(xy,los, cmap, 'DATA');
    c = max(abs([min(los), max(los)])); % Calculate maximum value for symmetric colormap
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
       
    modLos = forwardInsarModel(insar{i},xy,invpar,invResults,modelinput,geo,Heading,Inc,constOffset,xRamp,yRamp); % Modeled InSAR displacements
    
    % Display MODEL wrapped interferogram at 5.6 cm wavelength
    ax3=subplot(2,3,2);
    plotInsarWrapped(xy,modLos',insar{i}.wavelength,  cmap, 'MODEL');
    colormap(ax3,cmap.seismo)
    freezeColors
    
    % Display MODEL unwrapped interferogram
    ax4=subplot(2,3,5);
    plotInsarUnwrapped(xy,modLos', cmap, 'MODEL');
    caxis([-c c])
    colormap(ax4,cmap.redToBlue)
    freezeColors
    
    % Display RESIDUAL wrapped interferogram at 5.6 cm wavelength
    residual = los-modLos';
    ax5=subplot(2,3,3);
    plotInsarWrapped(xy,residual, insar{i}.wavelength, cmap, 'RESIDUAL');
    colormap(ax5,cmap.seismo)
    freezeColors
    
    % Display RESIDUAL unwrapped interferogram
    ax6=subplot(2,3,6);
    plotInsarUnwrapped(xy,residual, cmap, 'RESIDUAL');
    caxis([-c c])
    colormap(ax6,cmap.redToBlue)
    freezeColors
    
    img = getframe(gcf);
%     if saveflag=='y'
%         imwrite(img.cdata,[outputDir,'/','Summary_Figures/',inputFileN,'/',saveName,'/InSAR_Data_Model_Residual_',name,'.png']); %Edited
%         
%         % Add image to html report
%         fprintf(fidHTML, '%s\r\n', '<BR></BR><H3>Comparison InSAR Data - Model - Residual</H3>');
%         filepath = [outputDir,'/','Summary_Figures/',inputFileN,'/',saveName,'/InSAR_Data_Model_Residual_',name,'.png']; %Added
%         fprintf(fidHTML, '<img src="%s" alt="HTML5 Icon">\n', filepath) %Edited
%         
%         save([outputDir,'/Residual/Residual',name,saveName,'.mat'],'residual','xy'); %Added
%         save([outputDir,'/Model/Model',name,saveName,'.mat'],'modLos','xy'); %Added
%     end
    
    
    insar_ix = i;
end

