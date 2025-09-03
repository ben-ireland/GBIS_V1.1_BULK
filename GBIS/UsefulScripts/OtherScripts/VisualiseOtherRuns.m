clear all; close all;

% GBIS results file
Filepath = '/local-scratch/Ben/GBIS_V1.1_BULK/Inversion_Results/alutu_079D_08294_131313MoreFarField/invert_1_M/invert_1_M/invert_1_M.mat';
%Filepath = '/local-scratch/Ben/GBIS_V1.1_BULK/Inversion_Results/alutu_079D_08294_131313SeedingTest_1std/invert_1_M/invert_1_M/invert_1_M.mat';
%Filepath = '/local-scratch/Ben/GBIS_V1.1_BULK/Inversion_Results/alutu_079D_08294_131313SeedingTestV2/invert_1_M/invert_1_M/invert_1_M.mat';
%Filepath = '/local-scratch/Ben/GBIS_V1.1_BULK/Inversion_Results/alutu_079D_08294_131313SeedingTest_15std/invert_1_M/invert_1_M/invert_1_M.mat';
ParamIdx = 3; % Param to search by e.g. 3 = Depth for Mogi
nRuns = 5;
Optimal = 0; % Plot optimal result
BestRuns = 1; % Plot best n runs
DistFromOptimal = 1000; % X/Y Distance from optimal tolerance
ParamValue = 1000;

Save = 1;
Raw = 0;
if Raw==0
    Pt_Size = 35; % 3 if raw, 35 if DS
elseif Raw==1
    Pt_Size = 3;
end

load(Filepath);

invResults.model.RMSE(isempty(invResults.model.RMSE) | invResults.model.RMSE==0)=NaN;
invResults.model.weightedRSS(isempty(invResults.model.weightedRSS) | invResults.model.weightedRSS==0)=NaN;
[MinRMS,RMSIdx] = mink(invResults.model.RMSE,1000);
[MinWRSS,WRSSIdx] = mink(invResults.model.weightedRSS,1000);

if BestRuns==1
    f1 = figure();
    t = tiledlayout(2,2);
    title(t,'Best 1000 runs')
    nexttile
    scatter(invResults.mKeep(1,WRSSIdx),invResults.mKeep(2,WRSSIdx),[],invResults.model.weightedRSS(WRSSIdx),'.');
    axis square
    xlabel('X coordinates (m)')
    ylabel('Y coordinates (m)')
    subtitle('WRSS')
    colorbar
    box on
    set(gca,'FontSize',8)

    nexttile
    scatter(invResults.mKeep(3,WRSSIdx),invResults.mKeep(4,WRSSIdx),[],invResults.model.weightedRSS(WRSSIdx),'.');
    axis square
    xlabel('Depth (m)')
    ylabel('dV (m^3)')
    subtitle('WRSS')
    c = colorbar;
    c.Label.String = 'Misfit (WRSS)';
    box on
    set(gca,'FontSize',8)

    nexttile
    scatter(invResults.mKeep(1,RMSIdx),invResults.mKeep(2,RMSIdx),[],invResults.model.RMSE(RMSIdx),'.');
    axis square
    xlabel('X coordinates (m)')
    ylabel('Y coordinates (m)')
    subtitle('RMS')
    colorbar
    box on
    set(gca,'FontSize',8)

    nexttile
    scatter(invResults.mKeep(3,RMSIdx),invResults.mKeep(4,RMSIdx),[],invResults.model.RMSE(RMSIdx),'.');
    axis square
    xlabel('Depth (m)')
    ylabel('dV (m^3)')
    subtitle('RMS')
    c = colorbar;
    c.Label.String = 'Misfit (RMS)';
    box on
    set(gca,'FontSize',8)
    

    %saveas(f1,[pwd,'/TestFigs/ExtremeRuns/Alutu_15std_seeding_Best1000.png']);
end

BestWRSSRuns = invResults.mKeep(:,WRSSIdx);
BestRMSRuns = invResults.mKeep(:,RMSIdx);

