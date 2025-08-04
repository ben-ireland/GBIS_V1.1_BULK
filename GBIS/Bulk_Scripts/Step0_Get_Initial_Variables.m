function [Phase, lat, lon, VolcName, days, FileInfo, LOS, head, incidence, Metadata] = Step0_Get_Initial_Variables(TS_Files, inputFileName, Options)

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
    eval(textLine);
    textLine = fgetl(inputFileID);
end

% Load Sentinel 1 datacube
%Extract frame and generate LiCSAR download link

if endsWith(TS_Files.name,'.nc')
    Frame = regexp(TS_Files.name, '(?<=_)[0-9AD]{4}_[0-9]{5}_[0-9]{6}(?=.nc)','match');
    FrameNum = regexp(Frame,'[1-9]{1}[0-9]{2}(?=[AD])|(?<=0)[0-9]{2}(?=[AD])','match');
elseif endsWith(TS_Files.name,'.h5')
    Frame1 = extractAfter(TS_Files.folder,'SampleData/');
    Frame = extractBetween(Frame1,'/','/TS_GEOC');
    FrameNum = regexp(Frame,'[1-9]{1}[0-9]{2}(?=[AD])|(?<=0)[0-9]{2}(?=[AD])','match');
    VolcName = extractBefore(Frame1,Frame{1});
    VolcName = lower(VolcName);
    VolcName = strcat(VolcName(1:end-1),'_',Frame{1});
elseif endsWith(TS_Files.name,'.tif')
    Frame = regexp(TS_Files.name, '(?<=_)[0-9AD]{4}_[0-9]{5}_[0-9]{6}(?=.tif)','match');
    FrameNum = regexp(Frame,'[1-9]{1}[0-9]{2}(?=[AD])|(?<=0)[0-9]{2}(?=[AD])','match');
end

TrackID = Frame{1}(4);
if TrackID == 'D'
    Track = 'Descending';
elseif TrackID == 'A'
    Track = 'Ascending';
end
    
if startsWith(FrameNum{1},'0')
    FrameNumMat = cell2mat(FrameNum{1});
    FrameNum{1} = FrameNumMat(2:end);
end
 
%VolcanoName = regexp(TS_Files.name,'\S*(?=_[0-9AD]{4}_)','match');

Metadata.TrackID = TrackID;
Metadata.Track = Track;
Metadata.Frame = Frame;
Metadata.FrameNum = FrameNum;

%% Load Sentinel 1 datacube
if endsWith(TS_Files.name,'.nc')
    if Options.Auto_Angles ==1
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

    if Options.CropTS == 1
        LastStep = LOS(:,:,Options.CropTS_end) - LOS(:,:,Options.CropTS_start);
        LOS = LOS(:,:,Options.CropTS_start:Options.CropTS_end);
        days = days(Options.CropTS_start:Options.CropTS_end);
    else
        if Options.IgnoreLastStep ==1
            LastStep = LOS(:,:,end-1) - LOS(:,:,2);
        else
            LastStep = LOS(:,:,end);
        end
    end

    if Options.CropImg == 1
        LastStep = LastStep(Options.CropImgY,Options.CropImgX);
    end

elseif endsWith(TS_Files.name, '.h5')
    %VolcName = char(extractBetween(TS_Files.folder,'ClippedResults/','/'));
    if Options.Auto_Angles ==1
        %Extract frame and generate LiCSAR download link
        %Frame = extractBetween(TS_Files.folder,[VolcName,'/'],'/TS_GEOCml1clip');
        %FrameNum = regexp(Frame,'[1-9]{1}[0-9]{2}(?=[AD])|(?<=0)[0-9]{2}(?=[AD])','match');
        %FrameNum = FrameNum;
        if isfile(strcat(pwd,'/LiCSMetadata/',Frame,'_Metadata.mat'))
            file = strcat(pwd,'/LiCSMetadata/',Frame,'_Metadata.mat');
            load(file{1});
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

            save([pwd,'/LiCSMetadata/',Frame,'_Metadata.mat'],"incidence","head");
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

    if Options.CropTS == 1
        if Options.CropTS_start ==1 && Options.CropTS_end ==length(days)
            if Options.IgnoreLastStep ==1
                LastStep = LOS(:,:,end-1) - LOS(:,:,2); % Crop the first and last timeseries step to reduce noise when there is not a sigmoidal trend
            else
                LastStep = LOS(:,:,end);
            end

        else
            LastStep = LOS(:,:,Options.CropTS_end) - LOS(:,:,Options.CropTS_start);
            LOS = LOS(:,:,Options.CropTS_start:Options.CropTS_end);
            days = days(Options.CropTS_start:Options.CropTS_end);
        end
    else
        LastStep = LOS(:,:,end-1) - LOS(:,:,2);
    end

    if Options.CropImg == 1
        LastStep = LastStep(Options.CropImgY,Options.CropImgX);
    end
    VolcName = TS_Files.name(1:end-3);
