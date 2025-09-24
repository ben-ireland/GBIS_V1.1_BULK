% Ben Ireland, University of Bristol
% CHANGE LOG
% 10/2024 - Minimum working release on GitHub.
% 11/2024 - General improvements including functionality of
%           inputting of manual data and saving/loading runs
%           and other options.
% 12/2024 - Addition of new method to define fine bounding box
%           in Step 6 if Otsu-based method is not working
% 02/2025 - Additional source geometries from Cervelli (2013) and
%           Sun (1969) added as options
% 04/2025 - Overhaul of Otsu thresholding and ICA Steps (3/4)
% 05/2025 - Added constraints for number of far-field points in Step 6
%           (Nested uniform downsampling)
% 06/2025 - Added in compound dislocation model (CDM) as geometry option
%           and fixed various bugs in report generation
% 07/2025 - Added options to specify ramp and constant offset bounds,
%           option to automatically mask data based on DEM or buffers, and
%           fixed semi-variogram generation bug
% 08/2025 - Added options for a 'seeding' run to better constrain apriori
%           model bounds
% 09/2025 - Added option for automatic McTigue (1987) spherical source and
%           additional CDM constraints

%%%%%%%%%%%%%%%% Processing Steps %%%%%%%%%%%%%%%%%%%%
% This can be run in an automated sense all the way
% through by setting start and end steps in the options
% structure below. To run individual steps, fill in the
% input parameters below the 'Optional steps' section.
%
% When running all the way through, steps 1-3 are
% recommended, but can be skipped using the options below
%
% It is recommended to start at step 1 and go through all
% of the steps
%
% Deformation catalogues and PDF reports can only be
% generated if you run through ALL the steps.
%
% For automated procedures e.g. Steps 2-6, there are options
% to MANUALLY add in a signal location (bounding box and zone
% of peak deformation). Look for the 'MANUAL' options below.
%
%     Required steps:
% 0 - Load and format InSAR timeseries data for further
%     processing. (.nc or .h5 format). 
%     To add compatability for other data types, edit the Step0 function.
%     
%     Optional steps:
% 1 - Mask data around other volcanoes in the frame.
% 2 - Locate signal using sliding window approach.
% 3 - Apply ICA to the data for denoising.
% 4 - Use Otsu's thresholding to extract a bounding box
%     to use for nested uniform downsampling.
% 5 - Fit functions to the InSAR timeseries and compare
%     for best fit (Albino et al. 2022)
% 6 - Downsample using nested uniform downsampling.
% 7 - Modify GBIS input file based on results of previous
%     steps.
% 8 - Run GBIS for a Mogi and/or Penny or other source.
% 9 - Prepare PDF reports and tables for GBIS results
%     (for individual runs).
% 10- For a bulk run, create a .csv deformation 
%     catalogue of spatial, temporal and analytical
%     model parameters describing the signal.
%     (Only works if starting from Step 0)
%
%     Additional useful scripts:
%     RedoResults.m - re-run steps 9 and 10 from a GBIS run
%
%     ReeoResultsMulti.m - same as above but for multiple sources (e.g. Mogi + Dyke)
%
%     PlotDMR_UNW_Wrapped.m - Create nicer Data-Model-Residual plots
%
%     DecompEWUD.m - Decompose Asc and Dsc into EW-UD motion and compare
%                    to GBIS model.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear all; close all

%%%%%%%%%%%%%%%% INPUT YOUR DATA HERE %%%%%%%%%%%%%%%
%% Add input files and bulk InSAR data
input_Filename = 'Generic_Input_File'; % Without .inp extension

% Timeseries filepath - should be in .nc (m) or .h5 LiCS (mm) format
% Bulk Asc and Dsc doesn't yet work for h5 examples
%TS_Files = dir([pwd,'/SampleData','/**/timeseries/*.nc']); % .nc example (comment out as necessary)
%TS_Files = dir([pwd,'/SampleData','/**/TS_GEOCml1*/cum_filt.h5']); % .h5 example
TS_Files = dir(['/scratch/Ben/EAR_Data/**/timeseries/*.nc']);
%TS_Files = TS_Files([10])

%%%%%%%%%%%%%%% Saving and loading runs %%%%%%%%%%%%%%
SaveOptions =1; % Save parameters (optional)
LoadOptions =0; % Load previous set of parameters (optional)
SaveProgress =1; % Save progress (can be used if testing a few steps at once)
LoadProgress =0; % Load progress from a previous run and start from a step other than 1
LoadFilename = 'Path/to/saved/progress'; % Saved .mat progress file to load
                                        

%%%%%%%%%%%%%%%% General Parameters %%%%%%%%%%%%%%%%%%
%% General parameters of the datasets
Options.SpatialRes = 100; % Approximate spatial resolution of the input InSAR data in m
Options.WavelengthM = 0.056; % Wavelength of the SAR sensor in m e.g. 0.056 m for Sentinel-1

%Options.RunID = 'CDMsTest_WithLast'; % Unique identifier for the given run (e.g. VOLCANO_NAME_TEST)
%Options.RunID = 'CDMsTest_FentaleLastOffsetV4';
Options.RunID = 'DepthEstTest';
Options.BulkRunID = '2708'; % Unique identifier for summary figures or tables of all runs (e.g. SOURCE_NAME_TEST_0101)

%%%%%%%%%%%%%%% Optional Parameters %%%%%%%%%%%%%%%%%%%
%% Options
Options.StartStep = 0; % Which step to start on
Options.EndStep = 7; % Which step to stop on

% Options if running automatically
Options.SkipGBIS = 0; % Optionally skip the modelling step (1) (useful for development/pre-processing work)
Options.SkipFlagged = 0; % Optionally skip badly pre-processed examples (1) or attempt to model them anyway (0)

%% Options for MANUAL alternative to automatic pre-processing steps
%   For manual options to the input parameters, copy and change parameters in "Generic_Input_File.inp", and change
%   the filepath to the input file in section "Add input files and bulk InSAR data" below.
%   
%   Note: Manual Mask maps, AOIs, or peak deformation locations should be provided as either Shapefiles in the same CRS
%   as the raw InSAR data, or n by m binary arrays in .mat format, where n by m is the size of the InSAR data
%
%   Note: Before using manual functions, please set up a 'Manual_Inputs' folder with subfolders 'AOI','Mask', and 'Location'
%   for using a manual signal location, manual signal footprint, and any additional masks for data to remove from the image

