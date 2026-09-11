close all; clear variables;
%Files = dir('/scratch/Ben/Fentale/Fentale*.mat'); % These are already in GBIS format i.e. n x 1 vectors of Phase, Lat, Lon, Inc, and Heading (Masked phase values set to zero)
%Files = dir('/scratch/Ben/Fentale/CorrectedTS.mat'); % These are original timeseries e.g. n x m x l datacubes, (Masked values set to NaN)

% Define name and wavelength
Wavelength_m = 0.0566; % SAR Wavelength in m
m2rad= (4.*pi)./Wavelength_m;
rad2m= Wavelength_m./(4.*pi);
VolcName = {'2015_fentale_dsc'};

% Options for manual AOI definition
MANUAL_Options.Manual_Suffix = '_dyke'; % Check underscore against shapefile name.
MANUAL_Options.AOIFmt = 'shp';

%load('/local-scratch/Ben/GBIS_Sept26/EAR_Manual_Pedro_LiCS/Fentale/087A/LiCS_TS_mat/2015_fentale_087A_08102_131312.mat');
load('/local-scratch/Ben/GBIS_Sept26/EAR_Manual_Pedro_LiCS/Fentale/079D/LiCS_TS_mat/2015_fentale_079D_08094_131313.mat');
%load('/scratch/Ben/Dabbahu_Dyke_2026/LiCS_TS_mat/2026_Dabbahu_079D_07694_131313.mat');
%load('/scratch/Ben/Dabbahu_Dyke_2026/LiCS_TS_mat/2026_Dabbahu_014A_07688_131313.mat');
%load('/scratch/Ben/Suswa_Longonot_Connectivity/LiCS_TS_mat/Longonot_130A_09032_111110_V2.mat');
%load('/scratch/Ben/Suswa_Longonot_Connectivity/LiCS_TS_mat/Longonot_152D_09114_131313_V2.mat');
%load("/scratch/Ben/Suswa_Longonot_Connectivity/Envisat_IFG/Envisat_20040628_20060529_Longonot.mat")
%load("/scratch/Ben/Suswa_Longonot_Connectivity/LiCS_TS_mat/Suswa_EP1_130A_09212_131313_V2.mat")
%load("/scratch/Ben/Suswa_Longonot_Connectivity/LiCS_TS_mat/Suswa_EP2_130A_09212_131313_V2.mat")
%load("/scratch/Ben/Suswa_Longonot_Connectivity/LiCS_TS_mat/Suswa_EP1_152D_09114_131313_V2.mat")
%load("/scratch/Ben/Suswa_Longonot_Connectivity/LiCS_TS_mat/Suswa_EP2_152D_09114_131313_V2.mat")
head = Heading(1);
inc = Inc(1);

% Options for downsampling script
Options.SS_Factor = 20; % Coarse downsampling factor i.e. anywhere outside the AOI is averaged over every x by x pixels
Options.SS_FactorF = 8; % Fine downsampling factor i.e. anywhere inside the AOI is averaged over every x by x pixels
Options.NaN_Thresh_DS = 0.1; % Proportion of valid (non-NaN) values in an x by x averaged block below which the downsampled pixel is given a NaN value
Options.Adjust_SS_Factor = 0; % Automatically adjust the SS_Factors based on the number of pixels if they are outside the ranges below
Options.SS_RunLimit = 20; % Limit of number of times SS_Factor can be adjusted before taking the result (if Options.Adjust_SS_Factor == 1)
Options.Min_nPix = 1000; % Minimum number of pixels for a downsampled imaged (if Options.Adjust_SS_Factor == 1)
Options.Max_nPix = 3000; % Maximum number of pixels for a downsampled imaged (if Options.Adjust_SS_Factor == 1)
Options.Max_SS_Factor = 7; % Maximum subsampling factor in far-field
Options.Max_SS_FactorF = 3; % Maximum subsampling factor in near-field
Options.MinPropFF = 0.1; % Minimum proportion of subsampled far-field points relative to near-field points
Options.MaxPropFF = 0.3; % Maximum proportion of subsampled far-field points relative to near-field points
Options.WavelengthM = Wavelength_m; % InSAR wavelength in m
Options.MaskVolcs = 0; % Not needed here but mentioned in downsampling script
Options.ICA = 0; % Not needed here but mentioned in downsampling script
Options.RunID = 'Test'; % Not needed here but mentioned in downsampling script
Options.PreProcOffset = 0; % Optionally remove mean from far-field area as an offset to minimise background phase from reference pixel choice

% Options for variogram
Options.VariogramAttempts = 5; % Number of variogram attempts to average over

% Process AOI shapefile
MANUAL_AOI{1} = Manual_AOI(VolcName{1},Lat,Lon,MANUAL_Options);

[~, Filename{1}, Filename_Raw{1}, ~, ~, FineBoundingBox, ~, ~] = Standalone_Nested_Uniform_DS(Phase,Lon,Lat,MANUAL_AOI{1},head,inc,VolcName{1},Options);
keyboard

% Calculate Variogram parameters
M = Options.VariogramAttempts; % Large enough to get a representative mean
Sill = zeros(M,1);
Range = zeros(M,1);
Nugget = zeros(M,1);

FineBoundingBoxLL = convertFineBBcoords(FineBoundingBox,Filename_Raw{1});

% Clear variables for memory
clearvars -except FineBoundingBoxLL Filename_Raw Options M
for i = 1:M
    [Sill(i), Range(i), Nugget(i)] = fitVariogram_AOI_Pgon(FineBoundingBoxLL,Filename_Raw{1}, Options.WavelengthM);
end

Sill = median(Sill);
Range = median(Range);
Nugget = median(Nugget);
disp("")
disp('Average values:')
disp(['Sill: ',num2str(Sill)])
disp(['Range: ',num2str(Range)])
disp(['Nugget: ',num2str(Nugget)])

close all