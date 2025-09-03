function SignalLocationGBIS = SignalLocationFromResults(invResFile, VolcName)
% Script to extract Lat/Lon from GBIS locations and compare to volcano location

if ~exist([pwd,'/Spatial_Parameters'],'dir')
    mkdir(pwd,'Spatial_Parameters')
    addpath([pwd,'/Spatial_Parameters'])
end

% Load results and GVP volcanoes
load(invResFile);
GVP_List = readtable([pwd,'/GBIS/GVP/','GVP_Volcano_List_HoloceneXLS.xls']);

% Verify model names for multi-source models
if length(invpar.model)>1
    numM=0;
    modelTypes = fieldnames(modelInput);

    for i = 1:length(invpar.model)
        for j = 1:length(modelTypes)
            if contains(modelTypes{j},invpar.model{i},'IgnoreCase',true)
                numM = numM + 1;
                ModelName{numM} = modelTypes{j};
            end
        end
    end

else
    numM=1;
end

for a = 1:numM % Where there is more than one model, average the location

    % Load optimal x and y locations
    nParam = length(invResults.model.optimal);
    for k = 1:nParam-1
        if contains(model.parName{k},'X','IgnoreCase',false)
            XLocation = invResults.model.optimal(k);
        elseif contains(model.parName{k},'Y','IgnoreCase',false)
            YLocation = invResults.model.optimal(k);
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

    if numM==1
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
    
        SignalLocationGBIS.offsetKm = deg2km(SignalLocationGBIS.offsetKm);
        SignalLocationGBIS.LatLon = [Lat,Lon];
    else
        Lats(a) = Lat;
        Lons(a) = Lon;
    end

    if numM >1 && a==numM
        Lat = mean(Lats);
        Lon = mean(Lons);

        try
            % Use matching volcano name from GVP
            [SignalLocationGBIS.offsetKm,SignalLocationGBIS.bearingDeg] = distance(VolcLatLon(1),VolcLatLon(2),Lat,Lon);
        catch
            % Find location of closest volcano to the signal centre
            [Distances, Bearings] = distance(GVP_List.Latitude,GVP_List.Longitude,Lat,Lon);
            [SignalLocationGBIS.offsetKm, Cidx] = min(Distances);
            SignalLocationGBIS.bearingDeg = Bearings(Cidx);
        end
        SignalLocationGBIS.offsetKm = deg2km(SignalLocationGBIS.offsetKm);
        SignalLocationGBIS.LatLon = [Lat,Lon];
    end
end
end