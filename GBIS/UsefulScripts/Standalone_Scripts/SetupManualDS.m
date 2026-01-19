close all; clear all;
%Files = dir('/scratch/Ben/Fentale/Fentale*.mat'); % These are already in GBIS format i.e. n x 1 vectors of Phase, Lat, Lon, Inc, and Heading (Masked phase values set to zero)
%Files = dir('/scratch/Ben/Fentale/CorrectedTS.mat'); % These are original timeseries e.g. n x m x l datacubes, (Masked values set to NaN)

% Define name and wavelength
m2rad= (4.*pi)./0.031;
rad2m= 0.031./(4.*pi);
VolcName = {'Fentale_CSK_Asc','Fentale_CSK_Dsc'};

% Load timeseries and geometry files
load('/scratch/Ben/Fentale/CorrectedTS.mat')
LastStepAsc = squeeze(Timeseries_ASC(:,:,end));
LastStepDsc = squeeze(Timeseries_DSC(:,:,end));
%LastStepAsc = flipud(LastStepAsc);
%LastStepDsc = flipud(LastStepDsc);

load '/scratch/Ben/Fentale/Fentale_ASC.mat';
headAsc = Heading(1);
incAsc = Inc(1);

load '/scratch/Ben/Fentale/Fentale_DSC.mat';
headDsc = Heading(1);
incDsc = Inc(1);

% Conver from cm to rad
PhaseAsc = -(LastStepAsc./100).*m2rad;
PhaseDsc = -(LastStepDsc./100).*m2rad;

% Crop to smaller AOI
LatMax = 9.000;
LatMin = 8.972;
LonMax = 39.923;
LonMin = 39.890;

LatKeepAsc = Lat_ASC>LatMin & Lat_ASC<LatMax;
LonKeepAsc = Lon_ASC>LonMin & Lon_ASC<LonMax;
LatKeepDsc = Lat_DSC>LatMin & Lat_DSC<LatMax;
LonKeepDsc = Lon_DSC>LonMin & Lon_DSC<LonMax;

Lat_ASC = Lat_ASC(LatKeepAsc);
Lon_ASC = Lon_ASC(LonKeepAsc);
Lat_DSC = Lat_DSC(LatKeepDsc);
Lon_DSC = Lon_DSC(LonKeepDsc);
PhaseAsc = PhaseAsc(LatKeepAsc,LonKeepAsc);
PhaseDsc = PhaseDsc(LatKeepDsc,LonKeepDsc);

% Make square (needed for downsampling script)
[Lon_ASC,Lat_ASC,PhaseAsc] = MakeSquare(Lon_ASC,Lat_ASC,PhaseAsc);
[Lon_DSC,Lat_DSC,PhaseDsc] = MakeSquare(Lon_DSC,Lat_DSC,PhaseDsc);

% Create arrays of Lat and Lon
[LonAsc, LatAsc] = meshgrid(Lon_ASC,Lat_ASC);
[LonDsc, LatDsc] = meshgrid(Lon_DSC,Lat_DSC);

% Options for downsampling script
Options.SS_Factor = 30; % Coarse downsampling factor i.e. anywhere outside the AOI is averaged over every x by x pixels
Options.SS_FactorF = 10; % Fine downsampling factor i.e. anywhere inside the AOI is averaged over every x by x pixels
Options.NaN_Thresh_DS = 0.5; % Proportion of NaN values in an x by x averaged block above which the downsampled pixel is given a NaN value
Options.Adjust_SS_Factor = 1; % Automatically adjust the SS_Factors based on the number of pixels if they are outside the ranges below
Options.SS_RunLimit = 20; % Limit of number of times SS_Factor can be adjusted before taking the result (if Options.Adjust_SS_Factor == 1)
Options.Min_nPix = 1000; % Minimum number of pixels for a downsampled imaged (if Options.Adjust_SS_Factor == 1)
Options.Max_nPix = 2000; % Maximum number of pixels for a downsampled imaged (if Options.Adjust_SS_Factor == 1)
Options.Max_SS_Factor = 60; % Maximum subsampling factor in far-field
Options.Max_SS_FactorF = 15; % Maximum subsampling factor in near-field
Options.MinPropFF = 0.2; % Minimum proportion of subsampled far-field points relative to near-field points
Options.MaxPropFF = 0.3; % Maximum proportion of subsampled far-field points relative to near-field points
Options.WavelengthM = 0.031; % InSAR wavelength in m
Options.MaskVolcs = 0; % Not needed here but mentioned in downsampling script
Options.ICA = 0; % Not needed here but mentioned in downsampling script
Options.RunID = 'Test'; % Not needed here but mentioned in downsampling script
Options.PreProcOffset = 0; % Optionally remove mean from far-field area as an offset to minimise background phase from reference pixel choice

% Options for variogram
Options.VariogramAttempts = 5; % Number of variogram attempts to average over

% Options for manual AOI definition
MANUAL_Options.Manual_Suffix = '_Caldera';
MANUAL_Options.AOIFmt = 'shp';

% Process AOI shapefile
MANUAL_AOI{1} = Manual_AOI(VolcName{1},LatAsc,LonAsc,MANUAL_Options);
MANUAL_AOI{2} = Manual_AOI(VolcName{2},LatDsc,LonDsc,MANUAL_Options);

[~, Filename{1}, Filename_Raw{1}, ~, ~, FineBoundingBox, ~, ~] = Standalone_Nested_Uniform_DS(PhaseAsc,LonAsc,LatAsc,MANUAL_AOI{1},headAsc,incAsc,VolcName{1},Options);
[~, Filename{2}, Filename_Raw{2}, ~, ~, FineBoundingBox2, ~, ~] = Standalone_Nested_Uniform_DS(PhaseDsc,LonDsc,LatDsc,MANUAL_AOI{2},headDsc,incDsc,VolcName{2},Options);

% Calculate Variogram parameters
M = Options.VariogramAttempts; % Large enough to get a representative mean
Sill = zeros(M,1);
Range = zeros(M,1);
Nugget = zeros(M,1);

FineBoundingBoxLLAsc = convertFineBBcoords(FineBoundingBox,Filename_Raw{1});
FineBoundingBoxLLDsc = convertFineBBcoords(FineBoundingBox2,Filename_Raw{2});

% Clear variables for memory
clearvars -except FineBoundingBoxLLAsc FineBoundingBoxLLDsc Filename_Raw Options M
for i = 1:M
    [Sill(i), Range(i), Nugget(i)] = fitVariogram_AOI_Pgon(FineBoundingBoxLLAsc,Filename_Raw{1}, Options.WavelengthM);
end

SillAsc = median(Sill);
RangeAsc = median(Range);
NuggetAsc = median(Nugget);

% Clear variables for memory
clearvars -except FineBoundingBoxLLAsc FineBoundingBoxLLDsc Filename_Raw Options M
for i = 1:M
    [Sill(i), Range(i), Nugget(i)] = fitVariogram_AOI_Pgon(FineBoundingBoxLLDsc,Filename_Raw{2}, Options.WavelengthM);
end

SillDsc = median(Sill);
RangeDsc = median(Range);
NuggetDsc = median(Nugget);