MANUAL_Options.Manual_Suffix = '_Test'; % Unique suffix for all manual input filenames relating to a single manual run (see file structure)
MANUAL_Options.MaskData = 0; % Manually mask regions of the image (1) (Aside from or along with masking out nearby volcanoes) or not (0)
MANUAL_Options.MaskDataFmt = 'shp'; % Data format ('shp' - shapefile; 'mat' - Matlab file)
MANUAL_Options.RegionShrink = 0; % Optionally apply region shrinking to the input data manually with a disk element (parameters below) (1==yes; 0==no)
MANUAL_Options.RegionShrinkMinPts = 0; % Minimum size of region (in pixels) that region shrinking is applied to
MANUAL_Options.RS_DiskSize = 0; % Distance to shrink region by (in pixels)
MANUAL_Options.AOI = 0; % Alternative for Step 2 and Step 4 (1==yes; 0==no)
MANUAL_Options.AOIFmt = 'shp'; % Data format ('shp' - shapefile; 'mat' - Matlab file)
if MANUAL_Options.AOI == 1
    MANUAL_Options.Location = 1; % Alternative for Step 2, Step 4 and Step 5 - need to also have MANUAL_Options.AOI == 1 to use
elseif MANUAL_Options.AOI ==0
    MANUAL_Options.Location = 0;
end
MANUAL_Options.LocationFmt = 'shp'; % Data format ('shp' - shapefile; 'mat' - Matlab file)
MANUAL_Options.ICA = 0; % Alternative for Step 3 - do ICA with manually inputs (below) (1==yes; 0==no)
if MANUAL_Options.ICA == 1 
    MANUAL_Options.ICA_nComp = 6; % Number of components
    MANUAL_Options.ICA_White = 1; % Optionally whiten input data (RECOMMENDED) (1==yes; 0==no)
    MANUAL_Options.ICA_AllComps = 'no'; % Take all IC components for reconstructed data
    if strcmp(MANUAL_Options.ICA_AllComps,'no')
        MANUAL_Options.ICA_ChosenComps = [1,2,4]; % Take selected IC components for reconstructed data
    end
end

%% Initial formatting of variables (Step 0) - REQUIRED
Options.Auto_Angles = 1; % Automatically retrieve head and inc angles from LiCSAR (requires LiCS frames) - otherwise provide them manually in cmd line (1==yes; 0==no)
Options.CropTS = 0; % Crop timeseries? (1==yes; 0==no)
Options.CropTS_startAll = [3 2]; % Start timestep to crop timeseries (if Options.CropTS ==1)
Options.CropTS_endAll = [29 32]; % End timestep to crop timeseries (if Options.CropTS ==1)
Options.CropImg = 0; % Spatially crop image? (1==yes; 0==no)
Options.CropImgX = 1:500; % X range to crop image (if Options.CropImg ==1)
Options.CropImgY = 1:500; % Y range to crop image (if Options.CropImg ==1)
Options.IgnoreLastStep = 0; % Optionally remove first and last timeseries step (can reduce noise in some cases) (1==yes; 0==no) (if Options.AutoTimestep ==0)
Options.AutoTimestep = 1; % Optionally choose between the last and second-last step of the timeseries, choosing the one with lowest stdev (1==yes; 0==no)

%% Data pre-processing (Steps 1-3)
% Mask Data around nearby GVP volcanoes (step 1)
Options.MaskVolcs = 1; % 1=Mask x km radius around all other volcanoes in the ifg that aren't the target. 0= don't mask
Options.Mask_BufferDist = 60; % Radius to mask around volcanoes in pixels (distance = n.pixels * spatial resolution) - distance is approximate

% Locate signal using sliding window approach (step 2)
Options.SlidingWindow = 1; % Use Sliding window approach to find signal location (recommended) - used in ICA, Otsu, and temporal parameters procedures (1==yes; 0==no)
Options.SW_WindowSizes = 2:25; % Range of window sizes to compare
Options.SW_CropEdges = 1; % Crop outer X% of the images? (1==yes; 0==no)
Options.SW_CropEdges_Mag = 0.2; % Portion of the image edge to crop (if Options.SW_CropEdges==1)
Options.SW_RegionShrink = 1; % Apply region shrinking to remove edges of NaN areas (poor unwrapping) (1==yes; 0==no)
Options.SW_RegionShrink_MinPts = 500; % Minimum size of region (in pixels) that region shrinking is applied to (if Options.SW_RegionShrink ==1)
Options.SW_RegionShrink_DiskSize = 3; % Distance to shrink region by (in pixels) (if Options.SW_RegionShrink ==1)
Options.SW_NaN_Thresh = 0.95; % Minimum proportion of non-Nan pixels in a sliding window region for mean value to be retained
Options.SW_DBSCAN_Eps = 50; % Epsilon parameter for DBSCAN
Options.SW_DBSCAN_MinPts = 7; % MinPts parameter for DBSCAN
Options.SW_MinBBSize = 20; % Minimum size of initial signal location region i.e. x by x pixel square

% Apply ICA to the data for denoising (step 3)
Options.ICA = 1; % 1=Use ICA to de-noise timeseries prior to Otsu; 0=Don't use ICA (use original data)
Options.ICA_nCompRange = [5 5 5 10 10 10 20 20 20];
%Options.ICA_nCompRange = [5 5 5 10 10 10 20 20 20]; % Range of ICs to run ICA with (repeats can be used to account for impacts of random start position)
Options.ICA_ClosenessThresh = 0.95; % What proportion of the signal can be considered noise and removed by ICA e.g. 0.95 means 5% of the signal magnitude can be discarded as noise
                                    % This also checks to make sure that the reconstructed signal cannot be any stronger than 1 + (1-Options.ICA_ClosenessThresh) e.g. 1.05 for threshold of 0.95

%% Signal bounding box extraction with Otsu (Steps 4)
% Use Otsu thresholding to extract an approximate signal bounding box (step 4)
Options.Otsu_NumLevels = 5; % Number of levels of Otsu thresholding to test (number of segments = numlevels + 1)
Options.Otsu_BB_Shape = 2; % Make Otsu region rectangular (1) or the shape of the region (2, recommended)
Options.Otsu_RegionShrinkCohThresh = 0.25; % Don't perform region shrinking if non-zero/NaN pixels make up less than X proportion of the image
Options.Otsu_RegionShrink_MinPts = 500; % Minimum size of region (in pixels) that region shrinking is applied to
Options.Otsu_RegionShrink_DiskSize = 3; % Distance to shrink region by (in pixels)
Options.Otsu_MinClassSize = 200; % Minimum size (in pixels) of an Otsu class to be retained
Options.Otsu_MaxOverlap = 0.8; % Minimum overlap of the signal location from Step 2 (Location.Limits) needed for a Otsu class to be retained
Options.Otsu_MinConCompSize = 50; % Minimum size (in pixels) of connected component region in the chosen class to be retained
Options.Otsu_RegionConnectivity = 8; % Region connectivity criteria (4= connected by edges), (8= connected by edges or corners)
Options.Otsu_SizeLimit = 0.75; % What proportion of the whole image the Otsu region (FineBoundingBox) can contain
Options.Otsu_MaxMaskArea = 5000; % Threshold max region area (in pixels) below which buffering is applied
Options.Otsu_Buffer_Large = 1; % Number of pixels to buffer large Otsu regions (bigger than Options.Otsu_MaxMaskArea pixels)