elseif endsWith(TS_Files.name, '.tif')
    % Load single IFG data
    % Set empty output variables
    days = [];
    FileInfo = [];
    LOS = [];
    VolcName = TS_Files.name(1:end-4);

    TS_Filename = strcat(TS_Files.folder,'/',TS_Files.name);
    [LastStep, R] = readgeoraster(TS_Filename);
    LastStep = -LastStep; % Convention needed for GBIS conversions
    try
        lat = R.LatitudeLimits(1):R.CellExtentInLatitude:R.LatitudeLimits(2)-R.CellExtentInLatitude;
        lon = R.LongitudeLimits(1):R.CellExtentInLongitude:R.LongitudeLimits(2)-R.CellExtentInLongitude;
    catch
        lat = R.LatitudeLimits(1):R.SampleSpacingInLatitude:R.LatitudeLimits(2)-R.SampleSpacingInLatitude;
        lon = R.LongitudeLimits(1):R.SampleSpacingInLongitude:R.LongitudeLimits(2)-R.SampleSpacingInLongitude;
    end

    if length(lat) ~= size(LastStep,2) & length(lon) ~= size(LastStep,1)
        disp('Lat/Lon size do not match - trying alternative')
        try
            lat = R.LatitudeLimits(1):R.CellExtentInLatitude:R.LatitudeLimits(2);
            lon = R.LongitudeLimits(1):R.CellExtentInLongitude:R.LongitudeLimits(2);
        catch
            lat = R.LatitudeLimits(1):R.SampleSpacingInLatitude:R.LatitudeLimits(2);
            lon = R.LongitudeLimits(1):R.SampleSpacingInLongitude:R.LongitudeLimits(2);
        end
    end

    if length(lat) ~= size(LastStep,2) & length(lon) ~= size(LastStep,1)
        disp('Lat/Lon size still do not match - exiting')
        disp('Check function')
        return
    end

    lat = lat'; 
    lon = lon';
    LastStep = flipud(LastStep);
    
    if Options.CropImg == 1
        LastStep = LastStep(Options.CropImgY,Options.CropImgX);
    end

    % Assumes Last Step is in radians and coverts to m
    rad2m = Options.WavelengthM./(4.*pi);
    LastStep = LastStep.*rad2m;

    % Get incidence and heading angles
    if Options.Auto_Angles ==1
        %Extract frame and generate LiCSAR download link

        if isfile(strcat(pwd,'/LiCSMetadata/',Frame,'_Metadata.mat'))
            file = strcat(pwd,'/LiCSMetadata/',Frame,'_Metadata.mat');
            load(file{1});
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

            save([pwd,'/LiCSMetadata/',Frame,'_Metadata.mat'],"incidence","head");
        end
    else
        head = input('Enter the heading angle for the Sentinel 1 frame of interest');
        incidence = input('Enter the average incidence angle for the Sentinel 1 frame of interest');
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
colormap(flipud(cbrewer2('RdBu', 256)))
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
Phase = double(((4*pi)*LastStep)/Options.WavelengthM);
Phase = -1*Phase; %-ive as Phase is positive when away from the satellite

%Create grids of lat and lon
lat = repmat(lat,1,(length(lat)));
lon = lon.';
lon = repmat(lon,(length(lon)),1);

if Options.IgnoreLastStep ==1
    OriginalDatFilename = strcat(pwd,'/OriginalData/',VolcName,'NoLast.mat');
    OriginalImgFilename = strcat(pwd,'/OriginalData/',VolcName,'_Image_',num2str(size(LastStep,1)),'x',num2str(size(LastStep,2)),'NoLast.png');
else
    OriginalDatFilename = strcat(pwd,'/OriginalData/',VolcName,'WithLast.mat');
    OriginalImgFilename = strcat(pwd,'/OriginalData/',VolcName,'_Image_',num2str(size(LastStep,1)),'x',num2str(size(LastStep,2)),'WithLast.png');

end
save(OriginalDatFilename,'LastStep','lon','lat','head','incidence');

% Shift and normalise values to 0-255 for image
%LastStep255 = LastStep - min(LastStep(:));
%LastStep255 = (LastStep255/max(LastStep255(:)))*255;
%LastStep255(isnan(LastStep255)) = min(LastStep255(:));

imwrite(LastStep,OriginalImgFilename);
end