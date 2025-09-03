function Area = ExtractGBISSignalArea(invResFile,cutoff)
    % Ben Ireland, University of Bristol, September 2024

    load(invResFile);

    i=1; % First InSAR dataset (arbitrary)
    rawData = load(insar{i}.rawDataPath); % load *.mat file
    
%     Apply bounding box and remove data points outside the AOI
    
    iOutBox = find(rawData.Lon < geo.boundingBox(1) | rawData.Lon > geo.boundingBox(3) | rawData.Lat > geo.boundingBox(2) | rawData.Lat < geo.boundingBox(4));
    if sum(iOutBox)>0
        rawData.Phase(iOutBox) = [];
        rawData.Lat(iOutBox) = [];
        rawData.Lon(iOutBox) = [];
        rawData.Heading(iOutBox) = [];
        rawData.Inc(iOutBox) = [];
    end
    
    %Process and display raw InSAR data
    convertedPhase_raw = (rawData.Phase / (4*pi) )  * insar{i}.wavelength;    % Convert phase from radians to m
    los_raw = single(-convertedPhase_raw);  % Convert to Line-of-sigth displacement in m
    ll_raw = [single(rawData.Lon) single(rawData.Lat)];   % Create Longitude and Latitude 2Xn matrix
    xy_raw = llh2local(ll_raw', geo.referencePoint);    % Transform from geografic to local coordinates
    nPointsThis_raw = size(ll_raw, 1);   % Calculate length of current InSAR data vector
    xy_raw = double([(1:nPointsThis_raw)', xy_raw'*1000]);   % Add ID number column to xy matrix with local coordinates

    % Calculate MODEL
    constOffset = 0;
    xRamp = 0;
    yRamp = 0;
        
    if i == 1
        if insar{i}.constOffset == 'y'
            constOffset = invResults.model.mIx(end);
            invResults.model.mIx(end) = invResults.model.mIx(end)+1;
        end
        if insar{i}.rampFlag == 'y'
            xRamp = invResults.model.mIx(end);
            yRamp = invResults.model.mIx(end)+1;
            invResults.model.mIx(end) = invResults.model.mIx(end)+2;
        end
    end
    
    if i > 1
        if insar{i}.constOffset == 'y'
            constOffset = invResults.model.mIx(end);
            invResults.model.mIx(end) = invResults.model.mIx(end)+1;
        end
        if insar{i}.rampFlag == 'y'
            xRamp = invResults.model.mIx(end);
            yRamp = invResults.model.mIx(end)+1;
            invResults.model.mIx(end) = invResults.model.mIx(end)+2;
        end
    end

    % Apply forward model
    modLos_raw = forwardInsarModel(insar{i},xy_raw,invpar,invResults,modelInput,geo,rawData.Heading,rawData.Inc,constOffset,xRamp,yRamp);

    % Remove constant offset if there is one
    if insar{i}.constOffset == 'y'
        modLos_raw = modLos_raw - invResults.model.optimal(constOffset);
    end

    % Find spatial resolution in m of local coordinate system
    UniqueX = unique(ll_raw(:,1));
    UniqueY = unique(ll_raw(:,2));
    X_Resol_m = (max(xy_raw(:,2))-min(xy_raw(:,2)))./numel(UniqueX);   
    Y_Resol_m = (max(xy_raw(:,3))-min(xy_raw(:,3)))./numel(UniqueY);  

    % Find area where signal is above cutoff point
    Signal = modLos_raw(abs(modLos_raw)>cutoff);

    % Calculate area (num pixels x length of pixel x width of pixel)
    Area = (length(Signal).*X_Resol_m.*Y_Resol_m)./1e6; % In km2 - Adjust if your coordinates are in a different order to this
end