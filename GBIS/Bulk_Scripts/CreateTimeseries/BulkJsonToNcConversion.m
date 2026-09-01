clear variables; close all;
Files = dir('/folder/*.json');
outfolder = 'outfolder';
% Options
mask = 1; % Apply mask from LiCSAR volcano portal (land and coh<0.05)

cropTime.do = 1; % Crop timeseries in time (1) or not (0)
cropTime.start = 20140101; % Format yyyyMMdd
cropTime.end = 20241201; % Format yyyyMMdd

cohMask.do = 1; % Apply mask based on average coherence (1) or not (0)
cohMask.thresh = 0.3; % Threshold coherence below which to mask

fig = 1; % Plot figures of cumulative displacment?

for k = 1:length(Files)
    disp(['File ',num2str(k),' out of ',num2str(length(Files))])
    file = strcat(Files(k).folder,'/',Files(k).name);
    [NC_filename, DEM_Filename] = LiCSPortalJsonToNC(file,outfolder,mask,cropTime,cohMask,fig);
end