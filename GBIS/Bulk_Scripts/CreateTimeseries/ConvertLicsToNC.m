function filename = ConvertLicsToNC(VolcName,Frame,TS_File)
% VolcName ='Nabro';
% Frame ='014A_07688_131313';
% TS_File = 'LiCSBAS_Nabro/TS_GEOCml1clip/cum_filt.h5';

ImDates = h5read(TS_File,'/imdates');
DatesDT = datetime(ImDates,'ConvertFrom','yyyymmdd');
days_ = daysact(DatesDT(1),DatesDT);
LOS = h5read(TS_File,'/cum');
cLat = h5read(TS_File,'/corner_lat');
cLon = h5read(TS_File,'/corner_lon');
postLat = h5read(TS_File,'/post_lat');
postLon = h5read(TS_File,'/post_lon');
endLat = (size(LOS,1)-1)*postLat + cLat;
endLon = (size(LOS,1)-1)*postLon + cLon;
lat = [cLat:postLat:endLat];
lon = [cLon:postLon:endLon];
lon = lon';
lat = lat'; % Transpose to work with the format of the rest of the script
LOS = LOS./1000; % Convert LOS from mm to m

output_name = strcat(VolcName,'_',Frame);

filename = Save_NC_Timeseries(output_name,DatesDT,days_,lon,lat,LOS);