%% Temporal parameter extraction (Step 5)
% Fit functions to the timeseries (step 5)
Options.Temp_R2_Thresh = 0.5; % R2 threshold for function fits above which the function can be considered

%% Data Downsampling (Step 6)
% Downsampled the data using a nested uniform approach based on bounding boxes 
% and prepare in GBIS format (step 6)
Options.SS_Factor = 20; % Coarse downsampling factor i.e. anywhere outside the AOI is averaged over every x by x pixels
Options.SS_FactorF = 4; % Fine downsampling factor i.e. anywhere inside the AOI is averaged over every x by x pixels
Options.NaN_Thresh_DS = 0.5; % Proportion of NaN values in an x by x averaged block above which the downsampled pixel is given a NaN value
Options.Adjust_SS_Factor = 1; % Automatically adjust the SS_Factors based on the number of pixels if they are outside the ranges below
Options.SS_RunLimit = 20; % Limit of number of times SS_Factor can be adjusted before taking the result (if Options.Adjust_SS_Factor == 1)
Options.Min_nPix = 1000; % Minimum number of pixels for a downsampled imaged (if Options.Adjust_SS_Factor == 1)
Options.Max_nPix = 3000; % Maximum number of pixels for a downsampled imaged (if Options.Adjust_SS_Factor == 1)
Options.Max_SS_Factor = 30; % Maximum subsampling factor in far-field
Options.Max_SS_FactorF = 10; % Maximum subsampling factor in near-field
Options.MinPropFF = 0.1; % Minimum proportion of subsampled far-field points relative to near-field points
Options.MaxPropFF = 0.3; % Maximum proportion of subsampled far-field points relative to near-field points
Options.FarFieldMask = 1; % Optionally mask far-field pixels (1 == yes; 0 ==no)
Options.FarFieldUnmaskedVar = 1; % Use unmasked far-field image for semi-variogram generation rather than masked far-field (1 == yes; 0 ==no) (If Options.FarFieldMask == 1 AND Options.Variogram == 1)
Options.FarFieldMaskMethod = 1; % Mask far-field pixels based on 1. Areas where DEM is +/- N std away from near-field mean OR 2. Additional buffer of near-field region (if Options.FarFieldMask == 1) OR 3. combine both methods
Options.FarFieldDEM_StdLimit = 1.5; % N of std away from near-field mean elevation to mask data (if Options.FarFieldMaskMethod == 1 OR 3)
Options.FarFieldAdditionalBuffer = 15; % Percentage of original image size to keep outside of near-field region (if Options.FarFieldMaskMethod == 2 OR 3)
Options.PreProcOffset = 1; % Minimise far-field signal by removing offset during preprocessing? (1==on, 0==off)

%% Modelling setup and outputs (Step 7-9)
% Setup input files (step 7)
Options.EstimateDepthBounds =1; % Optionally estimate depth bounds based on size of Otsu region and Mogi equation (depth vs signal size) (1==yes, 0==no)
Options.DepthEstimateA = 0.05; % Estimate of percentage of displacement at the edge of the near-field bounding box (if Options.EstimateDepthBounds==1) (Higher = deeper depth constraints)
Options.Offset = 1; % Invert for constant offset in GBIS? (1==yes, 0==no)
Options.OffsetStep = 1e-4; % Step, lower and upper bounds for constant offset (if Options.Offset ==1)
Options.OffsetLower = -1e-1;
Options.OffsetUpper = 1e-1;
Options.Ramp = 0; % Invert for a linear ramp to the data in GBIS? (1==yes, 0==no)
Options.RampStep = 1e-7; % Step, lower and upper bounds for linear ramp (if Options.Ramp ==1)
Options.RampLower = -2e-6; % Maximum displacement from ramp = Options.RampUpper * max local X/Y coordinate (in m)
Options.RampUpper = 2e-6; % E.g. +/- 2e-6 m at 50 km grid = ramp with +/-0.1 m across the whole image
Options.Variogram = 1; % Specify if to calculate noise parmaeters from semi-variogram; 0 = default values, 1 = use variogram, other = use hard-coded values in input file
Options.VariogramAttempts = 20; % (if Options.Variogram==1) Number of variogram runs to use (range, sill and nugget values taken as averages of these runs)
Options.Bounds = 1; % Modify bounds or not
Options.BoundLimits =1; % Modify location bounds (XY) based on 1. Geometry of the fine bounding box, or 2. Geometry of the image i.e. explore the full image
Options.Change_Wavelength = 0; % Modify wavelength or not (default: 0.056 m)

% Source geometry options
Options.SourceType = 1; % default initial source types - 1=Mogi 2=Penny-shaped crack - other sources, see below (change in Step8_RunBulkInversion script)
Options.PennyComparison = 0; % Do a comparison with a Penny source (3 geometry options) and compare with other sources
Options.SillComparison = 0; % Do a comparison with a Sill source (Okada, 1985) and compare with other sources
Options.YangComparison = 0; % Do a comparison with a Yang source (3 geometry options) and compare with other sources
Options.DykeComparison = 0; % Do a comparison with a Dyke source (Okada, 1985) and compare with other sources
Options.CDMComparison = 1; % Do a comparison compound dislocation model (CDM) source Nikkhoo (2017) (Various sub-geometries - see Options.CDMGeometry)
Options.PennyType = 3; % Use Fialko (1), Sun Penny-shaped crack solution using pressure (2), or Sun Penny-shaped crack solution using volume (3)
Options.YangType = 2; % Yang Type (1= Yang1988; 2=Cervelli 2013 spheroid (volume); 3=Cervelli 2013 spheroid (pressure))
Options.CDMGeometry = [1,2,4,5,6,7,8]; % Constrain CDM to particular geometry or geometries (see below) - single number for one geometry, multiple for more than 1 geometry e.g. [1,3,6]:
% 1 = CDM with full freedom (all params)
% 2 = simple axisymmetic sphere (x,y,z,r,dV)
% 3 = axisymettric sphere (with trend/plunge) (x,y,z,r,tr,pl,dV)
% 4 = sill (symmetric axes) (horizontally extensive) (x,y,z,a,dV)
% 5 = sill (non-symmetric axes) (x,y,z,r,a,b,dV)
% 6 = dyke-like (vertically extensive) (x,y,z,l,w,str,dV)
% 7 = prolate spheroid (x,y,z,a,ar,tr,pl,dV)
% 8 = oblate spheroid (x,y,z,a,ar,tr,pl,dV)
Options.OtherSource = 0; % Optionally try to model with another source other than Penny or Mogi (0== No, 1== Yes)
Options.OtherSourceType = 'D'; % Additional source type if Options.OtherSource == 1 (You can add multiple sources e.g. 'MD' but bounds have to be set manually)

