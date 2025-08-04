function [ForwardModel,U_Comp,lonlat] = MakeForwardModel(OutputFilePath)
% Produce forward model plotted onto full resolution input data (not downsampled)
%% Load inversion results file
load(OutputFilePath);

% Create colormaps for plotting InSAR data
%cmap2.Seismo = colormap_cpt('GMT_seis.cpt', 100); % GMT Seismo colormap for wrapped interferograms
%cmap2.redToBlue = colormap_cpt('polar.cpt', 100); % Red to Blue colormap for unwrapped interferograms
%cmap = flipud(cbrewer2('RdYlBu', 256));
%cmap = flipud(cbrewer2('RdBu', 256));

%% Load InSAR data and results data
for i=1:length(insar)
    rawData = load(insar{i}.rawDataPath);
    
    convertedPhase_raw = (rawData.Phase / (4*pi) )  * insar{i}.wavelength;    % Convert phase from radians to m
    los_raw = single(-convertedPhase_raw);  % Convert to Line-of-sigth displacement in m
    ll_raw = [single(rawData.Lon) single(rawData.Lat)];   % Create Longitude and Latitude 2Xn matrix
    xy_raw = llh2local(ll_raw', geo.referencePoint);    % Transform from geografic to local coordinates
    nPointsThis_raw = size(ll_raw, 1);   % Calculate length of current InSAR data vector
    xy_raw = double([(1:nPointsThis_raw)', xy_raw'*1000]);   % Add ID number column to xy matrix with local coordinates
    nObsRaw = length(convertedPhase_raw);
    HeadingRaw = rawData.Heading;
    IncRaw = rawData.Inc;


    %% Offset and ramp values
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
    
    %% Calculate Forward model
    % Make forward model
    [modLosRaw, Utot] = forwardInsarModelComps(insar{i},xy_raw,invpar,invResults,modelInput,geo,HeadingRaw,IncRaw,constOffset,xRamp,yRamp); % Modeled InSAR displacements
    ForwardModel{i} = modLosRaw';
    U_Comp{i} = Utot';
    lonlat{i} = ll_raw;

end
end