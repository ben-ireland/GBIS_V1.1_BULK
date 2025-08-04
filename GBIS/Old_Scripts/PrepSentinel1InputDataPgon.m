function [VolcName, FineBoundingBox, BoundingBox, Filename, loadedData, nObs_SS, nObs_Raw, SignalLocation, TempParams] = PrepSentinel1InputDataPgon(TS_Files,inputFileName,SS,BB_Shape,auto_angles,wavelength,SpatialRes,CropTS,Options)
%Ben Ireland, University of Bristol, October 2023
% Function to prepare Sentinel 1 timeseries interferograms (.nc) for ingestion into GBIS
% and automatically extract bounding boxes of signal locations

%%%% FIRST TIME USAGE INSTRUCTIONS %%%%
%
% 1. Ensure everything is in the correct format as below.
% 2. Change lines as needed below 'endsWith(TS_Files.name, '.h5')' and/or 'endsWith(TS_Files.name, '.nc')' 
%    to fit your own folder structure for the timeseries processing. For one volcano, it may not be necessary
%    to extract the name of the volcano to add it to the filename (final lines of the script). Also change the
%    lines related to the extraction of the frame if needed.

%%%%%%%%%%%%%%%%%%%%%%%%%% INPUT VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  TS_Files: Local path to .mat file containing .nc timeseries files (as a structure from 'dir' function)
%
%  inputFileName: Local path to .inp (text) input file specifiying downsampling parameters
%
%  SS = 'y' - subsample data; 'n' - don't subsample data (ignores options
%  in the .inp file)
%
%  BB_Shape =  1==rectantgular bounding box, 2==custom polygon bounding
%  box (based on shape of the signal) - option 2 is recommended
%
%  auto_angles: 0== input heading and incidence angles manually, 1==
%  extract heading and incidence angle from LiCSAR metadata
%
%  wavelength: InSAR radar wavelength (e.g. 0.056m for Sentinel 1)
%
%  CropTS: Crop the timeseries based on temporal fitted functions (1) or
%  not (other value)
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
%  SignalLocation: Spatial parameters of the signal location
%
%  TempParams: Temporal parameters of the signal from fitting functions to
%  the timeseries
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Create folder structure if it does not exist

if ~isa(TS_Files,"struct")
    TS_Files = dir(TS_Files);
end

if ~exist([pwd,'/LiCSMetadata'],'dir')
    mkdir(pwd,'LiCSMetadata')
    addpath([pwd,'/LiCSMetadata'])
end

if ~exist([pwd,'/Spatial_Parameters'],'dir')
    mkdir(pwd,'Spatial_Parameters')
    addpath([pwd,'/Spatial_Parameters'])
end

if ~exist([pwd,'/nObs'],'dir')
    mkdir(pwd,'nObs')
    addpath([pwd,'/nObs'])
end

if ~exist([pwd,'/Bounding_Boxes'],'dir')
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

if ~exist([pwd,'/OriginalData'],'dir')
    mkdir(pwd,'OriginalData')
    addpath([pwd,'/OriginalData'])
end

%% Read input file
if isstruct(inputFileName)
    inputFileName = strcat(inputFileName.folder,'/',inputFileName.name);
end

inputFileID = fopen(inputFileName, 'r');
textLine = fgetl(inputFileID); 

while ischar(textLine)
    eval(textLine)
    textLine = fgetl(inputFileID);
end

fclose(inputFileID);

rad2m = (wavelength./(4.*pi));
m2rad = 4.*pi./wavelength;

