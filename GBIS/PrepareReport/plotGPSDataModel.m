function plotGPSDataModel(gps, geo, invpar, invResults, modelinput, saveName, saveflag)

% Function to generate plot with comparison between GPS data and model
%
% Usage: plotGPSDataModel(gps, geo, invpar, invResults, modelinput, saveName, saveflag)
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

obsGPS = llh2local([gps.ll';zeros(1,length(gps.ll(:,1)))], geo.referencePoint)*1000; % Convert geographic coordinates to local cooridinates
obsGPS = [obsGPS; zeros(1,size(obsGPS,2))]; % Add zeros to third column of observation matrix
nObsGPS = size(obsGPS,2); % Determine number of entries in GPS observation matrix

% Display GPS vectors
obsGPS(:,end+1) = [max(obsGPS(1,:))+5000; min(obsGPS(2,:))-5000; 0]; % add coordinates of legend
scalebar = abs(round(max(gps.displacements(:))/3,3)); % Determine length of scalebar
gps.displacements(:,end+1) = [-scalebar 0 0]; % add "displacements" of legend

%% Generate plot

figure('Position', [1, 1, 1200, 1000]);
quiver(obsGPS(1,:), obsGPS(2,:), gps.displacements(1,:), gps.displacements(2,:), 1, ...
    'Color','k','LineWidth',1,'MaxHeadSize',0.03,'Marker','s')
axis equal; 
ax = gca;
grid on
ax.Layer = 'top';
ax.Box = 'on';
ax.LineWidth = 1.5;
ax.GridLineStyle = '--';
xlabel('X distance from local origin (m)')
ylabel('Y distance from local origin (m)')
title('GPS horizontal displacements (data:black - model:red)')
xlim([min(obsGPS(1,:))-10000 max(obsGPS(1,:))+10000]);
ylim([min(obsGPS(2,:))-10000 max(obsGPS(2,:))+10000]);
text(obsGPS(1,end), obsGPS(2,end)-2000,[num2str(scalebar*1000),' mm']) % Add scakebar
drawnow
hold on

obsGPS(:,end) = []; % remove coordinates of legend
gps.displacements(:,end) = []; % remove displacements for legend

%% Calculate forward model using optimal source parameters

modGPS = forwardGPSModel(obsGPS',invpar,invResults,modelinput); % Calculate modelled displacements

% Plot modelled displacements
quiver(obsGPS(1,:),obsGPS(2,:),modGPS(1,:),modGPS(2,:),1,'Color','r','LineWidth',1,'MaxHeadSize',0.03,'Marker','s')
if saveflag=='y'
    print(gcf,[outputDir,'/Figures/GPS_Data_Model'],'-dpng')
end
drawnow

