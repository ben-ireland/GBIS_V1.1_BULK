function [OffsetPhase,OffsetValue] = RemovePhaseOffset(FineBoundingBox,loadedData)
    
    % Find phase values in far-field
    in = isinterior(FineBoundingBox,loadedData.Lon,loadedData.Lat);
    ixSubset = find(in == 0);
    subset = loadedData.Phase(ixSubset);

    % Find and remove offset
    OffsetValue = mean(subset,'omitnan');
    OffsetPhase = loadedData.Phase - OffsetValue;
end