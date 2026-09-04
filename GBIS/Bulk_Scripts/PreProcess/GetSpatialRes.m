function SpatialRes = GetSpatialRes(lat,lon)
    % Ben Ireland, University of Bristol, Sept 2026
    % Get approx spatial res from lat and lon spacing (assumes pixels are square)

    % X separation
    xSep = llh2local([lon(1,2);lat(1,1);0],[lon(1,1);lat(1,1);0]);
    xSep = abs(xSep(1)*1000); % Convert to m from km
    % Y separation
    ySep = llh2local([lon(1,1);lat(2,1);0],[lon(1,1);lat(1,1);0]);
    ySep = abs(ySep(2)*1000); % Convert to m from km

    % With square pixels, xSep and ySep should be very close or identical in size.
    % xSep and ySep may show slight differences at different latitudes, so take average of these in that case
    SpatialRes = (xSep + ySep)/2;
end