if BestRuns==1
    IdxBest = knnsearch(BestWRSSRuns(ParamIdx,:)',ParamValue,"K",nRuns);
    Idx = WRSSIdx(IdxBest);
else
    CloseRuns = find(abs(invResults.mKeep(1,:)-invResults.model.optimal(1))<DistFromOptimal...
                    & abs(invResults.mKeep(2,:)-invResults.model.optimal(2))<DistFromOptimal);

    IdxClose = knnsearch(invResults.mKeep(ParamIdx,CloseRuns)',ParamValue,"K",nRuns);
    Idx = CloseRuns(IdxClose);
end

% Create colormaps for plotting InSAR data
cmap2.Seismo = colormap_cpt('GMT_seis.cpt', 100); % GMT Seismo colormap for wrapped interferograms
cmap2.redToBlue = colormap_cpt('polar.cpt', 100); % Red to Blue colormap for unwrapped interferograms
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
    for k = 1:nRuns
        if Optimal==1
            modLosRaw = forwardInsarModel(insar{i},xy_raw,invpar,invResults,modelInput,geo,HeadingRaw,IncRaw,constOffset,xRamp,yRamp); 
        elseif Optimal==0
            modLosRaw = forwardInsarModelV2(insar{i},xy_raw,invpar,invResults,modelInput,geo,HeadingRaw,IncRaw,constOffset,xRamp,yRamp,Idx(k)); % Modeled InSAR displacements
        end
        modLosRaw2 = modLosRaw';

        %% Calculate RMSE of the residuals
        %Raw data
        % RMSE of data
        RMSE_LOSRaw = sqrt((sum(los_raw).^2))/nObsRaw;
        % RMSE of model
        RMSE_ModRaw = sqrt((sum(modLosRaw2).^2))/nObsRaw;
        % RMSE of residual 
        ResidualRaw = los_raw-modLosRaw2;

        RMSERaw = sqrt(sum(ResidualRaw.^2)/nObsRaw);
        WRSS = ResidualRaw' * insar{i}.invCov * ResidualRaw;

        %% Plot UNWRAPPED Data-Model-Residual
        f = figure()
        tl = tiledlayout(2,3,'TileIndexing','rowmajor');
        tl.TileSpacing = 'tight';

        ax1 = nexttile;
        % Raw residual - unwrapped
        scatter(ll_raw(:,1), ll_raw(:,2),Pt_Size,los_raw,'.');
        set(gca,'Color',[0.5 0.5 0.5]);
        colormap(ax1,cmap)
        c = max(abs([min(los_raw), max(los_raw)])); % Calculate maximu value for symmetric colormap
        %caxis([-c c])
        caxis([-0.05 0.05])
        axis square
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
        ax.Layer = 'top';
        ax.Box = 'on';
        set(gca,'Color',[0 0 0]);

        ax1 = nexttile;
        % Raw model - unwrapped
        scatter(ll_raw(:,1), ll_raw(:,2),Pt_Size,modLosRaw2,'.');
        set(gca,'Color',[0.5 0.5 0.5]);
        colormap(ax1,cmap)
        c = max(abs([min(los_raw), max(los_raw)])); % Calculate maximu value for symmetric colormap
        %caxis([-c c])
        caxis([-0.05 0.05])
        axis square
        xlim([min(ll_raw(:,1)) max(ll_raw(:,1))])
        ylim([min(ll_raw(:,2)) max(ll_raw(:,2))])
        if Raw ==0
            xlim(limX);
            ylim(limY);
        end
        xtickangle(45)
        subtitle(['RMS = ',num2str(RMSERaw),' m'])
        ax = gca;
        ax.XTickLabel = [];
        ax.YTickLabel = [];
        ax.XTick = [];
        ax.YTick = [];
        ax.Layer = 'top';
        ax.Box = 'on';
        set(gca,'Color',[0 0 0]);

        ax1 = nexttile;
        % Raw residual - unwrapped
        scatter(ll_raw(:,1), ll_raw(:,2),Pt_Size,ResidualRaw,'.');
        set(gca,'Color',[0.5 0.5 0.5]);
        colormap(ax1,cmap)
        c = max(abs([min(los_raw), max(los_raw)])); % Calculate maximu value for symmetric colormap
        %caxis([-c c])
        caxis([-0.05 0.05])
        axis square
        xlim([min(ll_raw(:,1)) max(ll_raw(:,1))])
        ylim([min(ll_raw(:,2)) max(ll_raw(:,2))])
        if Raw ==0
            xlim(limX);
            ylim(limY);
        end
        xtickangle(45)
        subtitle(['WRSS = ',num2str(WRSS)])
        ax = gca;
        ax.XTickLabel = [];
        ax.YTickLabel = [];
        ax.XTick = [];
        ax.YTick = [];
        ax.Layer = 'top';
        ax.Box = 'on';
        set(gca,'Color',[0 0 0]);
        c2 = colorbar;
        c2.Label.String = 'LOS displacement (m)';


        %% WRAPPED
        % Convert from m to radians
        los_raw_w = los_raw*4*pi/insar{i}.wavelength;
        modLosRaw2_w = modLosRaw2*4*pi/insar{i}.wavelength;
        ResidualRaw_w = ResidualRaw*4*pi/insar{i}.wavelength;
        
        % Customise axes labels
        cmin = 0;
        cmax = 2*pi;
        tickPositions = [0, pi, 2*pi];
        tickLabels = {'0','\pi','2\pi'};

        ax2 = nexttile;
        % Raw data - wrapped
        scatter(ll_raw(:,1), ll_raw(:,2),Pt_Size,wrapTo2Pi(los_raw_w),'.');
        colormap(ax2,cmap2.Seismo)
        ax = gca;
        ax.Layer = 'top';
        ax.Box = 'on';
        %grid on
        %ax.GridLineStyle = '--';
        set(gca,'Color',[0 0 0]);
        axis square
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

        ax2 = nexttile;
        % Raw model - wrapped
        scatter(ll_raw(:,1), ll_raw(:,2),Pt_Size,wrapTo2Pi(modLosRaw2_w),'.');
        colormap(ax2,cmap2.Seismo)
        ax = gca;
        ax.Layer = 'top';
        ax.Box = 'on';
        %grid on
        %ax.GridLineStyle = '--';
        set(gca,'Color',[0 0 0]);
        axis square
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
        subtitle(['Depth = ',num2str(invResults.mKeep(3,Idx(k))),' m']);

        ax2 = nexttile;
        % Raw residual - wrapped
        scatter(ll_raw(:,1), ll_raw(:,2),Pt_Size,wrapTo2Pi(ResidualRaw_w),'.');
        colormap(ax2,cmap2.Seismo)
        ax = gca;
        ax.Layer = 'top';
        ax.Box = 'on';
        %grid on
        %ax.GridLineStyle = '--';
        set(gca,'Color',[0 0 0]);
        axis square
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
        subtitle(['dV = ',num2str(invResults.mKeep(4,Idx(k))),' m^3']);

        c = colorbar;
        caxis([cmin, cmax]);
        c.Ticks = tickPositions;
        c.TickLabels = tickLabels;
        c.Label.String = 'Wrapped phase (radians)';

        saveas(f,[pwd,'/TestFigs/ExtremeRuns/Alutu_1k_Best_',num2str(k),'.png']);
    end
end