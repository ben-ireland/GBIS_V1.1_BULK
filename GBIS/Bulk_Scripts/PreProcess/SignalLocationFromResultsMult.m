function SignalLocationGBIS = SignalLocationFromResultsMult(invResFile, VolcName)
% Script to extract Lat/Lon from GBIS locations and compare to volcano location

if ~exist([pwd,'/Spatial_Parameters'],'dir')
    mkdir(pwd,'Spatial_Parameters')
    addpath([pwd,'/Spatial_Parameters'])
end

% Load results and GVP volcanoes
load(invResFile);

GVP_List = readtable([pwd,'/GBIS/GVP/','GVP_Volcano_List_HoloceneXLS.xls']);

% Load optimal x and y locations
nParam = length(invResults.optimalmodel{1});
for i = 1:length(invResults.optimalmodel)
    for k = 1:nParam-1
        if contains(invpar.model{i},'SILL')
            if contains(model.parName{k},'X','IgnoreCase',false)
                XLocation = invResults.optimalmodel{i}(k+1); % +1 sometimes needed and sometimes not?
            elseif contains(model.parName{k},'Y','IgnoreCase',false)
                YLocation = invResults.optimalmodel{i}(k+1);
            end
        else
            if contains(model.parName{k},'X','IgnoreCase',false)
                XLocation = invResults.optimalmodel{i}(k); % +1 sometimes needed and sometimes not?
            elseif contains(model.parName{k},'Y','IgnoreCase',false)
                YLocation = invResults.optimalmodel{i}(k);
            end
        end
    end

    % Find where these lie in the local coordinate system (relative)
    for k = 1:length(insar)
        XIdx(k) = knnsearch(insar{k}.obs_raw(2,:)',XLocation,'K',1,'IncludeTies',false);
        YIdx(k) = knnsearch(insar{k}.obs_raw(3,:)',YLocation,'K',1,'IncludeTies',false);
        ll = local2llh(insar{k}.obs_raw(2:3,:)./1000,geo.referencePoint); % ll(1,:) = Lon, ll(2,:) = Lat
        Lon(k) = ll(1,XIdx(k)); % All k values of lat and lon should match
        Lat(k) = ll(2,YIdx(k));
    end

    % Check results make sense
    if length(insar)>1
        if sum(ismember(Lat(1),Lat))<length(insar)-1 || sum(ismember(Lon(1),Lon))<length(insar)-1
            disp('Error in locating the signal - see function for more info')
            return
        end
    end

    Lat = Lat(1);
    Lon = Lon(1);

    for k = 1:size(GVP_List,1)
        if contains(VolcName,GVP_List.VolcanoName{k},'IgnoreCase',true)
            VolcLatLon = [GVP_List.Latitude(k), GVP_List.Longitude(k)];
        end
    end

    % Try in case of volcano name being slightly different to that on the GVP and COMET e.g. Alutu and Aluto
    VolcName2 = replace(VolcName,'_',' ');
    if ~exist('VolcLatLon')
        for k = 1:size(GVP_List,1)
            if contains(VolcName2,GVP_List.VolcanoName{k}(1:end-1),'IgnoreCase',true)
                VolcLatLon = [GVP_List.Latitude(k), GVP_List.Longitude(k)];
            end
        end
    end

    % Find offset distance and bearing of the signal (relative to GVP location)
    try
        % Use matching volcano name from GVP
        [SignalLocationGBIS.offsetKm,SignalLocationGBIS.bearingDeg] = distance(VolcLatLon(1),VolcLatLon(2),Lat,Lon);
    catch
        % Find location of closest volcano to the signal centre
        [Distances, Bearings] = distance(GVP_List.Latitude,GVP_List.Longitude,Lat,Lon);
        [SignalLocationGBIS.offsetKm, Cidx] = min(Distances);
        SignalLocationGBIS.bearingDeg = Bearings(Cidx);
    end
    SignalLocationGBIS.bearingDeg(i,:) = SignalLocationGBIS.bearingDeg;
    SignalLocationGBIS.offsetKm(i,:) = deg2km(SignalLocationGBIS.offsetKm);
    SignalLocationGBIS.LatLon(i,:) = [Lat,Lon];
end


end