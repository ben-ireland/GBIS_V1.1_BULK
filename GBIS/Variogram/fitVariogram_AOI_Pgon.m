function [Sill,Range,Nugget] = fitVariogram_AOI_Pgon(FineBoundingBox,inputFile, wavelength)
%   Modified version of 'fitvariogram' function, modified by Ben Ireland,
%   University of Bristol, April 2023
%
% Function to fit an exponential function to the data isotropic (semi-)variogram
%
% Usage:  fitVariogram(inputFile, wavelength)
%
%   FineBoundingBox:   Fine bounding box polyshape
%
%   inputFile:  path and name of *.mat file containing data in the format used by
%               GBIS
%
%   wavelength: wavelength of InSAR data in meters (e.g., 0.056 m for
%               Sentine-1/Envisat/ERS)
%
%
%
%   Sill, Range, Nugget: Parameters describing noise characteristics of the
%   interferogram data (see Bagnardi and Hooper (2018) for full description)
%
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
close all % To stop it spawning loads of figures
%clc

if ~exist([pwd,'/Variograms'],'dir')
    mkdir(pwd,'Variograms')
    addpath([pwd,'/Variograms'])
end

% Load dataset
disp('Ingesting data to estimate (semi-)variogram ...')
insarData = load(inputFile);

% Create colormap
cmapSeismo = colormap_cpt('GMT_seis.cpt', 100);    % GMT 'Seismo' colormap for wrapped data

% Find a local reference point
refPoint = [min(insarData.Lon), min(insarData.Lat)]; % Determine local reference point

% Convert phase to LOS displacement
convertedPhase = (insarData.Phase / (4*pi)) * wavelength;   % Convert phase from radians to m
los = single(-convertedPhase);                              % Convert to Line-of-sigth displacement in m

% Determine subsampling factor for faster plotting
if length(los) > 400000 && length(los) < 1000000
    sampling = 2;
elseif length(los) > 1000000
    sampling = 5;
else
    sampling = 1;
end

% Plot wrapped dataset
figure
scatter(insarData.Lon(1:sampling:end), insarData.Lat(1:sampling:end), [], mod(los(1:sampling:end), wavelength/2),'.');
colormap(cmapSeismo)
caxis([0 wavelength/2])
hold on
plot(FineBoundingBox)
axis xy
axis equal
title('Wrapped Interferogram')
xlabel('Longitude (degrees)')
ylabel('Latitude (degrees)')
colorbar

%% Identify data outside of Fine Sampling Box

disp('Data outside fine bounding box used')

in = isinterior(FineBoundingBox,insarData.Lon,insarData.Lat);
ixSubset = find(in == 0);

% Extract subset from rectangular area or after masking
subset = los(ixSubset);
llon = insarData.Lon(ixSubset);
llat = insarData.Lat(ixSubset);

% Display subregion from selection
f = figure('Position', [1, 1, 1200, 1000]);
subplot(2,3,1)
scatter(llon(:),llat(:),[],mod(subset(:),wavelength/2),'.')
colormap(cmapSeismo)
caxis([0 wavelength/2])
axis xy
axis equal
axis tight
title('Selected region, NON-DETRENDED')
xlabel('Longitude (degrees)')
ylabel('Latitude (degrees)')
colorbar

%% Remove linear trend from subregion
sll = [llon'; llat']';
xy = llh2local(sll',refPoint);
xy = xy*1000;

A = [xy' ones([length(xy) 1])];

coeff = lscov(A,subset);
deramped = subset - A*coeff;

%% Display trend and subregion after removal of trend
subplot(2,3,2)
scatter(llon(:),llat(:),[],mod(A(:,:)*coeff,wavelength/2),'.')
colormap(cmapSeismo)
caxis([0 wavelength/2])
axis xy
axis equal
axis tight
title('Selected region, ESTIMATED TREND')
xlabel('Longitude (degrees)')
ylabel('Latitude (degrees)')
colorbar

subplot(2,3,3)
scatter(llon(:),llat(:),[],mod(deramped(:),wavelength/2),'.')
colormap(cmapSeismo)
caxis([0 wavelength/2])
axis xy
axis equal
axis tight
title('Selected region, DETRENDED')
xlabel('Longitude (degrees)')
ylabel('Latitude (degrees)')
colorbar

%% Calculate and display variogram before plane removal
subplot(2,3,4)
variog = variogram(xy',double(subset),'plotit',true,'subsample',3000);
title('Semi-variogram, NON-DETRENDED')

% Calculate and display variogram after detrending
variogDtrnd = variogram(xy',double(deramped),'plotit',false,'subsample',3000,'nrbins',30);

%% Fit exponential function to experimental variogram and display
subplot(2,3,5)
[a,c,n] = variogramfit(variogDtrnd.distance,variogDtrnd.val,20000,1e-04,variogDtrnd.num, 'model', 'exponential', 'nugget', 1);
title('Semi-variogram and fit, DETRENDED')

h =subplot(2,3,6);
set(h,'visible','off')
text(0.1,1.0,'Fitted exponential semi-variogram parameters:','FontSize',14)
text(0.1,0.8,['Sill:  ', num2str(c)],'FontSize',14)
text(0.1,0.6,['Range:  ', num2str(a)],'FontSize',14)
text(0.1,0.4,['Nugget:  ', num2str(n)],'FontSize',14)

% Print variogram exponential fit parameters to screen
disp(['Sill:  ',num2str(c)])
disp(['Range:  ',num2str(a)])
disp(['Nugget:  ',num2str(n)])

Sill = c;
Range = a;
Nugget = n;

InputFilename = extractAfter(inputFile,'InputData/');
Filename = [pwd,'/Variograms/',InputFilename(1:end-4),'.png'];
saveas(f,Filename);