%% Load Sentinel 1 datacube
if endsWith(TS_Files.name,'.nc')
    if auto_angles ==1
        %Extract frame and generate LiCSAR download link
        Frame = regexp(TS_Files.name, '(?<=_)[0-9AD]{4}_[0-9]{5}_[0-9]{6}(?=.nc)','match');

        if isfile([pwd,'/LiCSMetadata/',Frame{1},'_Metadata.mat'])
            load([pwd,'/LiCSMetadata/',Frame{1},'_Metadata.mat']);
            Frame = char(Frame);
        else
            FrameNum = regexp(Frame,'[1-9]{1}[0-9]{2}(?=[AD])|(?<=0)[0-9]{2}(?=[AD])','match');
            FrameNum = FrameNum;
            
            if startsWith(FrameNum{1},'0')
                FrameNumMat = cell2mat(FrameNum{1});
                FrameNum{1} = FrameNumMat(2:end);
            end

            download_link = char(strcat('https://gws-access.jasmin.ac.uk/public/nceo_geohazards/LiCSAR_products/'...
                ,FrameNum{1},'/',Frame{1},'/metadata/metadata.txt'));

            Frame = char(Frame);
            %Download metadata and extract heading and incidence angle values
            Metadata = webread(download_link);

            head = extractBetween(Metadata,"heading=","avg");
            head = strtrim(head);
            head = str2double(head);

            incidence = extractBetween(Metadata,"avg_incidence_angle=","azimuth");
            incidence = strtrim(incidence);
            incidence = str2double(incidence);

            save([pwd,'/LiCSMetadata/',Frame,'_Metadata.mat'],"incidence","head");
        end
        
    else
        head = input('Enter the heading angle for the Sentinel 1 frame of interest');
        incidence = input('Enter the average incidence angle for the Sentinel 1 frame of interest');
    end

    VolcanoName = regexp(TS_Files.name,'\S*(?=_[0-9AD]{4}_)','match');
    
    VolcName = TS_Files.name(1:end-3);

    %% Load timeseries files

    TS_Filename = strcat(TS_Files.folder,'/',TS_Files.name);

    %Read .nc file (time series) and extract the final time step
    days = ncread(TS_Filename,'time');
    LOS = ncread(TS_Filename,'DATA');
    lat = ncread(TS_Filename,'lat');
    lon = ncread(TS_Filename,'lon');
    FileInfo = ncinfo(TS_Filename,'time');
    LOS = permute(LOS,[2 1 3]);

    if CropTS == 1
        if TempParams.StartIdx ==1 && TempParams.EndIdx ==length(days)
            LastStep = LOS(:,:,end-1) - LOS(:,:,2); % Crop the first and last timeseries step to reduce noise when there is not a sigmoidal trend
        else
            LastStep = LOS(:,:,TempParams.EndIdx) - LOS(:,:,TempParams.StartIdx);
        end
    else
        LastStep = LOS(:,:,end-1) - LOS(:,:,2);
    end

