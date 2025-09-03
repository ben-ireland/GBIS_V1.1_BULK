function [OffsetRMS,OffsetImage] = ManualOffsetRemoval(OutputFilepath)
    %OutputFilePath = '/scratch/Ben/GBIS_BULK/Inversion_Results/fentale_079D_08094_131313CDMsTest_LastOffset/invert_1_L/invert_1_L/invert_1_L.mat';
    %OutputFilePath = '/scratch/Ben/GBIS_BULK/Inversion_Results/fentale_079D_08094_131313CDMsTest_LastOffset/invert_1_K/invert_1_K/invert_1_K.mat';
    %OutputFilePath = '/scratch/Ben/GBIS_BULK/Inversion_Results/corbetti_079D_08294_131313CDMsTest_NoLastNoOffset/invert_1_M/invert_1_M/invert_1_M.mat';
    %OutputFilePath = '/scratch/Ben/GBIS_BULK/Inversion_Results/alutu_079D_08294_131313CDMsTest_NoLastNoOffset/invert_1_K/invert_1_K/invert_1_K.mat';
    %OutputFilePath = '/scratch/Ben/GBIS_BULK/Inversion_Results/alutu_079D_08294_131313CDMsTest_NoLastNoOffset/invert_1_M/invert_1_M/invert_1_M.mat';
    %OutputFilePath = '/scratch/Ben/GBIS_BULK/Inversion_Results/alutu_079D_08294_131313CDMsTest_NoLastNoOffset/invert_1_J/invert_1_J/invert_1_J.mat';
    OutputFilepath = '/scratch/Ben/GBIS_BULK/Inversion_Results/silali_152D_08915_131313CDMsTest_LastNoOffset/invert_1_M/invert_1_M/invert_1_M.mat';
    %OutputFilepath = '/scratch/Ben/GBIS_BULK/Inversion_Results/silali_152D_08915_131313CDMsTest_LastNoOffset/invert_1_K/invert_1_K/invert_1_K.mat';
    %% Load inversion results file
    invResFiles = dir(OutputFilepath);
    Filepath = char(strcat(invResFiles.folder,'/',invResFiles.name));
    load(Filepath);

    resExp = 0;
    resExpOffset = 0;
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
        modLosRaw = forwardInsarModel(insar{i},xy_raw,invpar,invResults,modelInput,geo,HeadingRaw,IncRaw,constOffset,xRamp,yRamp); % Modeled InSAR displacements
        modLosRaw2 = modLosRaw';

        WRSS_LOS = insar{i}.dLos* insar{i}.invCov* insar{i}.dLos';

        % Calculate RMSE of the residuals
        %Raw data
        % RMSE of data
        RMSE_LOSRaw = sqrt((sum(los_raw.^2))/nObsRaw);
        % RMSE of residual without offset
        ResidualRaw = los_raw-modLosRaw2;
        RMSERaw(i) = sqrt((sum(ResidualRaw.^2))/nObsRaw);
        RMSE_ReductionRaw = ((RMSE_LOSRaw-RMSERaw)/RMSE_LOSRaw)*100;

        % RMSE of residual with offset
        ResidualOffset = ResidualRaw - mean(ResidualRaw);

        RMSERawOffset(i) = sqrt((sum(ResidualOffset.^2))/nObsRaw);
        resExp = resExp + ResidualRaw'* insar{i}.invCov* ResidualRaw;
        resExpOffset = resExpOffset + ResidualOffset'* insar{i}.invCov* ResidualOffset;

        f = figure()
        T = tiledlayout(1,3)
        cmap = flipud(cbrewer2('RdBu', 256));

        nexttile
        scatter(ll_raw(:,1), ll_raw(:,2),35,ResidualRaw,'.');
        colormap(cmap); 
        caxis([-0.05 0.05])
        axis square
        xlim([min(ll_raw(:,1)) max(ll_raw(:,1))])
        ylim([min(ll_raw(:,2)) max(ll_raw(:,2))])
        xtickangle(45)
        ax = gca;
        ax.Layer = 'top';
        ax.Box = 'on';
        set(gca,'Color',[0 0 0]);
        ax.XTickLabel = [];
        ax.YTickLabel = [];
        colorbar('WestOutside')
        title(['resExp: ',num2str(resExp)])
        subtitle(['RMSE: ',num2str(RMSERaw(i))])

        nexttile
        scatter(ll_raw(:,1), ll_raw(:,2),35,ResidualOffset,'.');
        colormap(cmap); 
        caxis([-0.05 0.05])
        axis square
        xlim([min(ll_raw(:,1)) max(ll_raw(:,1))])
        ylim([min(ll_raw(:,2)) max(ll_raw(:,2))])
        xtickangle(45)
        ax = gca;
        ax.Layer = 'top';
        ax.Box = 'on';
        set(gca,'Color',[0 0 0]);
        ax.XTickLabel = [];
        ax.YTickLabel = [];
        title(['resExp: ',num2str(resExpOffset)])
        subtitle(['RMSE: ',num2str(RMSERawOffset(i))])

        nexttile
        imagesc(insar{i}.invCov)
        colorbar
        axis image
        set(gca,'XTickLabel',[])
        set(gca,'YTickLabel',[])

        saveas(f,[pwd,'/TestFigs/SilaliMogi.png']);

    end
    keyboard
end