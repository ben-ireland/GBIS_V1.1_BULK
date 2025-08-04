function [FineBoundingBox, BoundingBox, Filename, loadedData, nObs_SS, nObs_Raw] = OtsuDownsampling(LastStep,lat,lon,SS_Factors,SS,BB_Shape,Frame,wavelength,SpatialRes,RunID)
%Ben Ireland, University of Bristol, June 2024
% Function to downsample InSAR data using an Otsu-thresholding based approach

%%%% EXAMPLE USAGE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% [FineBoundingBox, BoundingBox, Filename, loadedData, nObs_SS, nObs_Raw] = OtsuDownsampling(LastStep,lat,lon,[50,25],'y',2,'014A_07688_131313',0.056,100,'Test');
%
%%%% FIRST TIME USAGE INSTRUCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 1. Ensure everything is in the correct format as below.
%
%%%%%%%%%%%%%%%%%%%%%%%%%% INPUT VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  LastStep = n x m array of LOS values in m (last step in timeseries or individual IFG)
%
%  lat = n x 1 array of corresponding lat/lon values (in degrees)
%
%  lon = m x 1 array of corresponding lat/lon values (in degrees)
%
%  SS_Factors = subsampling fatcors in the format [Coarse_Factor, Fine_Factor]
%
%  SS = 'y' - subsample data; 'n' - don't subsample data (ignores options
%  in the .inp file)
%
%  BB_Shape =  1==rectantgular bounding box, 2==custom polygon bounding
%  box (based on shape of the signal) - option 2 is recommended
%
%  wavelength = InSAR radar wavelength (e.g. 0.056m for Sentinel 1)
%
%  SpatialRes = Spatial resolution of the raw LOS data (in m)
%
%  RunID = Unique ID for this run
% 
%%%%%%%%%%%%%%%%%%%%%%%%%% OUTPUT VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  FineBoundingBox: coordinates [UL_Lon,UL_Lat,LR_Lon,LR_Lat] of the area
%  of interest for fine downsampling (outputs an empty array if subsampling
%  is not performed
% 
%  BoundingBox: Extents of the full 50km x 50km image, in the format [UL_Lon,UL_Lat,LR_Lon,LR_Lat]
% 
%  Filename: Filepath to the created input file containing the loadedData
%  structure
% 
%  loadedData: data structure containing lat, lon, phase, heading and incidence
%  vectors in a format to ingest into GBIS
%  
%  nOBS_SS: number of data points after downsampling
%
%  nOBS_Raw: number of data points in original synthetic interferogram
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Create folder structure if it does not exist
if ~exist([pwd,'/nObs'],'dir')
    mkdir(pwd,'nObs')
    addpath([pwd,'/nObs'])
end

if ~exist([pwd,'/BoundingBoxes'],'dir')
    mkdir(pwd,'Bounding_Boxes')
    addpath([pwd,'/Bounding_Boxes'])
end

if ~exist([pwd,'/InputData'],'dir')
    mkdir(pwd,'InputData')
    addpath([pwd,'/InputData'])
end

if ~exist([pwd,'/ForReview'],'dir')
    mkdir(pwd,'ForReview')
    addpath([pwd,'/ForReview'])
end

% Download heading and incidence angle from LiCSAR portal
Track = Frame(1:3);
if startsWith(Track,'0')
    Track = Track(2:end);
end
download_link = char(strcat('https://gws-access.jasmin.ac.uk/public/nceo_geohazards/LiCSAR_products/'...
    ,Track,'/',Frame,'/metadata/metadata.txt'));

Metadata = webread(download_link);

head = extractBetween(Metadata,"heading=","avg");
head = strtrim(head);
head = str2double(head);

incidence = extractBetween(Metadata,"avg_incidence_angle=","azimuth");
incidence = strtrim(incidence);
incidence = str2double(incidence);

%% Work out coordinates for bounding box and fine bounding box
% Extract bounds of the full extent
LatMax = max(lat(:));
LatMin = min(lat(:));
LonMax = max(lon(:));
LonMin = min(lon(:));

lonBB = lon;
latBB = lat;

BoundingBox = [LonMin,LatMax,LonMax,LatMin];

% Make polyshape from big bounding box (covering the full extent of the
% image)
BoundingBoxPoly = polyshape([BoundingBox(1) BoundingBox(1) BoundingBox(3)...
    BoundingBox(3)],[BoundingBox(2) BoundingBox(4) BoundingBox(4)...
    BoundingBox(2)]);

%% Pre-process for downsampling and save nObs data
%Convert from LOS (m) to unwrapped Phase (radians) and check phase
Phase = double(((4*pi)*LastStep)/wavelength);
Phase = -1*Phase; %-ive as Phase is positive when away from the satellite

%Create grids of lat and lon
lat = repmat(lat,1,(length(lat)));
lon = lon.';
lon = repmat(lon,(length(lon)),1);

%Find number of observations of full resolution ifg
nObs_Raw = numel(LastStep);
        
%% Downsample LOS and Lat/Lon with COARSE/FINE Subsampling WITH averaging
if SS == 'y'

    % Takes into account the coherence mask 
    % WITH EDITABLE THRESHOLD FOR RETAINING DOWNSAMPLED PIXELS BASED ON PROPORTION OF NaN VALUES
    
    % Define NaN threshold to keep or ignore downsampled pixel values
    NaN_Threshold = 0.5;
    
    % Define image dimensions
    n = size(Phase, 1); % Number of rows
    m = size(Phase, 2); % Number of columns

    % Find bounding box using Otsu's thresholding
    [FineBoundingBox, Image, OtsuFigure, SignalLocation] = ExtractSignalBoundingBoxCheck(BB_Shape, LastStep, 5, RunID, SpatialRes, lonBB, latBB);
    
    if SignalLocation.Flag ==1
        if ~exist([pwd,'/ForReview/',RunID],'dir')
            mkdir([pwd,'/ForReview'],RunID)
            addpath([pwd,'/ForReview/',RunID])
        end
        Filename = []; % Empty output variables
        FineBoundingBox = [];
        loadedData = [];
        nObs_SS = [];

        OtsuGrayFilename = strcat(pwd,'/ForReview/',RunID,'/',RunID,'GrayIfg','_Shape_',num2str(BB_Shape),'.png');
        OtsuFigFilename = strcat(pwd,'/ForReview/',RunID,'/',RunID,'OtsuFig','_Shape_',num2str(BB_Shape),'.png');
        imwrite(uint8(Image),OtsuGrayFilename);
        saveas(OtsuFigure,OtsuFigFilename);

        save([pwd,'/ForReview/',RunID,'/',RunID,'_Shape_',num2str(BB_Shape),'BoundingBox.mat'],'FineBoundingBox','BoundingBox','BoundingBoxPoly');
        save([pwd,'/ForReview/',RunID,'/',RunID,'_Shape_',num2str(BB_Shape),'_SignalLocation.mat'],'SignalLocation');
        return
    end

    % Unique identifier based on parameters
    SS_Style = ['BB_CF_Avg_Otsu_',num2str(SS_Factors(1)),'_',num2str(SS_Factors(2)),'_',num2str(NaN_Threshold)];
    
    % Process lat and lon matricies
    lon2 = lon(1,:);
    lat2 = lat(:,1);
    
    % Mask based on polygon coordinates
    Coords = FineBoundingBox.Vertices;
    fine_samp = poly2mask(Coords(:,1),Coords(:,2),n,m);
    fine_samp = fine_samp'; % Reverse coords of bounding box because the same is done to the LOS
    
    % Initialize empty matrices for downsampled image and downsampling locations
    downsampledImg = NaN(n,m);
    downsampledImgFine = NaN(n,m);
    
    downsampledLocs = NaN(n,m);
    downsampledLocsFine = NaN(n,m);
    
    Phase = Phase'; % So the logical indexing assigns the correct phase values to each lat/lon coordinate
    
    % Iterate through each pixel and downsample
    for i = 1:n
        for j = 1:m
            if mod(i,SS_Factors(1)) ==0 && mod(j,SS_Factors(1)) ==0
                %Get values and indexes of area
                LonAvg = mean(lon2(i-(SS_Factors(1)-1):i));
                LatAvg = mean(lat2(j-(SS_Factors(1)-1):j));
    
                LonIdx = round(mean([i-(SS_Factors(1)-1),i]));
                LatIdx = round(mean([j-(SS_Factors(1)-1),j]));
    
                downsampledLocs(LonIdx,LatIdx) = 1;
    
                %Get Phase values
                area = Phase(i-(SS_Factors(1)-1):i,j-(SS_Factors(1)-1):j);
    
                if nnz(area)/numel(area) > NaN_Threshold
                    downsampledImg(LonIdx,LatIdx) = mean(nonzeros(area(:)));
                else
                    downsampledImg(LonIdx,LatIdx) = NaN;
                end
            end
    
            if mod(i,SS_Factors(2)) ==0 && mod(j,SS_Factors(2)) ==0
                %Get values and indexes of area
                LonAvg = mean(lon2(i-(SS_Factors(2)-1):i));
                LatAvg = mean(lat2(j-(SS_Factors(2)-1):j));
    
                LonIdx = round(mean([i-(SS_Factors(2)-1),i]));
                LatIdx = round(mean([j-(SS_Factors(2)-1),j]));
    
                downsampledLocsFine(LonIdx,LatIdx) = 1;
    
                %Get Phase values
                area = Phase(i-(SS_Factors(2)-1):i,j-(SS_Factors(2)-1):j);
    
                if nnz(area)/numel(area) > NaN_Threshold
                    downsampledImgFine(LonIdx,LatIdx) = mean(nonzeros(area(:)));
                else
                    downsampledImgFine(LonIdx,LatIdx) = NaN;
                end
            end
        end
    end
    
    downsampledLocsFine(fine_samp~=1)=NaN;
    downsampledLocs(fine_samp==1)=NaN;
    
    downsampledImgFine(fine_samp~=1)=NaN;
    downsampledImg(fine_samp==1)=NaN;
    
    downsampledLocs(downsampledLocsFine==1)=1;
    downsampledImg(fine_samp==1)=downsampledImgFine(fine_samp==1);
    
    Check_NaN = isnan(downsampledImg);
    downsampledLocs(Check_NaN)= NaN;
    
    % Find downsampled locations
    [xDownsampled, yDownsampled] = find(~isnan(downsampledLocs));
    
    Null = ~isnan(downsampledImg);
    downsampledImg = downsampledImg(Null);
    
    %Convert downsampled x and y locations into Lat or Lon
    Lon3 = zeros(length(xDownsampled),1);
    Lat3 = zeros(length(yDownsampled),1);
    
    for x = 1:length(yDownsampled)
        Lon3(x) = lon2(xDownsampled(x));
        Lat3(x) = lat2(yDownsampled(x));
    end
    
    loadedData.Lon = Lon3;
    loadedData.Lat = Lat3;
    loadedData.Phase = downsampledImg;

    nObs_SS = length(loadedData.Lon);

%% No subsampling
elseif SS == 'n'
    % Initialise empty output variables
    FineBoundingBox = [];
    SignalLocation = [];
    nObs_SS = [];

    loadedData.Lon = reshape(lon,[],1);
    loadedData.Lat = reshape(lat,[],1);
    Phase = reshape(Phase,[],1);
    loadedData.Phase = Phase;

    SS_Style = 'No_SS';
else
    error('Error. Please specify if the data should be subsampled using "y" (yes) or "n" (no)')
end


%% Remove Null values
%Find and remove zero or NaN values
Null = (loadedData.Phase~=0) & ~isnan(loadedData.Phase);
loadedData.Phase = loadedData.Phase(Null);
loadedData.Lat = loadedData.Lat(Null);
loadedData.Lon = loadedData.Lon(Null);

%% Prepare final parts of input data
%Create vectors of the heading and incidence angle
loadedData.Heading = (zeros(size(loadedData.Phase)))+head;
loadedData.Inc = (zeros(size(loadedData.Phase)))+incidence;

%Write and save input file
Lon = loadedData.Lon;
Lat = loadedData.Lat;
Phase = loadedData.Phase;
Inc = loadedData.Inc;
Heading = loadedData.Heading;

Filename = strcat(pwd,'/InputData/',RunID,'_',Frame,'_',SS_Style,'_.mat')
save(Filename,'Lon','Lat','Phase','Inc','Heading');

%% Save outputs from Otsu thresholding

if SS == 'y'
    OtsuGrayFilename = strcat(pwd,'/Bounding_Boxes/',RunID,'GrayIfg','_Shape_',num2str(BB_Shape),'.png');
    OtsuFigFilename = strcat(pwd,'/Bounding_Boxes/',RunID,'OtsuFig','_Shape_',num2str(BB_Shape),'.png');
    imwrite(uint8(Image),OtsuGrayFilename);
    saveas(OtsuFigure,OtsuFigFilename);

    save([pwd,'/Bounding_Boxes/',RunID,'_Shape_',num2str(BB_Shape),'BoundingBox.mat'],'FineBoundingBox','BoundingBox','BoundingBoxPoly');
    save([pwd,'/nObs/',RunID,'_',SS_Style,'_nOBS.mat'],'nObs_SS','nObs_Raw');
end

end