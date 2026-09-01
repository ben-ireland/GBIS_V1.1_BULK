function [Fig, RMS] = PlotDMR_UNW_WrappedDS(OutputFilePath,Name)

Save = 1;
Raw = 0;
if Raw==0
    Pt_Size = 35; % 3 if raw, 35 if DS
elseif Raw==1
    Pt_Size = 3;
end

%% Load inversion results file
invResFiles = dir(OutputFilePath);

Filepath = char(strcat(invResFiles.folder,'/',invResFiles.name));

load(Filepath);

% Create colormaps for plotting InSAR data
cmap2.Seismo = colormap_cpt('GMT_seis.cpt', 100); % GMT Seismo colormap for wrapped interferograms
cmap2.redToBlue = colormap_cpt('polar.cpt', 100); % Red to Blue colormap for unwrapped interferograms
cmap = flipud(cbrewer2('RdYlBu', 256));
cmap = flipud(cbrewer2('RdBu', 256));

%% Load InSAR data and results data
for i=1:length(insar)
    if Raw==1
        rawData = load(insar{i}.rawDataPath);
    else
        rawData = load(insar{i}.rawDataPath);
        ll_raw = [single(rawData.Lon) single(rawData.Lat)]; 
        limX = [min(ll_raw(:,1)) max(ll_raw(:,1))];
        limY = [min(ll_raw(:,2)) max(ll_raw(:,2))];
        rawData = load(insar{i}.dataPath);
    end
    
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

    %% Plot UNWRAPPED Data-Model-Residual
    figure()
    tl = tiledlayout(1,3);
    tl.TileSpacing = 'tight';

    nexttile
    % Raw data - unwrapped
    scatter(ll_raw(:,1), ll_raw(:,2),Pt_Size,los_raw,'.');
    colormap(cmap); 
    c = max(abs([min(los_raw), max(los_raw)])); % Calculate maximu value for symmetric colormap
    c = 0.3;
    caxis([-c c])
    %caxis([-0.1 0.1])
    axis equal
    xlim([min(ll_raw(:,1)) max(ll_raw(:,1))])
    ylim([min(ll_raw(:,2)) max(ll_raw(:,2))])
    if Raw ==0
        xlim(limX);
        ylim(limY);
    end
    xtickangle(45)
    ax = gca;
    ax.Layer = 'top';
    ax.Box = 'on';
    %grid on
    %ax.GridLineStyle = '--';
    set(gca,'Color',[0 0 0]);
    % Turn off axis labels
    %ax.XAxis.Visible = 'off';
    %ax.YAxis.Visible = 'off';

    %c2 = colorbar('SouthOutside');
    %c2.Label.String = 'LOS displacement (m)';

    % Turn off tick labels
    ax.XTickLabel = [];
    ax.YTickLabel = [];

    % If you want to remove ticks as well, uncomment the following lines
    ax.XTick = [];
    ax.YTick = [];
%     title('Data','interpreter','none')
%     subtitle(['RMSE (mm) = ',num2str(1000*RMSE_LOSRaw,4)],'interpreter','none')

    nexttile
    % Raw model - unwrapped
    scatter(ll_raw(:,1), ll_raw(:,2),Pt_Size,modLosRaw2,'.');
    set(gca,'Color',[0.5 0.5 0.5]);
    colormap(cmap)
    c = max(abs([min(los_raw), max(los_raw)])); % Calculate maximu value for symmetric colormap
    c = 0.3;
    caxis([-c c])
    %caxis([-0.1 0.1])
    axis equal
    xlim([min(ll_raw(:,1)) max(ll_raw(:,1))])
    ylim([min(ll_raw(:,2)) max(ll_raw(:,2))])
    if Raw ==0
        xlim(limX);
        ylim(limY);
    end
    xtickangle(45)
    ax = gca;
    ax.Layer = 'top';
    ax.Box = 'on';
    %grid on
    %ax.GridLineStyle = '--';
    set(gca,'Color',[0 0 0]);
    
    % Turn off axis labels
    %ax.XAxis.Visible = 'off';
    %ax.YAxis.Visible = 'off';

    % Turn off tick labels
    ax.XTickLabel = [];
    ax.YTickLabel = [];

    % If you want to remove ticks as well, uncomment the following lines
    ax.XTick = [];
    ax.YTick = [];
%     title('Model','interpreter','none')
%     subtitle(['RMSE (mm) = ',num2str(1000*RMSE_ModRaw,4)],'interpreter','none')

    nexttile
    % Raw residual - unwrapped
    scatter(ll_raw(:,1), ll_raw(:,2),Pt_Size,ResidualRaw,'.');
    colormap(cmap); 
    c = max(abs([min(los_raw), max(los_raw)])); % Calculate maximu value for symmetric colormap
    c = 0.3;
    caxis([-c c])
    %caxis([-0.1 0.1])
    axis equal
    xlim([min(ll_raw(:,1)) max(ll_raw(:,1))])
    ylim([min(ll_raw(:,2)) max(ll_raw(:,2))])
    if Raw ==0
        xlim(limX);
        ylim(limY);
    end
    xtickangle(45)
    ax = gca;
    ax.Layer = 'top';
    ax.Box = 'on';
    %grid on
    %ax.GridLineStyle = '--';
    set(gca,'Color',[0 0 0]);
    % Turn off axis labels
    %ax.XAxis.Visible = 'off';
    %ax.YAxis.Visible = 'off';

    % Turn off tick labels
    ax.XTickLabel = [];
    ax.YTickLabel = [];

    % If you want to remove ticks as well, uncomment the following lines
    ax.XTick = [];
    ax.YTick = [];
    c2 = colorbar;
    c2.Label.String = 'LOS displacement (m)';
