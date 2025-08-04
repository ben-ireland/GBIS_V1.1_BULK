function SignalLocation = ManualSignalLocation(lon,lat,Location,SpatialRes)

% Find offset distance and bearing of the signal (relative to GVP location)
OffsetX = Location.pix(1) - (length(lon)/2); % Different to Y offset to account for the lat values being indexed in descending order with ascending index (may need changing)
%OffsetX = (length(lon)/2) - x;
OffsetY = (length(lat)/2) - Location.pix(2);

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
x = Location.pix(2);
y = Location.pix(1);

% Save locational information
SignalLocation.OffsetBearing = OffsetBearing;
SignalLocation.OffsetDistanceKm = (sqrt(OffsetX.^2 + OffsetY.^2))*(SpatialRes/1000);
SignalLocation.CentPix = [round(x), round(y)];
SignalLocation.Pix = [round(x), round(y)]; % Needed for later on when constructing the deformation catalogue
SignalLocation.Comment = 'Manual location';
SignalLocation.Flag = 0;