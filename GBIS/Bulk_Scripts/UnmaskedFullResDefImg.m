function Filename_Raw = UnmaskedFullResDefImg(Phase,lon,lat,FineBoundingBox,head,incidence,VolcName,Frame,Options)
    % Ben Ireland, July 2025
    % Convert unmasked fullres InSAR map into GBIS format

    % Work out coordinates for bounding box and fine bounding box
    % Extract bounds of the full extent
    LatMax = max(lat(:));
    LatMin = min(lat(:));
    LonMax = max(lon(:));
    LonMin = min(lon(:));

    % Make polyshape from big bounding box (covering the full extent of the
    % image)
    FullResPhase = Phase;
    FullResLat = lat;
    FullResLon = lon;

    VolcanoName = regexp(VolcName,'\S*(?=_[0-9AD]{4}_)','match');

    % Flatten arrays
    loadedData.Lon = reshape(lon,[],1);
    loadedData.Lat = reshape(lat,[],1);
    Phase = reshape(Phase,[],1);
    loadedData.Phase = Phase;

    % Remove null values
    Null = (loadedData.Phase~=0) & ~isnan(loadedData.Phase);
    loadedData.FullPhase = loadedData.Phase;
    loadedData.FullLat = loadedData.Lat;
    loadedData.FullLon = loadedData.Lon;
    loadedData.Phase = loadedData.Phase(Null);
    loadedData.Lat = loadedData.Lat(Null);
    loadedData.Lon = loadedData.Lon(Null);

    % Prep viewing geometry
    loadedData.Heading = (zeros(size(loadedData.Phase)))+head;
    loadedData.Inc = (zeros(size(loadedData.Phase)))+incidence;

    %Manually remove offset (change ref pixel)
    if Options.Offset ==1
        % Apply manual offset
        [loadedData.Phase,loadedData.Offset] = RemovePhaseOffset(FineBoundingBox,loadedData);
    else
        loadedData.Offset = [];
    end

    % Make output file
    SS_Style = 'No_SS';
    if Options.MaskVolcs ==1
        SS_Style = append(SS_Style,'_MaskVolc');
    end

    if Options.ICA ==1
        SS_Style = append(SS_Style,'_ICA');
    end

    % Write output file
    Lon = loadedData.Lon;
    Lat = loadedData.Lat;
    Phase = loadedData.Phase;
    Inc = loadedData.Inc;
    Heading = loadedData.Heading;
    Offset = loadedData.Offset;

    Filename_Raw = char(strcat(pwd,'/InputData/',VolcanoName{1},'_',Frame,'_',SS_Style,'_',Options.RunID,'_UnMasked.mat'));
    save(Filename_Raw,'Lon','Lat','Phase','Inc','Heading','Offset','FineBoundingBox','FullResPhase','FullResLat','FullResLon');
end