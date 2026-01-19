function [lon,lat,LastStep] = MakeSquare(lon,lat,LastStep)

    % Make data square if non-square
    disp('Input data is not square.. making it square by padding with NaNs')
    nonSquare = 1;
    Origlon = lon;
    Origlat = lat;
    OrigLastStep = LastStep;

    MaxLen = max(size(LastStep,1),size(LastStep,2)); % Find length of longest dimension
    NewSize = nan(MaxLen);
    for i = 1:size(NewSize,1)
        for j = 1:size(NewSize,2)
            if i <= size(LastStep,1) && j <= size(LastStep,2)
                NewSize(i,j) = LastStep(i,j);
            end
        end
    end
    %NewSize(1:numel(LastStep)) = LastStep;
    LastStep = NewSize;

    latDiff = lat(2)-lat(1);
    lonDiff = lon(2)-lon(1);
    if latDiff<0
        startlat = max(lat);
    else
        startlat = min(lat);
    end
    if lonDiff<0
        startlon = max(lon);
    else
        startlon = min(lon);
    end
    stoplat = (MaxLen-1)*latDiff + startlat;
    stoplon = (MaxLen-1)*lonDiff + startlon;

    lat = startlat:latDiff:stoplat;
    lon = startlon:lonDiff:stoplon;
    lat = lat';
    lon = lon';
end