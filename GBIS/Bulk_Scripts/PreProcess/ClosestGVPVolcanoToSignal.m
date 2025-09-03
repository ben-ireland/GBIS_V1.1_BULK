function [VolcanoOfSignal, IfgVolcano, SignalLocation] = ClosestGVPVolcanoToSignal(lon,lat,Polygon,VolcName,SpatialRes)

% Load GVP table and extract locations and names
GVP_List = readtable([pwd,'/GBIS/GVP/','GVP_Volcano_List_HoloceneXLS.xls']);

% Extract name of closest volcano to the centrepoint of the
% interferogram and compare this to the name of the interferogram (should be the same)
CentrePointLL = [lon(round(length(lon)/2)), lat(round(length(lat)/2))];
data.LonDiff = table2array(GVP_List(:,10)) - CentrePointLL(1);
data.LatDiff = table2array(GVP_List(:,9)) - CentrePointLL(2);
data.Distance = sqrt(data.LatDiff.^2 + data.LonDiff.^2);

% Find the row with the minimum distance
[~, minIdx] = min(data.Distance);

% Corresponding Volcano Name and check if this matches filename
IfgVolcano = char(GVP_List.VolcanoName(minIdx));

if ~contains(VolcName,IfgVolcano,'IgnoreCase',true)
    disp('GVP name and volcano name do not match')
end

% Find closest volcano to the centroid of the signal i.e. Otsu polygon
% (before buffering)
[x,y] = centroid(Polygon);
PolyCentLL = [lon(round(x)), lat(round(y))]; % Lat indexed differently because the elements are in descending order
Pdata.LonDiff = table2array(GVP_List(:,10)) - PolyCentLL(1);
Pdata.LatDiff = table2array(GVP_List(:,9)) - PolyCentLL(2);
Pdata.Distance = sqrt(Pdata.LatDiff.^2 + Pdata.LonDiff.^2);

% Find the row with the minimum distance
[~, PminIdx] = min(Pdata.Distance);

% Corresponding Volcano Name to the signal and check if this matches
% volcano closest to the centre of the ifg
VolcanoOfSignal = char(GVP_List.VolcanoName(PminIdx));

% Find offset distance and bearing of the signal (relative to GVP location)
OffsetX = x - (length(lon)/2); % Different to Y offset to account for the lat values being indexed in descending order with ascending index (may need changing)
%OffsetX = (length(lon)/2) - x;
OffsetY = (length(lat)/2) - y;

% Convert signal offset direction to 0-360 degree bearings
OffsetBearing = atand(OffsetX./OffsetY);

if OffsetY >=0 && OffsetX >=0
    OffsetBearing = OffsetBearing; 
elseif OffsetY <0 && OffsetX >=0
    OffsetBearing = OffsetBearing + 180;
elseif OffsetY >0 && OffsetX <=0
    OffsetBearing = OffsetBearing + 360;
elseif OffsetY <=0 && OffsetX <0
    OffsetBearing = OffsetBearing + 180;
end

% Save locational information
SignalLocation.OffsetBearing = OffsetBearing;
SignalLocation.OffsetDistanceKm = (sqrt(OffsetX.^2 + OffsetY.^2))*(SpatialRes/1000);
SignalLocation.LL = PolyCentLL;
SignalLocation.CentPix = [round(x), round(y)];