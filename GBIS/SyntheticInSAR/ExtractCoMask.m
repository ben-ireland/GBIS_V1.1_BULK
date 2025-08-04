function [CoherenceMask] = ExtractCoMask(TS_Files)

TS_Filename = strcat(TS_Files.folder,'/',TS_Files.name);

%Read .nc file (time series) and extract the final time step
days = ncread(TS_Filename,'time');
LOS = ncread(TS_Filename,'DATA');
lat = ncread(TS_Filename,'lat');
lon = ncread(TS_Filename,'lon');
FileInfo = ncinfo(TS_Filename,'time');
LOS = permute(LOS,[2 1 3]);

LastStep = squeeze(LOS(:,:,end));
CoherenceMask = (LastStep~=0);
end