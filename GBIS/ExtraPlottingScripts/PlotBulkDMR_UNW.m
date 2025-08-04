function [Fig, RMS] = PlotBulkDMR_UNW(OutputFilePath)

% Create colormaps for plotting InSAR data
cmap2.Seismo = colormap_cpt('GMT_seis.cpt', 100); % GMT Seismo colormap for wrapped interferograms
cmap2.redToBlue = colormap_cpt('polar.cpt', 100); % Red to Blue colormap for unwrapped interferograms

figure()
tl = tiledlayout((length(OutputFilePath)),3);
tl.TileSpacing = "tight";
tl.Padding = "tight";
tl.FontSize = 4;

for k = 1:length(OutputFilePath)
    %% Load inversion results file
    invResFiles = dir(OutputFilePath{k});
    
    Filepath = char(strcat(invResFiles.folder,'/',invResFiles.name));
    
    load(Filepath);
    
    %% Load InSAR data and results data
    for i=1:length(insar)
        loadedData = load(insar{i}.dataPath);
    
        convertedPhase = (loadedData.Phase / (4*pi) ) * insar{i}.wavelength;    % Convert phase from radians to m
        los = single(-convertedPhase);  % Convert to Line-of-sigth displacement in m
        ll = [single(loadedData.Lon) single(loadedData.Lat)];   % Create Longitude and Latitude 2Xn matrix
        xy = llh2local(ll', geo.referencePoint);    % Transform from geografic to local coordinates
        
        nPointsThis = size(ll, 1);   % Calculate length of current InSAR data vector
        xy = double([(1:nPointsThis)', xy'*1000]);   % Add ID number column to xy matrix with local coordinates
        nObs2 = size(xy,1);
        Heading = loadedData.Heading;
        Inc = loadedData.Inc;
    
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
        modLos = forwardInsarModel(insar{i},xy,invpar,invResults,modelInput,geo,Heading,Inc,constOffset,xRamp,yRamp); % Modeled InSAR displacements
        modLos2 = modLos';
    
        %% Calculate RMSE of the residuals
        
        %Downsampled data
        % RMSE of data
        RMSE_LOS = sqrt((sum(los).^2))/nObs2;
        % RMSE of model
        RMSE_Mod = sqrt((sum(modLos2).^2))/nObs2;
        % RMSE of residual
        Residual = los-modLos2;
        RMSE = sqrt((sum(Residual).^2))/nObs2;
        RMSE_Reduction = ((RMSE_LOS-RMSE)/RMSE_LOS)*100;
    
        RMS.LOS = RMSE_LOS;
        RMS.Mod = RMSE_Mod;
        RMS.Resid = Residual;
        RMS.RMSE = RMSE;
        RMS.Reduction = RMSE_Reduction;
        %% Plot UNWRAPPED Data-Model-Residual
    
        nexttile
        % DATA
        scatter(ll(:,1), ll(:,2),2,los,'square', 'filled');
        colormap(cmap2.redToBlue); 
        c = max(abs([min(los), max(los)])); % Calculate maximum value for symmetric colormap
        caxis([-c c])
        axis square
        xlim([min(ll(:,1)) max(ll(:,1))])
        ylim([min(ll(:,2)) max(ll(:,2))])
        xtickangle(45)
    %     title('Data','interpreter','none')
    %     sgtitle(outputFileName(1:end-4),'interpreter','none');
    
        nexttile
        % MODEL
        scatter(ll(:,1), ll(:,2),2,modLos2,'square', 'filled');
        colormap(cmap2.redToBlue)
        c = max(abs([min(los), max(los)])); % Calculate maximum value for symmetric colormap
        caxis([-c c])
        axis square
        xlim([min(ll(:,1)) max(ll(:,1))])
        ylim([min(ll(:,2)) max(ll(:,2))])
        xtickangle(45)
    %     title('Model','interpreter','none')
    
        nexttile
        % RESIDUAL
        scatter(ll(:,1), ll(:,2),2,Residual,'square', 'filled');
        colormap(cmap2.redToBlue); 
        c = max(abs([min(los), max(los)])); % Calculate maximum value for symmetric colormap
        caxis([-c c])
        axis square
        xlim([min(ll(:,1)) max(ll(:,1))])
        ylim([min(ll(:,2)) max(ll(:,2))])
        xtickangle(45)
        c2 = colorbar;
        c2.Label.String = 'LOS displacement (m)';
    %     title('Residual','interpreter','none')
    %     subtitle(['RMSE (mm) = ',num2str(1000*RMSE,4)],'interpreter','none')
    
        
    end
end
% Get all axes handles in the tiled layout
allAxes = findobj(tl, 'type', 'axes');

% Set LineWidth for all axes
set(allAxes, 'LineWidth', 0.5);
Fig = tl;
end