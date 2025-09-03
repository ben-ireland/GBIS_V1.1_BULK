function LastStep = RemoveGVPVolcsStep0(LastStep, lat, lon, Options)

% Ben Ireland, August 2025, University of Bristol
[lon,lat] = meshgrid(lon,lat);
lon = lon(1,:).';
lat = lat(:,1);

BufferDist = Options.Mask_BufferDist;
GVP_List = readtable([pwd,'/GBIS/GVP/','GVP_Volcano_List_HoloceneXLS.xls']);

% Extract name of closest volcano to the centrepoint of the
% interferogram and compare this to the name of the interferogram (should be the same)

CentrePointLL = [lon(round(length(lon)/2)), lat(round(length(lat)/2))];
data.LonDiff = table2array(GVP_List(:,10)) - CentrePointLL(1);
data.LatDiff = table2array(GVP_List(:,9)) - CentrePointLL(2);
data.Distance = sqrt(data.LatDiff.^2 + data.LonDiff.^2);

% Find the row with the minimum distance
[~, minIdx] = min(data.Distance);

disp('Removing data around other volcanoes in the frame')

% Extend lat and lon by the buffer amount to exclude pixels of volcanoes just outside the AOI
lonDiff = lon(2)-lon(1);
if sign(lonDiff) ==1
    minlonExt = min(lon) - (lonDiff*BufferDist);
    maxlonExt = max(lon) + (lonDiff*(BufferDist+1));
else
    minlonExt = min(lon) + (lonDiff*BufferDist);
    maxlonExt = max(lon) - (lonDiff*BufferDist);
end
lonExt = minlonExt:abs(lonDiff):maxlonExt;
lonExt = lonExt';

latDiff = lat(2)-lat(1);
if sign(latDiff) ==1
    minlatExt = min(lat) - (latDiff*BufferDist);
    maxlatExt = max(lat) + (latDiff*BufferDist);
else
    minlatExt = min(lat) + (latDiff*(BufferDist+1));
    maxlatExt = max(lat) - (latDiff*BufferDist);
end

if latDiff<0
    latExt = maxlatExt:latDiff:minlatExt;
    latExt = latExt';
else
    latExt = maxlatExt:-latDiff:minlatExt;
    latExt = latExt';
end

if size(latExt,1) > (size(lat,1) + 2*BufferDist)
    latExt = latExt(1:(size(lat,1) + 2*BufferDist));
end
if size(lonExt,1) > (size(lon,1) + 2*BufferDist)
    lonExt = lonExt(1:(size(lon,1) + 2*BufferDist));
end

% Extract all volcanoes within the ifg region (currently calculates on a normal and extended grid (for volcanoes just outside the frame) 
% but only the extended one is needed
iInBoxExt = find(GVP_List.Latitude < max(latExt) & GVP_List.Latitude > min(latExt)  & GVP_List.Longitude > min(lonExt) & GVP_List.Longitude < max(lonExt));
iInBoxExt(iInBoxExt==minIdx) = [];

AllVolcsExt = GVP_List.VolcanoName(iInBoxExt);
disp('Other volcanoes in the frame and just outside are:')
disp(char(AllVolcsExt))

% Create buffers around volcano
VolcPointsExt = [GVP_List.Latitude(iInBoxExt), GVP_List.Longitude(iInBoxExt)];

% Convert lat-lon to pixels (find closest lat and lon idx)
LatIdxsExt = knnsearch(latExt,VolcPointsExt(:,1));
LonIdxsExt = knnsearch(lonExt,VolcPointsExt(:,2));

VolcBuffersExt = polybuffer([LonIdxsExt,LatIdxsExt],'points',BufferDist);
[xExt, yExt] = boundary(VolcBuffersExt);

MaskVolcExt = mpoly2mask([xExt,yExt],[size(latExt,1),size(lonExt,1)]);
MaskVolcExtCrop = MaskVolcExt(BufferDist+1:end-BufferDist,BufferDist+1:end-BufferDist);

% Mask displacement data
LastStep(MaskVolcExtCrop) = NaN;
end