elseif endsWith(TS_Files.name, '.h5')
    VolcName = char(extractBetween(TS_Files.folder,'ClippedResults/','/'));
    if auto_angles ==1
        %Extract frame and generate LiCSAR download link
        Frame = extractBetween(TS_Files.folder,[VolcName,'/'],'/TS_GEOCml1clip');
        FrameNum = regexp(Frame,'[1-9]{1}[0-9]{2}(?=[AD])|(?<=0)[0-9]{2}(?=[AD])','match');
        FrameNum = FrameNum;

        if isfile([pwd,'/LiCSMetadata/',Frame,'_Metadata.mat'])
            load([pwd,'/LiCSMetadata/',Frame,'_Metadata.mat']);
        else
            if startsWith(FrameNum{1},'0')
                FrameNumMat = cell2mat(FrameNum{1});
                FrameNum{1} = FrameNumMat(2:end);
            end

            download_link = char(strcat('https://gws-access.jasmin.ac.uk/public/nceo_geohazards/LiCSAR_products/'...
                ,FrameNum{1},'/',Frame{1},'/metadata/metadata.txt'));

            Frame = char(Frame);

            %Download metadata and extract heading and incidence angle values
            Metadata = webread(download_link);

            head = extractBetween(Metadata,"heading=","avg");
            head = strtrim(head);
            head = str2double(head);

            incidence = extractBetween(Metadata,"avg_incidence_angle=","azimuth");
            incidence = strtrim(incidence);
            incidence = str2double(incidence);

            save([Frame,'_Metadata.mat'],"incidence","head");
        end
    else
        head = input('Enter the heading angle for the Sentinel 1 frame of interest');
        incidence = input('Enter the average incidence angle for the Sentinel 1 frame of interest');
    end

    ImDates = h5read(char(strcat(TS_Files.folder,'/',TS_Files.name)),'/imdates');
    DatesDT = datetime(ImDates,'ConvertFrom','yyyymmdd');
    days = daysact(DatesDT(1),DatesDT);
    LOS = h5read(char(strcat(TS_Files.folder,'/',TS_Files.name)),'/cum');
    cLat = h5read(char(strcat(TS_Files.folder,'/',TS_Files.name)),'/corner_lat');
    cLon = h5read(char(strcat(TS_Files.folder,'/',TS_Files.name)),'/corner_lon');
    postLat = h5read(char(strcat(TS_Files.folder,'/',TS_Files.name)),'/post_lat');
    postLon = h5read(char(strcat(TS_Files.folder,'/',TS_Files.name)),'/post_lon');
    endLat = (size(LOS,1)-1)*postLat + cLat;
    endLon = (size(LOS,1)-1)*postLon + cLon;
    lat = [cLat:postLat:endLat];
    lon = [cLon:postLon:endLon];
    lon = lon';
    lat = lat'; % Transpose to work with the format of the rest of the script
    FileInfo.StartDate = DatesDT(1);
    FileInfo.Dates = DatesDT;
    LOS = LOS./1000; % Convert LOS from mm to m

    if CropTS == 1
        if TempParams.StartIdx ==1 && TempParams.EndIdx ==length(days)
            LastStep = LOS(:,:,end-1) - LOS(:,:,2); % Crop the first and last timeseries step to reduce noise when there is not a sigmoidal trend
        else
            LastStep = LOS(:,:,TempParams.EndIdx) - LOS(:,:,TempParams.StartIdx);
        end
    else
        LastStep = LOS(:,:,end-1) - LOS(:,:,2);
    end
end

% Plot original data
figure()
h = imagesc(lon,lat,LastStep);
%title('LOS displacement (m)')
axis square
box on
xlabel('Longitude (degrees)')
ylabel('Latitude (degrees)')
colormap(jet)
c = colorbar(gca,"eastoutside");
c.Label.String = 'LOS Displacement (m)';
%c = max(abs([min(LastStep), max(LastStep)]));
c = 0.1;
caxis([-c c])
set(gca,'YDir','normal')
set(h, 'AlphaData', LastStep~=0)
title(['Frame: ',Frame],'interpreter','none')
OriginalFigFilename = strcat(pwd,'/OriginalData/',VolcName,'.png');
saveas(gcf,OriginalFigFilename)
% Make data square if non-square
nonSquare = 0;
if size(LastStep,1) ~= size(LastStep,2)
    disp('Input data is not square.... making it square by padding with NaNs')
    nonSquare = 1;
    Origlon = lon;
    Origlat = lat;
    OrigLastStep = LastStep;

    MaxLen = max(size(LastStep,1),size(LastStep,2)); % Find length of longest dimension
    NewSize = nan(MaxLen);
    for i = 1:size(NewSize,1)
        for j = 1:size(NewSize,2)
            if i <= size(LastStep,1) && j <= size(LastStep,2)
                NewSize(i,j) = LastStep(i,j);
            end
        end
    end
    %NewSize(1:numel(LastStep)) = LastStep;
    LastStep = NewSize;

    latDiff = lat(2)-lat(1);
    lonDiff = lon(2)-lon(1);
    if latDiff<0
        startlat = max(lat);
    else
        startlat = min(lat);
    end
    if lonDiff<0
        startlon = max(lon);
    else
        startlon = min(lon);
    end
    stoplat = (MaxLen-1)*latDiff + startlat;
    stoplon = (MaxLen-1)*lonDiff + startlon;
    
    lat = startlat:latDiff:stoplat;
    lon = startlon:lonDiff:stoplon;
    lat = lat';
    lon = lon';