%   Mogi model bounds 
%   4 km based on median depth from Ebmeier et al. (2018); 7e06 m^3 volume based on rounded injection volume (Delaney, 1994) from median depth (4 km) and displacements (~10 cm) of intrusions (Biggs and Pritchard, 2017)
%   Lower depth and volume based on rounded 1st percentile of depth Ebmeier et al. (2018) (0.5 km) and volume of a 4 km point source producing the 90th percentile displacement (~95 cm; 10^8 m3) of Biggs and Pritchard, 2017.
%   Upper depth and volume based on rounded 90th percentile of depth Ebmeier et al. (2018) (10 km) and volume of a 4 km point source producing the 90th percentile displacement (~95 cm; 10^8 m3) of Biggs and Pritchard, 2017.
Options.MogiStartDepth = 4000; 
Options.MogiMinDepth = 500;
Options.MogiMaxDepth = 10000;
Options.MogiStartVol = 7e06;
Options.MogiMinVol = -1.5e08;
Options.MogiMaxVol = 1.5e08;
%   Penny model bounds 
%   (z location based on previous catalogues (see Mogi description), Radius bounds of 4000/500/10000 based on East African Rift System (Biggs et al. 2009; 2011))
Options.PennyStartRadius = 5000;
Options.PennyMinRadius = 500;
Options.PennyMaxRadius = 10000;
Options.PennyStartDepth = 4000;
Options.PennyMinDepth = 500;
Options.PennyMaxDepth = 10000;
Options.PennyStartDPMu = 1e-4;
Options.PennyMinDPMu = -1e03;
Options.PennyMaxDPMu = 1e03;

%   Okada Sill Model bounds
%   Length/Width/Opening based on global ranges and Penny bounds from East African Rift System (Biggs et al. 2009; 2011); Depth based on previous catalogues (see Mogi description)
%   Strike left completely open
Options.SillStartLength = 5000;
Options.SillMinLength = 500;
Options.SillMaxLength = 20000;
Options.SillStartWidth = 5000;
Options.SillMinWidth = 500;
Options.SillMaxWidth = 20000;
Options.SillStartDepth = 4000;
Options.SillMinDepth = 500;
Options.SillMaxDepth = 10000;
Options.SillStartStrike = 180;
Options.SillMinStrike = 0;
Options.SillMaxStrike = 360;
Options.SillStartOpening = 0.01;
Options.SillMinOpening = -5;
Options.SillMaxOpening = 5;

%   Yang Sill Model bounds
%   Depth based on previous catalogues (see Mogi description)
%   Strike left completely open
Options.YangStartZ = 4000;
Options.YangMinZ = 500;
Options.YangMaxZ = 10000;
Options.YangStarta = 5000;
Options.YangMina = 500;
Options.YangMaxa = 10000;
Options.YangStartb = 5000;
Options.YangMinb = 500;
Options.YangMaxb = 10000;
Options.YangStartab = 0.5;
Options.YangMinab = 0.2;
Options.YangMaxab = 10;
Options.YangStartTrend = 90;
Options.YangMinTrend = 0;
Options.YangMaxTrend = 180;
Options.YangStartPlunge = 0;
Options.YangMinPlunge = 0;
Options.YangMaxPlunge = 0;
Options.YangStartDpMu = 1e-4;
Options.YangMinDpMu = -1e3; % If YangType ==1 or 3
Options.YangMaxDpMu = 1e3; 
Options.YangStartVolume = 1e06; % If YangType ==2
Options.YangMinVolume = -1e07;
Options.YangMaxVolume = 1e07;

% Okada dyke (Okada, 1985) model bounds
% Derived from sill bounds and global ranges (see sill constraints for more details)
Options.DykeStartLength = 5000;
Options.DykeMinLength = 500;
Options.DykeMaxLength = 20000;
Options.DykeStartWidth = 5000;
Options.DykeMinWidth = 500;
Options.DykeMaxWidth = 20000;
Options.DykeStartDepth = 4000; % Bottom depth of dyke (Top depth if dip is -ive)
Options.DykeMinDepth = 500;
Options.DykeMaxDepth = 10000;
Options.DykeStartDip = 90;
Options.DykeMinDip = 90;
Options.DykeMaxDip = 90;
Options.DykeStartStrike = 180;
Options.DykeMinStrike = 0;
Options.DykeMaxStrike = 360;
Options.DykeStartOpening = 0.1;
Options.DykeMinOpening = 0;
Options.DykeMaxOpening = 5;

%   CDM (Nikkhoo 2017) model bounds
%   X and Y bounds are defined in Step 6 and 7
%   Model constraints come from those from sill and point sources above

