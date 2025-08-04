function [Data, Model, Residual] = RecalculateResiduals(OutputFilePath)
    invResFiles = dir(OutputFilePath);
    Filepath = char(strcat(invResFiles.folder,'/',invResFiles.name));
    load(Filepath);

    for i = 1:length(insar)
        % load downsampled data
        rawData = load(insar{i}.dataPath);
        convertedPhase_raw = (rawData.Phase / (4*pi) )  * insar{i}.wavelength;    % Convert phase from radians to m
        los_raw = single(-convertedPhase_raw);  % Convert to Line-of-sigth displacement in m
        ll_raw = [single(rawData.Lon) single(rawData.Lat)];   % Create Longitude and Latitude 2Xn matrix
        xy_raw = llh2local(ll_raw', geo.referencePoint);    % Transform from geografic to local coordinates
        nPointsThis_raw = size(ll_raw, 1);   % Calculate length of current InSAR data vector
        xy_raw = double([(1:nPointsThis_raw)', xy_raw'*1000]);   % Add ID number column to xy matrix with local coordinates
        nObsRaw = length(convertedPhase_raw);
        HeadingRaw = rawData.Heading;
        IncRaw = rawData.Inc;

        % Calculate Forward model (no offset)
        % Make forward model
        constOffset = 0;
        xRamp = 0;
        yRamp = 0;

        if insar{i}.constOffset == 'y'
            constOffset = invResults.model.mIx(end);
            invResults.model.mIx(end) = invResults.model.mIx(end)+1;
        end

        if insar{i}.rampFlag == 'y'
            xRamp = invResults.model.mIx(end);
            yRamp = invResults.model.mIx(end)+1;
            invResults.model.mIx(end) = invResults.model.mIx(end)+2;
        end

        modLosRaw = forwardInsarModel(insar{i},xy_raw,invpar,invResults,modelInput,geo,HeadingRaw,IncRaw,constOffset,xRamp,yRamp); % Modeled InSAR displacements
        
        Data{i} = los_raw;
        Model{i} = modLosRaw';
        Residual{i} = Data{i}-Model{i};
    end
end