else
    lonBB = lon;
    latBB = lat;
end

%% Work out coordinates for bounding box and fine bounding box
% Extract bounds of the full extent
LatMax = max(lat(:));
LatMin = min(lat(:));
LonMax = max(lon(:));
LonMin = min(lon(:));

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
Extra = '';
if SS == 'y'

    % Takes into account the coherence mask 
    % WITH EDITABLE THRESHOLD FOR RETAINING DOWNSAMPLED PIXELS BASED ON PROPORTION OF NaN VALUES

    if Options.MaskVolcs ==1
        Extra = append(Extra,'_MaskVolc');
        % Create buffer around other volcanoes in the scene
        Phase = CreateBufferGVP(Phase, lat, lon, VolcName, rad2m);
    end

    if Options.SlidingWindow ==1
        Location = SlidingWindowClustering(Phase, TS_Files);
    else
        Location = [];
    end

    if Options.ICA ==1
        Extra = append(Extra,'_ICA');

        % Use ICA to denoise signal before Otsu thresholding
        [~, ~, ICAs_Reconstructed] = DoICA2(TS_Files, Phase, Location, Options);

        if Options.ICA ==1 % Accounts for if ICA Fails (DoICA2 function sets Options.ICA=0)
            LastStepICA = ICAs_Reconstructed(:, :, end) - ICAs_Reconstructed(:, :, 2);
            LastStepICA = LastStepICA./1000;
            Phase = double(((4*pi)*LastStepICA)/wavelength);
            Phase = -1*Phase; %-ive as Phase is positive when away from the satellite
        end
    end

    FullResPhase = Phase;
    FullResLat = lat;
    FullResLon = lon;
    
    % Define NaN threshold to keep or ignore downsampled pixel values
    NaN_Threshold = 0.5;
    
    % Define image dimensions
    n = size(Phase, 1); % Number of rows
    m = size(Phase, 2); % Number of columns

    % Find bounding box using Otsu's thresholding and extract spatial parameters of signal
    if Options.ICA ==1
        if nonSquare ==1
            % If non-square, added NaN rows/cols to make the matrix square will confuse Otsu, so use original data
            [FineBoundingBox, Image, OtsuFigure, SignalLocation, largest_component_mask] = ExtractSignalBoundingBoxCheck(BB_Shape, OrigLastStep, 5, VolcName, SpatialRes, Origlon, Origlat);
        else
            LastStepIC = Phase.*rad2m;
            LastStepIC = -1*LastStepIC;
            % Incorporate ICA outputs into Otsu thresholding
            %[FineBoundingBox, Image, OtsuFigure, SignalLocation, largest_component_mask] = ExtractSignalBoundingBoxCheck(BB_Shape, LastStepIC, 5, VolcName, SpatialRes, lonBB, latBB);
            [FineBoundingBox, Image, OtsuFigure, SignalLocation, largest_component_mask] = ExtractSignalBoundingBoxCheckLocation25(BB_Shape, LastStepIC, 5, VolcName, SpatialRes, lonBB, latBB,Location,Options);
        end    
    else
        if nonSquare ==1
            [FineBoundingBox, Image, OtsuFigure, SignalLocation, largest_component_mask] = ExtractSignalBoundingBoxCheck(BB_Shape, OrigLastStep, 5, VolcName, SpatialRes, Origlon, Origlat);
        else
            [FineBoundingBox, Image, OtsuFigure, SignalLocation, largest_component_mask] = ExtractSignalBoundingBoxCheck(BB_Shape, LastStep, 5, VolcName, SpatialRes, lonBB, latBB);
        end
    end
    
    
    if SignalLocation.Flag ==1
        if ~exist([pwd,'/ForReview/',VolcName],'dir')
            mkdir([pwd,'/ForReview'],VolcName)
            addpath([pwd,'/ForReview/',VolcName])
        end

        OtsuGrayFilename = strcat(pwd,'/ForReview/',VolcName,'/',VolcName,'GrayIfg','_Shape_',num2str(BB_Shape),Extra,'.png');
        OtsuFigFilename = strcat(pwd,'/ForReview/',VolcName,'/',VolcName,'OtsuFig','_Shape_',num2str(BB_Shape),Extra,'.png');
        imwrite(uint8(Image),OtsuGrayFilename);
        saveas(OtsuFigure,OtsuFigFilename);

        save([pwd,'/ForReview/',VolcName,'/',VolcName,'_Shape_',num2str(BB_Shape),Extra,'BoundingBox.mat'],'FineBoundingBox','BoundingBox','BoundingBoxPoly','largest_component_mask');
        save([pwd,'/ForReview/',VolcName,'/',VolcName,'_Shape_',num2str(BB_Shape),Extra,'_SignalLocation.mat'],'SignalLocation');

        if Options.SkipFlagged ==1
            Filename = []; % Empty output variables
            FineBoundingBox = [];
            loadedData = [];
            nObs_SS = [];
            TempParams = [];
            return
        end
    end

    % Extract temporal parameters of the signal
    if Options.ICA ==1
        if Options.SlidingWindow ==1
            SignalLocation.Pix = Location.pix;
        end
        ICAs_Reconstructed = ICAs_Reconstructed./1000; % Convert from mm to m
        TempParams = FitTimeseriesFunctions(ICAs_Reconstructed, days, FileInfo, SignalLocation.Pix, VolcName);
    else
        if Options.SlidingWindow ==1
            SignalLocation.Pix = Location.pix;
        end
        TempParams = FitTimeseriesFunctions(LOS, days, FileInfo, SignalLocation.Pix, VolcName);
    end

    if TempParams.Flag ==1
        % Save temporal parameters for review if the timeseries fit fails
        if ~exist([pwd,'/ForReview/',VolcName],'dir')
            mkdir([pwd,'/ForReview'],VolcName)
            addpath([pwd,'/ForReview/',VolcName])
        end
    
        save([pwd,'/ForReview/',VolcName,'/',VolcName,Extra,'_TempParams.mat'],'TempParams');
        TempFilename = strcat(pwd,'/ForReview/',VolcName,'/',VolcName,Extra,'_TempFigure.png');
        saveas(TempParams.Figure,TempFilename);
    end

    % Unique identifier based on parameters
    SS_Style = ['BB_CF_Avg_Pgon_',num2str(geo.SS_Factor),'_',num2str(geo.SS_FactorF),'_',num2str(NaN_Threshold)];
    
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
            if mod(i,geo.SS_Factor) ==0 && mod(j,geo.SS_Factor) ==0
                %Get values and indexes of area
                LonAvg = mean(lon2(i-(geo.SS_Factor-1):i));
                LatAvg = mean(lat2(j-(geo.SS_Factor-1):j));
    
                LonIdx = round(mean([i-(geo.SS_Factor-1),i]));
                LatIdx = round(mean([j-(geo.SS_Factor-1),j]));
    
                downsampledLocs(LonIdx,LatIdx) = 1;
    
                %Get Phase values
                area = Phase(i-(geo.SS_Factor-1):i,j-(geo.SS_Factor-1):j);
    
                if nnz(area)/numel(area) > NaN_Threshold
                    downsampledImg(LonIdx,LatIdx) = mean(nonzeros(area(:)));
                else
                    downsampledImg(LonIdx,LatIdx) = NaN;
                end
            end
    
            if mod(i,geo.SS_FactorF) ==0 && mod(j,geo.SS_FactorF) ==0
                %Get values and indexes of area
                LonAvg = mean(lon2(i-(geo.SS_FactorF-1):i));
                LatAvg = mean(lat2(j-(geo.SS_FactorF-1):j));
    
                LonIdx = round(mean([i-(geo.SS_FactorF-1),i]));
                LatIdx = round(mean([j-(geo.SS_FactorF-1),j]));
    
                downsampledLocsFine(LonIdx,LatIdx) = 1;
    
                %Get Phase values
                area = Phase(i-(geo.SS_FactorF-1):i,j-(geo.SS_FactorF-1):j);
    
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

    if Options.MaskVolcs ==1
        SS_Style = append(SS_Style,'_MaskVolc');
    end

    if Options.ICA ==1
        SS_Style = append(SS_Style,'_ICA');
    end