if Options.CDMComparison==1
    if ismember(1,Options.CDMGeometry) % Fully Open
        Options.CDMStartZ = 5000;
        Options.CDMStartOmegX = 45;
        Options.CDMStartOmegY = 45;
        Options.CDMStartOmegZ = 45;
        Options.CDMStartAX = 1000;
        Options.CDMStartAY = 1000;
        Options.CDMStartAZ = 1000;
        Options.CDMStartOpen = 0.1;
        Options.CDMStartDV = 1e06;
        Options.CDMMinZ = 500;
        Options.CDMMinOmegX = 0;
        Options.CDMMinOmegY = 0;
        Options.CDMMinOmegZ = 0;
        Options.CDMMinAX = 500;
        Options.CDMMinAY = 500;
        Options.CDMMinAZ = 500;
        Options.CDMMinOpen = -5;
        Options.CDMMinDV = -1.5e08;
        Options.CDMMaxZ = 10000;
        Options.CDMMaxOmegX = 90;
        Options.CDMMaxOmegY = 90;
        Options.CDMMaxOmegZ = 180;
        Options.CDMMaxAX = 10000;
        Options.CDMMaxAY = 10000;
        Options.CDMMaxAZ = 10000;
        Options.CDMMaxOpen = 5;
        Options.CDMMaxDV = 1.5e08;
    end
    if ismember(2,Options.CDMGeometry)  % Simple sphere 
        % Constrain parameters where needed
        Options.CDM_AS_StartZ = 5000;
        Options.CDM_AS_StartAX = 1000;
        Options.CDM_AS_StartDV = 1e06;
        Options.CDM_AS_MinZ = 500;
        Options.CDM_AS_MinAX = 500;
        Options.CDM_AS_MinDV = -1.5e08;
        Options.CDM_AS_MaxZ = 10000;
        Options.CDM_AS_MaxAX = 10000;
        Options.CDM_AS_MaxDV = 1.5e08;
    end
    if ismember(3,Options.CDMGeometry) % Sphere with trend/plunge 
        % Constrain parameters where needed
        Options.CDM_S_StartZ = 5000;
        Options.CDM_S_StartAX = 1000;
        Options.CDM_S_StartOmegX = 45;
        Options.CDM_S_StartOmegZ = 90;
        Options.CDM_S_StartDV = 1e06;
        Options.CDM_S_MinZ = 500;
        Options.CDM_S_MinAX = 500;
        Options.CDM_S_MinOmegX = 0;
        Options.CDM_S_MinOmegZ = 0;
        Options.CDM_S_MinDV = -1.5e08;
        Options.CDM_S_MaxZ = 10000;
        Options.CDM_S_MaxAX = 10000;
        Options.CDM_S_MaxOmegX = 90;
        Options.CDM_S_MaxOmegZ = 180;
        Options.CDM_S_MaxDV = 1.5e08;
    end
    if ismember(4,Options.CDMGeometry) % Symmetric sill
        % Constrain parameters where needed
        Options.CDM_Si_StartZ = 5000;
        Options.CDM_Si_StartAX = 1000;
        Options.CDM_Si_StartDV = 1e06;
        Options.CDM_Si_MinZ = 500;
        Options.CDM_Si_MinAX = 500;
        Options.CDM_Si_MinDV = -1.5e08;
        Options.CDM_Si_MaxZ = 10000;
        Options.CDM_Si_MaxAX = 10000;
        Options.CDM_Si_MaxDV = 1.5e08;
    end
    if ismember(5,Options.CDMGeometry) % Sill (non-symmetric)
        % Constrain parameters where needed
        Options.CDM_Si2_StartZ = 5000;
        Options.CDM_Si2_StartAX = 1000;
        Options.CDM_Si2_StartAY = 1000;
        Options.CDM_Si2_StartOmegZ = 90;
        Options.CDM_Si2_StartDV = 1e06;
        Options.CDM_Si2_MinZ = 500;
        Options.CDM_Si2_MinAX = 500;
        Options.CDM_Si2_MinAY = 500;
        Options.CDM_Si2_MinOmegZ = 0;
        Options.CDM_Si2_MinDV = -1.5e08;
        Options.CDM_Si2_MaxZ = 10000;
        Options.CDM_Si2_MaxAX = 10000;
        Options.CDM_Si2_MaxAY = 10000;
        Options.CDM_Si2_MaxOmegZ = 180;
        Options.CDM_Si2_MaxDV = 1.5e08;
    end
    if ismember(6,Options.CDMGeometry) % Dyke-like
        Options.CDM_D_StartZ = 5000;
        Options.CDM_D_StartAX = 1000;
        Options.CDM_D_StartAZ = 1000;
        Options.CDM_D_StartOmegZ = 90;
        Options.CDM_D_StartDV = 1e06;
        Options.CDM_D_MinZ = 500;
        Options.CDM_D_MinAX = 500;
        Options.CDM_D_MinAZ = 500;
        Options.CDM_D_MinOmegZ = 0;
        Options.CDM_D_MinDV = 0;
        Options.CDM_D_MaxZ = 10000;
        Options.CDM_D_MaxAX = 10000;
        Options.CDM_D_MaxAZ = 10000;
        Options.CDM_D_MaxOmegZ = 180;
        Options.CDM_D_MaxDV = 1.5e08;
    end
    if ismember(7,Options.CDMGeometry) % Prolate spheroid
        Options.CDM_PS_StartZ = 5000;
        Options.CDM_PS_StartAspectRatio = 0.5; % Less than 1
        Options.CDM_PS_StartAZ = 1000;
        Options.CDM_PS_StartOmegX = 22.5;
        Options.CDM_PS_StartOmegZ = 90;
        Options.CDM_PS_StartDV = 1e06;
        Options.CDM_PS_MinZ = 500;
        Options.CDM_PS_MinAspectRatio = 0.2;
        Options.CDM_PS_MinAZ = 500;
        Options.CDM_PS_MinOmegX = 0;
        Options.CDM_PS_MinOmegZ = 0;
        Options.CDM_PS_MinDV = -1.5e08;
        Options.CDM_PS_MaxZ = 10000;
        Options.CDM_PS_MaxAspectRatio = 1;
        Options.CDM_PS_MaxAZ = 10000;
        Options.CDM_PS_MaxOmegX = 45;
        Options.CDM_PS_MaxOmegZ = 180;
        Options.CDM_PS_MaxDV = 1.5e08;
    end
    if ismember(8,Options.CDMGeometry) % Oblate spheroid
        Options.CDM_OS_StartZ = 5000;
        Options.CDM_OS_StartAspectRatio = 0.5; % Less than 1
        Options.CDM_OS_StartAX = 1000;
        Options.CDM_OS_StartOmegX = 22.5;
        Options.CDM_OS_StartOmegZ = 90;
        Options.CDM_OS_StartDV = 1e06;
        Options.CDM_OS_MinZ = 500;
        Options.CDM_OS_MinAspectRatio = 0.2;
        Options.CDM_OS_MinAX = 500;
        Options.CDM_OS_MinOmegX = 0;
        Options.CDM_OS_MinOmegZ = 0;
        Options.CDM_OS_MinDV = -1.5e08;
        Options.CDM_OS_MaxZ = 10000;
        Options.CDM_OS_MaxAspectRatio = 1;
        Options.CDM_OS_MaxAX = 10000;
        Options.CDM_OS_MaxOmegX = 45;
        Options.CDM_OS_MaxOmegZ = 180;
        Options.CDM_OS_MaxDV = 1.5e08;
    end
end

% For bounds of other sources, change the .inp file (e.g. "Generic_Input_File.inp") directly before running