%     title('Residual','interpreter','none')
%     subtitle(['RMSE (mm) = ',num2str(1000*RMSERaw,4)],'interpreter','none')

    Fig = tl;
    %saveas(Fig,[pwd,'/',Name,num2str(i),'_Unwrapped.png']);

    %% WRAPPED
    % Convert from m to radians
    los_raw = los_raw*4*pi/insar{i}.wavelength;
    modLosRaw2 = modLosRaw2*4*pi/insar{i}.wavelength;
    ResidualRaw = ResidualRaw*4*pi/insar{i}.wavelength;
    
    % Customise axes labels
    cmin = 0;
    cmax = 2*pi;
    tickPositions = [0, pi, 2*pi];
    tickLabels = {'0','\pi','2\pi'};

    figure()
    tl = tiledlayout(1,3);
    tl.TileSpacing = 'tight';

    nexttile
    % Raw data - wrapped
    scatter(ll_raw(:,1), ll_raw(:,2),Pt_Size,wrapTo2Pi(los_raw),'.');
    colormap(cmap2.Seismo)
    ax = gca;
    ax.Layer = 'top';
    ax.Box = 'on';
    %grid on
    %ax.GridLineStyle = '--';
    set(gca,'Color',[0 0 0]);
    axis equal
    xlim([min(ll_raw(:,1)) max(ll_raw(:,1))])
    ylim([min(ll_raw(:,2)) max(ll_raw(:,2))])
    if Raw ==0
        xlim(limX);
        ylim(limY);
    end
    xtickangle(45)
    ax = gca;
    ax.XTickLabel = [];
    ax.YTickLabel = [];
    ax.XTick = [];
    ax.YTick = [];
    %c = colorbar('SouthOutside');
    %caxis([cmin, cmax]);
    %c.Ticks = tickPositions;
    %c.TickLabels = tickLabels;
    %c.Label.String = 'Wrapped phase (radians)';
%     title('Data','interpreter','none')
%     subtitle(['RMSE (mm) = ',num2str(1000*RMSE_LOSRaw,4)],'interpreter','none')
%set(gca,'XTick',[])
%set(gca,'YTick',[])

    nexttile
    % Raw model - wrapped
    scatter(ll_raw(:,1), ll_raw(:,2),Pt_Size,wrapTo2Pi(modLosRaw2),'.');
    colormap(cmap2.Seismo)
    ax = gca;
    ax.Layer = 'top';
    ax.Box = 'on';
    %grid on
    %ax.GridLineStyle = '--';
    set(gca,'Color',[0 0 0]);
    axis equal
    xlim([min(ll_raw(:,1)) max(ll_raw(:,1))])
    ylim([min(ll_raw(:,2)) max(ll_raw(:,2))])
    if Raw ==0
        xlim(limX);
        ylim(limY);
    end
    xtickangle(45)
    ax = gca;
    ax.XTickLabel = [];
    ax.YTickLabel = [];
    ax.XTick = [];
    ax.YTick = [];
%     title('Model','interpreter','none')
%     subtitle(['RMSE (mm) = ',num2str(1000*RMSE_ModRaw,4)],'interpreter','none')
%set(gca,'XTick',[])
%set(gca,'YTick',[])

    nexttile
    % Raw residual - wrapped
    scatter(ll_raw(:,1), ll_raw(:,2),Pt_Size,wrapTo2Pi(ResidualRaw),'.');
    colormap(cmap2.Seismo)
    ax = gca;
    ax.Layer = 'top';
    ax.Box = 'on';
    %grid on
    %ax.GridLineStyle = '--';
    set(gca,'Color',[0 0 0]);
    axis equal
    xlim([min(ll_raw(:,1)) max(ll_raw(:,1))])
    ylim([min(ll_raw(:,2)) max(ll_raw(:,2))])
    if Raw ==0
        xlim(limX);
        ylim(limY);
    end
    xtickangle(45)
    ax = gca;
    ax.XTickLabel = [];
    ax.YTickLabel = [];
    ax.XTick = [];
    ax.YTick = [];
    c = colorbar;
    caxis([cmin, cmax]);
    c.Ticks = tickPositions;
    c.TickLabels = tickLabels;
    c.Label.String = 'Wrapped phase (radians)';
%     title('Residual','interpreter','none')
%     subtitle(['RMSE (mm) = ',num2str(1000*RMSERaw,4)],'interpreter','none')
    
    %set(gca,'XTick',[])
    %set(gca,'YTick',[])
    Fig2 = tl;
    if Raw ==1
        saveas(Fig,[pwd,'/',Name,num2str(i),'_UnwrappedRaw.png']);
        saveas(Fig2,[pwd,'/',Name,num2str(i),'_WrappedRaw.png']);
    elseif Raw ==0
        saveas(Fig,[pwd,'/',Name,num2str(i),'_UnwrappedDS.png']);
        saveas(Fig2,[pwd,'/',Name,num2str(i),'_WrappedDS.png']);
    end

    if Save==1
        if Raw ==1
            save([pwd,'/',Name,num2str(i),'_DMR_Raw.mat'],"ll_raw",'los_raw','modLosRaw2','ResidualRaw');
        else
            save([pwd,'/',Name,num2str(i),'_DMR_DS.mat'],"ll_raw",'los_raw','modLosRaw2','ResidualRaw','limX','limY');
        end
    end
end
end