%% No subsampling
elseif SS == 'n'
    % Initialise empty output variables
    FineBoundingBox = [];
    SignalLocation = [];
    nObs_SS = [];
    TempParams = [];

    loadedData.Lon = reshape(lon,[],1);
    loadedData.Lat = reshape(lat,[],1);
    Phase = reshape(Phase,[],1);
    loadedData.Phase = Phase;

    SS_Style = 'No_SS';
    
    if Options.MaskVolcs ==1
        SS_Style = append(SS_Style,'_MaskVolc');
    end

    if Options.ICA ==1
        SS_Style = append(SS_Style,'_ICA');
    end
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

Filename = strcat(pwd,'/InputData/',VolcanoName{1},'_',Frame,'_',SS_Style,'_.mat')
save(Filename,'Lon','Lat','Phase','Inc','Heading');

%% Save outputs from Otsu thresholding

if SS == 'y'
    disp('Creating and saving downsampling figures')
    % Save earlier figures
    OtsuGrayFilename = strcat(pwd,'/Bounding_Boxes/',VolcName,'GrayIfg','_Shape_',num2str(BB_Shape),Extra,'.png');
    OtsuFigFilename = strcat(pwd,'/Bounding_Boxes/',VolcName,'OtsuFig','_Shape_',num2str(BB_Shape),Extra,'.png');
    imwrite(uint8(Image),OtsuGrayFilename);
    saveas(OtsuFigure,OtsuFigFilename);

    % Create Otsu overview figure
    figure()
    T = tiledlayout(1,2,"TileSpacing","none","Padding","compact");
    ax1 = nexttile;
    h = imagesc(-1*rad2m.*FullResPhase);
    axis square
    box(ax1,'on')
    colormap(ax1,jet)
    c = 0.1;
    caxis([-c c])
    set(h, 'AlphaData',FullResPhase~=0)
    hold on

    plot(FineBoundingBox,"LineStyle","--",FaceAlpha=0,LineWidth=2)
    xticklabels({''})
    yticklabels({''})
    set(gca,'XTick',[])
    set(gca,'YTick',[])
    hold off
    
    ax2 = nexttile;
    scatter(loadedData.Lon,loadedData.Lat,10,-1*rad2m.*loadedData.Phase,'filled','square');
    axis square
    xlim([min(FullResLon(:)),max(FullResLon(:))]);
    ylim([min(FullResLat(:)),max(FullResLat(:))]);
    box(ax2,'on')
    colormap(ax2,jet)
    caxis([-c c])
    c = colorbar(gca,"eastoutside");
    c.Label.String = 'LOS Displacement (m)';
    xticklabels({''})
    yticklabels({''})
    set(gca,'XTick',[])
    set(gca,'YTick',[])
    hold off

    OtsuDSFigFilename = strcat(pwd,'/Bounding_Boxes/',VolcName,'OtsuDSFig','_Shape_',num2str(BB_Shape),Extra,'.png');
    saveas(gcf,OtsuDSFigFilename);

    save([pwd,'/Bounding_Boxes/',VolcName,'_Shape_TEST',num2str(BB_Shape),Extra,'BoundingBox.mat'],'FineBoundingBox','BoundingBox','BoundingBoxPoly','largest_component_mask');
    save([pwd,'/Spatial_Parameters/',VolcName,'_Shape_',num2str(BB_Shape),Extra,'_SignalLocation.mat'],'SignalLocation');
    save([pwd,'/nObs/',VolcName,'_',SS_Style,'_nOBS.mat'],'nObs_SS','nObs_Raw');
end

end