% Model Setup (Step 8)
Options.nRuns = 2e5; % Number of iternations for GBIS
Options.SeedingRun = 0; % Optionally run a seeding run to start full inversion with tighter parameters bounds (1 ==yes; 0==no)
Options.SeedingMaxRuns = 3; % Number of seeding runs to run in sequence to constrain bounds
Options.SeedingnRuns = 5e4; % Number of runs for a seeding run (if Options.SeedingRun ==1)
Options.SeedingBurnin = 2.5e4; % Burn-in (nRuns) for seeding runs for setting lower and upper bounds from percentiles
Options.SeedingMethod = 1; % Method for constraining bounds (1== Percentiles; 2== stdDev)
Options.SeedingCriteria = 1; % Criteria for new bounds. If Options.SeedingMethod == 1, Options.SeedingCriteria == percentiles e.g. 95; If Options.SeedingMethod == 2, Options.SeedingCriteria == N stdDevs from optimal results
Options.SeedingTargetReduction = 100; % Target mean reduction (%) in bound ranges across all parameters (to allow seeding runs to exit early). If you don't want to set a target, set it to 100%)
Options.skipSimulatedAnnealing = 'n'; % Skip simulated annealing process
Options.SingleFrameOnly = 0; % Only run 1 frame per volcano
Options.AscDscOnly = 0; % Only run for InSAR data you have more than 1 frame of data for

% Reports (Step 9)
Options.Reports = 1; % Generate final reports at the same time or not (1==yes;0==no)
Options.AreaCutoff = 0.012; % (in m) - cutoff value to use when calculating area of signals from forward models - this should relate to the noise of the input images
Options.Burnin = 5e4; % Burn-in value (number of runs) used when preparing the final reports (if reports are used)
Options.BulkOutputs = 0; % Create summary figures (downsampled) of the full bulk run (1) or a single figure with all DMRs (2)
Options.BulkOutputsRaw = 0; % Create summary figures (full resolution) of the bulk run or a single figure with all DMRs (2)
Options.BulkUnwrapped = 0; % Create bulk summary figures with unwrapped data (if Options.BulkOutputs==1)
Options.BulkWrapped = 0; % Create bulk summary figures with wrapped data (if Options.BulkOutputs==1)
Options.CreateTable = 1; % Create output table or not

% Create Catalogue (Step 10)
Options.TableOverwrite =0; % Overwrite table if filename is the same (1==yes;0==no)
Options.TableRoundValues =5; % Round numeric values in table (0==no; >0 == number of sig. figs. to round to)

%% Save or load options
if SaveOptions ==1
    if ~exist([pwd,'/Options'],'dir')
        mkdir(pwd,'Options')
        addpath([pwd,'/Options'])
    end
    save([pwd,'/Options/',Options.BulkRunID,'_',Options.RunID,'_Options.mat'],'Options');
end

if LoadOptions ==1
    load(LoadFilename);
    Options.NewStartStep = 0; % Options for new starting and ending steps if loading progress and options from a part-completed run 
    Options.NewEndStep = 0;
    %Options.StartStep = Options.NewStartStep; % (comment in if needed)
    %Options.EndStep = Options.NewEndStep; % (comment in if needed)
end

%%%%%%%%%%%%%%%%%%%% DO NOT EDIT BELOW THIS LINE UNLESS NECESSARY %%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('Options and input data read')
addpath(genpath([pwd,'/GBIS'])); % Add GBIS folder to current path
disp('GBIS Scripts added to MATLAB path')

% Hide all figures (so it can run in the background) and make backgrounds white (comment out if you want to see figures)
set(0,'defaultfigurecolor',[1 1 1]);
% (Caution - this script produces a LOT of figures which may impact performance if this line is commented out)
set(0, 'DefaultFigureVisible', 'off');

% Remove spaces from input file (needed for step 7)
inp_Filepath = Remove_inp_spaces([input_Filename,'.inp'],[input_Filename,'_NoSpaces.inp']);

% Find and sort bulk timeseries and input files
inputFiles = dir(inp_Filepath);
TS_Files = SortStruct(TS_Files, 'name');

%% Steps to execute
% If in 'bulk', use asc and dsc data options to figure out which data is being used for each volcano
[TS_Files, Loop_nums] = Get_Loop_Nums(TS_Files,Options);

% IF JOB SPLITTING  
args = getenv('GROUP_IDX'); % Get which group of files is being used
group_idx = str2double(args);
if exist('group_idx','var') && ~isnan(group_idx) % For TMUX looping
    Loop_nums = {Loop_nums{group_idx}};
    TS_Files = TS_Files(Loop_nums{:});
    Loop_nums = {Loop_nums{:} - (min(Loop_nums{:}) -1)}; % Re-adjust loop nums to work with cropped TS_Files
end

% Prepare initial variables
rad2m = Options.WavelengthM./(4.*pi);
m2rad= (4.*pi)./Options.WavelengthM;
FullTable = [];
DefaultInpFilePath = inp_Filepath;

% Run MANUAL processes
logicalResults = structfun(@(x) isnumeric(x) && any(x ~= 0), MANUAL_Options, 'UniformOutput', true);
RunManual = any(logicalResults);

if RunManual
    disp('Running manual pre-processing')

    % Create directory structure
    if ~exist([pwd,'/Manual_Inputs'],'dir')
        mkdir(pwd,'Manual_Inputs')
        addpath([pwd,'/Manual_Inputs'])
    end

    if ~exist([pwd,'/Manual_Inputs/Mask'],'dir')
        mkdir(pwd,'Manual_Inputs/Mask')
        addpath([pwd,'/Manual_Inputs/Mask'])
    end

    if ~exist([pwd,'/Manual_Inputs/AOI'],'dir')
        mkdir(pwd,'Manual_Inputs/AOI')
        addpath([pwd,'/Manual_Inputs/AOI'])
    end

    if ~exist([pwd,'/Manual_Inputs/Location'],'dir')
        mkdir(pwd,'Manual_Inputs/Location')
        addpath([pwd,'/Manual_Inputs/Location'])
        error('Must have "Manual_Inputs" folder set up before using the manual functions')
        return
    end

    for i = 1:length(Loop_nums)
        NumFrames = length(Loop_nums{i});
        for j = 1:NumFrames
            Options.CropTS_start = Options.CropTS_startAll(j);
            Options.CropTS_end = Options.CropTS_endAll(j); 
            disp(['Manual pre-processing - Frame ',num2str(j),' out of ', num2str(NumFrames), ' | Bulk run ', num2str(i), ' out of ',num2str(length(Loop_nums))]);
            [MANUAL_DefImg, lat, lon, VolcName, Days, FileInfo, LOS, Heading, Incidence, Metadata] = Step0_Get_Initial_Variables(TS_Files(Loop_nums{i}(j)),inputFiles,Options);
            if MANUAL_Options.MaskData == 1
                disp('Loading manual mask')
                MANUAL_Mask{i,j} = Manual_ExtraMask(VolcName,lat,lon,MANUAL_Options);
            end

            if MANUAL_Options.AOI ==1
                disp('Loading manual AOI')
                MANUAL_AOI{i,j} = Manual_AOI(VolcName,lat,lon,MANUAL_Options);
            end
            
            if MANUAL_Options.Location ==1
                disp('Loading manual signal location')
                ManualDefLoc = Manual_Location(VolcName,lat,lon,MANUAL_Options);
                MANUAL_AOI{i,j}.pix = ManualDefLoc;
                MANUAL_AOI{i,j}.Limits = [ManualDefLoc(2)-5,ManualDefLoc(1)-5; ManualDefLoc(2)+5,ManualDefLoc(1)+5];
            end
        end
    end
