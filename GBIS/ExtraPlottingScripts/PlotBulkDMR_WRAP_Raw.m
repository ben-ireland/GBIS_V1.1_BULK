function [Fig, RMS] = PlotBulkDMR_WRAP_Raw(OutputFilePath)

% Create colormaps for plotting InSAR data
cmap2.Seismo = colormap_cpt('GMT_seis.cpt', 100); % GMT Seismo colormap for wrapped interferograms
cmap2.redToBlue = colormap_cpt('polar.cpt', 100); % Red to Blue colormap for unwrapped interferograms

figure()
tl = tiledlayout((length(OutputFilePath)),3);
tl.TileSpacing = "tight";
tl.Padding = "tight";
tl.FontSize = 4;

for k=1:length(OutputFilePath)
    %% Load inversion results file
    invResFiles = dir(OutputFilePath{k});
    
    Filepath = char(strcat(invResFiles.folder,'/',invResFiles.name));
    
    load(Filepath);
    
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
        modLosRaw = forwardInsarModel(insar{i},xy_raw,invpar,invResults,modelInput,geo,HeadingRaw,IncRaw,constOffset,xRamp,yRamp); % Modeled InSAR displacements
        modLosRaw2 = modLosRaw';
    
        %% Calculate RMSE of the residuals
        %Raw data
        % RMSE of data
        RMSE_LOSRaw = sqrt((sum(los_raw).^2))/nObsRaw;
        % RMSE of model
        RMSE_ModRaw = sqrt((sum(modLosRaw2).^2))/nObsRaw;
        % RMSE of residual 
        ResidualRaw = los_raw-modLosRaw2;
        RMSERaw = sqrt((sum(ResidualRaw).^2))/nObsRaw;
        RMSE_ReductionRaw = ((RMSE_LOSRaw-RMSERaw)/RMSE_LOSRaw)*100;
    
        RMS.LOS = RMSE_LOSRaw;
        RMS.Mod = RMSE_ModRaw;
        RMS.Resid = ResidualRaw;
        RMS.RMSE = RMSERaw;
        RMS.Reduction = RMSE_ReductionRaw;
        %% Plot WRAPPED Data-Model-Residual
        % Convert from m to radians
        los_raw = los_raw*4*pi/insar{i}.wavelength;
        modLosRaw2 = modLosRaw2*4*pi/insar{i}.wavelength;
        ResidualRaw = ResidualRaw*4*pi/insar{i}.wavelength;
    
        % Customise axes labels
        cmin = 0;
        cmax = 2*pi;
        tickPositions = [0, pi, 2*pi];
        tickLabels = {'0','\pi','2\pi'};
    
        nexttile
        % Raw data - wrapped
        scatter(ll_raw(:,1), ll_raw(:,2),0.5,wrapTo2Pi(los_raw),'square', 'filled');
        colormap(cmap2.Seismo)
        axis square
        xlim([min(ll_raw(:,1)) max(ll_raw(:,1))])
        ylim([min(ll_raw(:,2)) max(ll_raw(:,2))])
        xtickangle(45)
    %     title('Data','interpreter','none')
    %     subtitle(['RMSE (mm) = ',num2str(1000*RMSE_LOSRaw,4)],'interpreter','none')
    
        nexttile
        % Raw model - wrapped
        scatter(ll_raw(:,1), ll_raw(:,2),0.5,wrapTo2Pi(modLosRaw2),'square', 'filled');
        colormap(cmap2.Seismo)
        axis square
        xlim([min(ll_raw(:,1)) max(ll_raw(:,1))])
        ylim([min(ll_raw(:,2)) max(ll_raw(:,2))])
        xtickangle(45)
    %     title('Model','interpreter','none')
    %     subtitle(['RMSE (mm) = ',num2str(1000*RMSE_ModRaw,4)],'interpreter','none')
    
        nexttile
        % Raw residual - wrapped
        scatter(ll_raw(:,1), ll_raw(:,2),0.5,wrapTo2Pi(ResidualRaw),'square', 'filled');
        colormap(cmap2.Seismo)
        axis square
        xlim([min(ll_raw(:,1)) max(ll_raw(:,1))])
        ylim([min(ll_raw(:,2)) max(ll_raw(:,2))])
        xtickangle(45)
        c = colorbar;
        caxis([cmin, cmax]);
        c.Ticks = tickPositions;
        c.TickLabels = tickLabels;
        c.Label.String = 'Wrapped phase (radians)';
    %     title('Residual','interpreter','none')
    %     subtitle(['RMSE (mm) = ',num2str(1000*RMSERaw,4)],'interpreter','none')
    end
end
% Get all axes handles in the tiled layout
allAxes = findobj(tl, 'type', 'axes');

% Set LineWidth for all axes
set(allAxes, 'LineWidth', 0.5);
Fig = tl;
end