clear variables; close all;
Files = dir('/folder/*.json');
outfolder = 'outfolder';
% Options
mask = 1; % Apply mask from LiCSAR volcano portal (land and coh<0.05) (can have some artefacts in)

SameTimeCrop = 1; % Crop to the same timeperiod for each file
SameLatCrop = 0; % Crop to same lat extent for each file
SameLonCrop = 0; % Crop to same lat extent for each file

cropTime.do = 1; % Crop timeseries in time (1) or not (0)
cropTime.start = 20140101; % Format yyyyMMdd
cropTime.end = 20241201; % Format yyyyMMdd

cropLat.do = 0; % Crop timeseries in Lat (1) or not (0), 1 value per file
cropLat.Start = 35.0; % In decimal degrees, 1 value per file if cropping mutliple files at once
cropLat.End = 35.5; % In decimal degrees, 1 value per file if cropping mutliple files at once

cropLon.do = 0; % Crop timeseries in Lon (1) or not (0), 1 value per file
cropLon.Start = 35.0; % In decimal degrees, 1 value per file if cropping mutliple files at once
cropLon.End = 35.5; % In decimal degrees, 1 value per file if cropping mutliple files at once
% Can only crop some files by either 1. Setting cropLat.Start/cropLat.End really wide e.g. [-90, 90] or 2. specifying cropLat.do ==1 for certain files only

cohMask.do = 1; % Apply additional masking based on coherence
cohMask.type = 2; % 1 = use a scalar threshold; 2 = remove a threshold percentile of low coherence areas
cohMask.thresh = 25; % if 1, thresh is between 0-1. if 2, thresh is a percentile 0-100. e.g. 25 will remove pixels with average coherence below 25th percentile of the image
cohMask.thresh2 = 0.4; % if cohMask.type ==3; make sure cohMask.thresh does not remove pixels with coherence > cohMask.thresh2

fig = 1; % Plot figures of cumulative displacment?

% Loop
for k = 1:length(Files)
    disp(['File ',num2str(k),' out of ',num2str(length(Files))])
    file = strcat(Files(k).folder,'/',Files(k).name);
    
    if any(cropTime.do) && SameTimeCrop == 0
        cropTime2 = cropTime(k);
    else
        cropTime2 = cropTime;
    end
    if any(cropLat.do) && SameLatCrop == 0
        cropLat2 = cropLat(k);
    else
        cropLat2 = cropLat;
    end
    if any(cropLon.do) && SameLonCrop == 0
        cropLon2 = cropLon(k);
    else
        cropLon2 = cropLon;
    end

    [NC_filename, DEM_Filename] = LiCSPortalJsonToNC(file,outfolder,mask,cropTime2,cropLat2,cropLon2,cohMask,fig);
end