end


for i = 1:length(Loop_nums)
    if LoadProgress ~=1
        % Generate run name in here based on frames used
        NumFrames = length(Loop_nums{i});
        FileExt = length(extractAfter(TS_Files(Loop_nums{i}(1)).name,'.')) + 1;
        if NumFrames >1
            outputFileName = [TS_Files(Loop_nums{i}(1)).name(1:end-FileExt),'_',TS_Files(Loop_nums{i}(2)).name(end-(17+FileExt-1):end-FileExt),Options.RunID,'.inp'];
        else
            outputFileName = [TS_Files(Loop_nums{i}(1)).name(1:end-FileExt),Options.RunID,'.inp'];
        end

        Run_name{i} = outputFileName(1:end-4);
        outputFileName = [pwd,'/InputFiles/',outputFileName];
    end
    
    disp('--------------------------------- Running for next deformation signal ---------------------------------')
    for j = 1:NumFrames
        % Initialise variables and folder structure (step 0)
        if LoadProgress==1
            disp('Loading previous data')
            load([LoadFilename,'_Area',num2str(i),'_Img',num2str(j),'.mat']);
        end

        if SaveProgress==1
            if j>1
                disp('Saving current progress')
                if ~exist([pwd,'/SavedRuns'],'dir')
                    mkdir(pwd,'SavedRuns')
                    addpath([pwd,'/SavedRuns'])
                end
                save([pwd,'/SavedRuns/','Steps_',num2str(Options.StartStep),'_',num2str(Options.EndStep),'_',Options.BulkRunID,'_Area',num2str(i),'_Img',num2str(j-1),'.mat']);
            end
        end
        Options.CropTS_start = Options.CropTS_startAll(j);
        Options.CropTS_end = Options.CropTS_endAll(j); 
        disp(['Step 0 - Frame ',num2str(j),' out of ', num2str(NumFrames), ' | Bulk run ', num2str(i), ' out of ',num2str(length(Loop_nums))]);
        [DefImg, lat, lon, VolcName, Days, FileInfo, LOS, Heading, Incidence, Metadata] = Step0_Get_Initial_Variables(TS_Files(Loop_nums{i}(j)),inputFiles,Options);
        VolcNames{j} = VolcName;
        disp(['Signal and frame: ',VolcName])

        if Options.EndStep == 0
            continue
        end

        %% Step 1
        if Options.StartStep <=1 && Options.EndStep >=1
            % Function call
            if Options.MaskVolcs ==1
                disp(['Step 1 - Frame ',num2str(j),' out of ', num2str(NumFrames), ' | Bulk run ', num2str(i), ' out of ',num2str(length(Loop_nums))]);
                DefImg = Step1_CreateBufferGVP(DefImg, lat, lon, VolcName, rad2m, Options);
            end

            if MANUAL_Options.MaskData ==1
                disp('Manually masking additional parts of the dataset')
                DefImg(MANUAL_Mask{i,j} == 0) = NaN;
            end
            
            if Options.EndStep ==1 && j == NumFrames && i == length(Loop_nums)
                break
            elseif Options.EndStep ==1
                continue
            end
        end
        
        %% Step 2
        if Options.StartStep <= 2 && Options.EndStep >=2
            % Function call
            if Options.SlidingWindow ==1 && MANUAL_Options.AOI == 0
                disp(['Step 2 - Frame ',num2str(j),' out of ', num2str(NumFrames), ' | Bulk run ', num2str(i), ' out of ',num2str(length(Loop_nums))]);
                Location = Step2_SlidingWindowClustering(DefImg, VolcName, Options);
            else
                Location = [];
            end

            if MANUAL_Options.RegionShrink ==1
                disp('Manually applying region shrinking to remove areas of poor unwrapping')
                DefImg = Manual_RegionShrink(DefImg,VolcName,MANUAL_Options);
            end

            if Options.EndStep ==2 && j == NumFrames && i == length(Loop_nums)
                break
            elseif Options.EndStep ==2
                continue
            end
        end
        
        %% Step 3
        if Options.StartStep <= 3 && Options.EndStep >=3
            % Function call
            if ~isempty(LOS)
                if Options.ICA ==1 && MANUAL_Options.ICA ==0
                    disp(['Step 3 - Frame ',num2str(j),' out of ', num2str(NumFrames), ' | Bulk run ', num2str(i), ' out of ',num2str(length(Loop_nums))]);
                    
                    if MANUAL_Options.AOI==1
                        Location = MANUAL_AOI{i,j};
                    end
                    DefImgICA = Step3_DoICA_Test(TS_Files(Loop_nums{i}(j)), DefImg, Location, Options);
                    if ~isempty(DefImgICA)
                        DefImg = DefImgICA;
                    end
                elseif MANUAL_Options.ICA ==1
                    disp('Manually applying ICA to the data')
                    Location = MANUAL_AOI{i,j};
                    DefImgICA = Manual_ICA(TS_Files(Loop_nums{i}(j)), DefImg, Location, Options, MANUAL_Options);
                elseif RunManual && MANUAL_Options.ICA ==0 && MANUAL_Options.AOI==1
                    Location = MANUAL_AOI{i,j};
                end
            else
                disp('Input data is a single interferogram not a timeseries, so ICA cannot be performed - skipping this step')
            end

            if Options.EndStep ==3 && j == NumFrames && i == length(Loop_nums)
                break
            elseif Options.EndStep ==3
                continue
            end
        end
        
        %% Step 4
        if Options.StartStep <= 4 && Options.EndStep >=4
            % Function call
            if Options.SlidingWindow ==1 && MANUAL_Options.AOI ==0
                disp(['Step 4 - Frame ',num2str(j),' out of ', num2str(NumFrames), ' | Bulk run ', num2str(i), ' out of ',num2str(length(Loop_nums))]);
                [FineBoundingBox, Image, OtsuFigure, SignalLocation, compMask] = Step4_ExtractOtsuBoundingBoxV2(DefImg, Location, VolcName, lon, lat, Options);
            end

            % Add option for if sliding window is not turned on
            if Options.EndStep ==4 && j == NumFrames && i == length(Loop_nums)
                break
            elseif Options.EndStep ==4
                continue
            end
        end

        %% Step 5
        if Options.StartStep <= 5 && Options.EndStep >=5
            % Function call
            if MANUAL_Options.AOI==1
                Location = MANUAL_AOI{i,j};
            end

            disp(['Step 5 - Frame ',num2str(j),' out of ', num2str(NumFrames), ' | Bulk run ', num2str(i), ' out of ',num2str(length(Loop_nums))]);
            Model = Step5_FitTimeseriesFunctions(LOS, Days, FileInfo, Location.pix, VolcName, Options);
            if Options.EndStep ==5 && j == NumFrames && i == length(Loop_nums)
                break
            elseif Options.EndStep ==5
                continue
            end
        end

        %% Step 6
        if Options.StartStep <= 6 && Options.EndStep >=6

            if i==1 && j==1 % Reset SS_Factors in case they are adjusted later on
                OrigSS_Factor = Options.SS_Factor;
                OrigSS_FactorF = Options.SS_FactorF;
            else
                Options.SS_Factor = OrigSS_Factor;
                Options.SS_FactorF = OrigSS_FactorF;
            end

            % Function call
            disp(['Step 6 - Frame ',num2str(j),' out of ', num2str(NumFrames), ' | Bulk run ', num2str(i), ' out of ',num2str(length(Loop_nums))]);
            if MANUAL_Options.Location ==0
                if Options.FarFieldMask == 1
                    [DefImg, DefImgOld] = ExtraFarFieldMask(TS_Files(Loop_nums{i}(j)),DefImg,FineBoundingBox,Options); 
                    Filename_Raw_Unmasked{j} = UnmaskedFullResDefImg(DefImgOld,lon,lat,FineBoundingBox,Heading,Incidence,VolcName,Metadata.Frame,Options); 
                end
                [loadedData, Filename{j}, Filename_Raw{j},nObs_SS, nObs_Raw, BoundingBox, SS_Factor, SS_FactorF] = Step6_NestedUniformDS(DefImg,lon,lat,FineBoundingBox,Heading,Incidence,VolcName,Metadata.Frame,compMask,SignalLocation,Options);

                Options.SS_Factor = SS_Factor; % In case they have been automatically adjusted in step 6
                Options.SS_FactorF = SS_FactorF;
            elseif MANUAL_Options.Location ==1
                disp('Downsampling based on manually defined AOI')
                Location = MANUAL_AOI{i,j};
                SignalLocation = ManualSignalLocation(lon,lat,Location,Options.SpatialRes);
                if Options.FarFieldMask == 1
                    [DefImg, DefImgOld] = ExtraFarFieldMask(TS_Files(Loop_nums{i}(j)),DefImg,MANUAL_AOI{i,j},Options);  
                    Filename_Raw_Unmasked{j} = UnmaskedFullResDefImg(DefImgOld,lon,lat,FineBoundingBox,Heading,Incidence,VolcName,Metadata.Frame,Options); 
                end
                [loadedData, Filename{j}, Filename_Raw{j},nObs_SS, nObs_Raw, BoundingBox, SS_Factor, SS_FactorF] = Manual_Downsampling(DefImg,lon,lat,MANUAL_AOI{i,j},Heading,Incidence,VolcName,Metadata.Frame,SignalLocation,Options);
                FineBoundingBox = MANUAL_AOI{i,j}.pgon;
            end

            if Options.FarFieldMask ==1 && Options.FarFieldUnmaskedVar ==1
                % Save unmasked file to use to calculate variogram stats in step 7
                Filename_Raw{j} = Filename_Raw_Unmasked{j};
            end

            if Options.EndStep ==6 && j == NumFrames && i == length(Loop_nums)
                break
            elseif Options.EndStep ==6
                continue
            end
        end

        %% Step 7
        if Options.StartStep <= 7 && Options.EndStep >=7
            % Function call
            if j ==2
                inp_Filepath = InpFilePath;
            else
                inp_Filepath = DefaultInpFilePath;
            end
            disp(['Step 7 - Frame ',num2str(j),' out of ', num2str(NumFrames), ' | Bulk run ', num2str(i), ' out of ',num2str(length(Loop_nums))]);
            if Options.EstimateDepthBounds ==1
                Options.NewDepthLims = RecalculateDepthBounds(compMask,lat,lon,outputFileName,Options);
            end
            InpFilePath = Step7_PrepInputFile(inp_Filepath,outputFileName,FineBoundingBox,BoundingBox,nObs_Raw,Filename,Filename_Raw,j,Options);

            if Options.EndStep ==7 && j == NumFrames && i == length(Loop_nums)
                break
            elseif Options.EndStep ==7
                continue
            end
        end
    end

    % Close all figures before continuing (for speed)
    close all

    %% Step 8
    if Options.StartStep <= 8 && Options.EndStep >=8
        % Function call
        if Options.SkipGBIS ==0
            disp(['Step 8 - Bulk run ', num2str(i), ' out of ',num2str(length(Loop_nums))]);
            OutputFilepaths = Step8_RunBulkInversion(InpFilePath,NumFrames,Options);
        end

        if Options.EndStep ==8 && i == length(Loop_nums)
            break
        elseif Options.EndStep ==8
            continue
        end
    end

    if Options.SkipGBIS ==1
        disp('"SkipGBIS" option turned on, skipping inversion and moving on to the next dataset')
        continue
    end


    %% Step 9
    if Options.StartStep <= 9 && Options.EndStep >=9
        % Function call
        if Options.Reports ==1
            disp(['Step 9 - Bulk run ', num2str(i), ' out of ',num2str(length(Loop_nums))]);
            if ~RunManual || (length(Options.OtherSourceType)>1 & Options.OtherSource ==1)
                FullTable = Step9_GenerateReportsTableV2(FullTable,OutputFilepaths,NumFrames,VolcNames,VolcName,Options);
            else
                FullTable = Step9_GenerateReportsTableV2Mult(FullTable,OutputFilepaths,NumFrames,VolcNames,VolcName,Options);
            end
        end

        if RunManual
            disp('Deformation catalogue and report generation may not work perfectly for manual input runs, please check outputs')
        end

        if Options.EndStep ==9 && i == length(Loop_nums)
            break
        elseif Options.EndStep ==9
            continue
        end
    end

end

%% Step 10
if Options.StartStep <= 10 && Options.EndStep >=10 && Options.SkipGBIS == 0
    % Function call
    disp('Step 10')
    if Options.CreateTable ==1
        [FullTable, CatalogueFilePath] = Step10_CreateCatalogue(FullTable,Options);
    end
end

% Save progress if needed
if SaveProgress ==1
    disp('Saving progress')
    if ~exist([pwd,'/SavedProgress'],'dir')
        mkdir(pwd,'SavedProgress')
        addpath([pwd,'/SavedProgress'])
    end
    save([pwd,'/SavedProgress/',Options.BulkRunID,'_',Options.RunID,'_Progress.mat']);
end
