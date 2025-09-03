close all;clear all
addpath(genpath([pwd,'/GBIS'])); 

wavelength = 0.056;
rad2m = wavelength./(4*pi);
m2rad = (4*pi)./wavelength;
RunName = 'NoICA_Buffer_WithLastV4'; % For inversion results

OrigData = dir('/home/jl20461/GBIS_V1.1_BULK/OriginalData/*WihtLast.mat');
Masks = dir('/home/jl20461/GBIS_V1.1_BULK/Buffers/*WithLast.mat');
SlidingWindows = dir('/home/jl20461/GBIS_V1.1_BULK/SignalLocation/WithLastStep3/*_SlidingWindow_Clustering_50_7_Box_20.mat');
ICAs = dir(['/home/jl20461/GBIS_V1.1_BULK/ICA/*',RunName,'Comparison.mat']);
OtsuBBs = dir(['/home/jl20461/GBIS_V1.1_BULK/Bounding_Boxes/*_BoundingBox_2_MaskVolc_',RunName,'.mat']);
OtsuMasks = dir(['/home/jl20461/GBIS_V1.1_BULK/Bounding_Boxes/*_LargestMask_2_MaskVolc_',RunName,'.mat']);

n=0;
for i = 1:length(OrigData)
    if contains(OrigData(i).name,'gada_ale_079')
        n = n+1;
        OrigData2(n) = OrigData(i);
        Masks2(n) = Masks(i);
        SlidingWindows2(n) = SlidingWindows(i);
        OtsuBBs2(n) = OtsuBBs(i);
        OtsuMasks2(n) = OtsuMasks(i);
    end
end

OrigData = OrigData2;
Masks = Masks2;
SlidingWindows = SlidingWindows2;
OtsuBBs = OtsuBBs2;
OtsuMasks = OtsuMasks2;

for i = 1:length(OrigData)
    disp(num2str(i))

    % Define filepaths
    OriginalData = strcat(OrigData(i).folder,'/',OrigData(i).name);
    MaskData = strcat(Masks(i).folder,'/',Masks(i).name);
    SlidingWindow = strcat(SlidingWindows(i).folder,'/',SlidingWindows(i).name);
    %ICAData = strcat(ICAs(i).folder,'/',ICAs(i).name);
    OtsuBB = strcat(OtsuBBs(i).folder,'/',OtsuBBs(i).name);
    OtsuMask = strcat(OtsuMasks(i).folder,'/',OtsuMasks(i).name);

    % Generate DMR from volcano
    VolcName = extractBefore(OrigData(i).name,'WihtLast');
    
    InvResFile = strcat('/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/',VolcName,RunName,'/invert_1_M/invert_1_M/invert_1_M.mat');
    PlotDMR_UNW_Wrapped(InvResFile,['/ICA_DMRs/',VolcName]);
    DMRData = dir(['/home/jl20461/GBIS_V1.1_BULK/ICA_DMRs/',VolcName,'*DS.mat']);
    DMRData = strcat(DMRData(1).folder,'/',DMRData(1).name);

    f = figure()
    t = tiledlayout(5,2,"TileSpacing","compact","Padding","compact");

    % Original data
    nexttile
    Orig = load(OriginalData);
    imagesc(Orig.LastStep,"AlphaData",Orig.LastStep~=0);
    colormap(flipud(cbrewer2('RdBu',256)))
    caxis([-0.05 0.05])
    caxis([-max(Orig.LastStep(:)), max(Orig.LastStep(:))]);
    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
    set(gca,'Xticklabel',[]);
    set(gca,'Yticklabel',[]);
    axis image
    c = colorbar('westoutside')
    c.Label.String = 'LOS Displacement (m)';

    % Masked data
    nexttile
    Mask = load(MaskData);
    imagesc(Mask.LastStep.*-rad2m,"AlphaData",Mask.LastStep~=0);
    colormap(flipud(cbrewer2('RdBu',256)))
    caxis([-0.05 0.05])
    caxis([-max(Orig.LastStep(:)), max(Orig.LastStep(:))]);
    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
    set(gca,'Xticklabel',[]);
    set(gca,'Yticklabel',[]);
    axis image

    %ICA + Sliding window and clustering results
    nexttile
    %ICA = load(ICAData);
    imagesc(Mask.LastStep.*-rad2m,"AlphaData",Mask.LastStep~=0);
    colormap(flipud(cbrewer2('RdBu',256)))
    caxis([-0.05 0.05])
    caxis([-max(Orig.LastStep(:)), max(Orig.LastStep(:))]);
    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
    set(gca,'Xticklabel',[]);
    set(gca,'Yticklabel',[]);
    axis image
    hold on
    SlideWind = load(SlidingWindow);
    set(gca,'YDir','reverse')
    h = gscatter(SlideWind.Points2(:,2), SlideWind.Points2(:,1), SlideWind.idx2, [0.8 0.8 0.8; 0 0 0], 'o', [], 'off');
    for i = 1:length(h)
        set(h(i), 'MarkerFaceColor', get(h(i), 'Color'));
        set(h(i), 'MarkerEdgeColor', [0.8 0.8 0.8]);% Fill the markers with their respective colors
    end

    h3 = plot(SlideWind.pgon,"EdgeColor",'k','FaceAlpha',0.3,'FaceColor','k');
    if length(unique(SlideWind.idx2)) ==1
        legend(gca, [h, h3], {'Core point (DBSCAN)','Initial signal centre estimate'}, 'Location', 'southwest')
    else
        legend(gca, [h(2), h(1), h3], {'Core point (DBSCAN)', 'Noise (DBSCAN)','Initial signal centre estimate'}, 'Location', 'southwest')
    end
    hold off

    % Otsu bounding box location
    nexttile
    imagesc(Mask.LastStep.*-rad2m,"AlphaData",Mask.LastStep~=0);
    colormap(flipud(cbrewer2('RdBu',256)))
    caxis([-0.05 0.05])
    caxis([-max(Orig.LastStep(:)), max(Orig.LastStep(:))]);
    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
    set(gca,'Xticklabel',[]);
    set(gca,'Yticklabel',[]);
    axis image
    hold on
    OtsuResults = load(OtsuMask);
    OtsuFineBB = load(OtsuBB);
    test = regionprops(OtsuResults.largest_component_mask,'ConvexHull');
    CompMask = polyshape(test.ConvexHull(:,1),test.ConvexHull(:,2));
    h1 = plot(OtsuFineBB.BoundingBox,"LineStyle","--","EdgeColor",'k','FaceAlpha',0,'LineWidth',1.5);
    h2 = plot(CompMask,"LineStyle","-","EdgeColor",'k','FaceAlpha',0,'LineWidth',1.5);
    legend(gca, [h1, h2], {'Near/Far-field boundary', 'Chosen Otsu region'}, 'Location', 'southwest');
    hold off

    % Downsampled data
    nexttile
    DMR = load(DMRData);
    scatter(DMR.ll_raw(:,1), DMR.ll_raw(:,2),20,DMR.los_raw.*rad2m,'.');
    colormap(flipud(cbrewer2('RdBu',256)))
    caxis([-0.05 0.05])
    caxis([-max(Orig.LastStep(:)), max(Orig.LastStep(:))]);
    xlim([min(Orig.lon(:)) max(Orig.lon(:))])
    ylim([min(Orig.lat(:)) max(Orig.lat(:))])
    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
    set(gca,'Xticklabel',[]);
    set(gca,'Yticklabel',[]);
    box on
    axis square

    % Downsampled model
    nexttile
    scatter(DMR.ll_raw(:,1), DMR.ll_raw(:,2),20,DMR.modLosRaw2.*rad2m,'.');
    colormap(flipud(cbrewer2('RdBu',256)))
    caxis([-0.05 0.05])
    caxis([-max(Orig.LastStep(:)), max(Orig.LastStep(:))]);
    xlim([min(Orig.lon(:)) max(Orig.lon(:))])
    ylim([min(Orig.lat(:)) max(Orig.lat(:))])
    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
    set(gca,'Xticklabel',[]);
    set(gca,'Yticklabel',[]);
    box on
    axis square

    set(gcf, 'Position', [100, 100, 500, 600]);
    ax = findall(gcf, 'Type', 'axes'); % Find all axes in the current figure
    for k = 1:length(ax)
        lgd = findall(ax(k), 'Type', 'Legend');
        if ~isempty(lgd)
            lgd.FontSize = 6; % Adjust this value as needed
        end
    end

    % LOAD INVERSION RESULTS
    InvResults = load(InvResFile);
    burning = 20000;
    % Convergence plots for strength and extent
    if InvResults.invpar.nRuns <= 10000
        blankCells = 999; 
    else
        blankCells = 9999;
    end
    for k = 3:4
        nexttile    % Determine poistion in subplot
        plot(1:100:length(InvResults.invResults.mKeep(1,:))-blankCells, InvResults.invResults.mKeep(k,1:100:end-blankCells),'r.') % Plot one point every 100 iterations
        %title(invResults.model.parName(k))
        axis square
        ConvX{k} = 1:100:length(InvResults.invResults.mKeep(1,:))-blankCells;
        ConvY{k} = InvResults.invResults.mKeep(k,1:100:end-blankCells);
    end
    

    % % PDF plots for strength and extent
    % for k = 3:4
    %     nexttile % Determine poistion in subplot
    %     xMin = mean(InvResults.invResults.mKeep(k,burning:end-blankCells))-4*std(InvResults.invResults.mKeep(k,burning:end-blankCells));
    %     xMax = mean(InvResults.invResults.mKeep(k,burning:end-blankCells))+4*std(InvResults.invResults.mKeep(k,burning:end-blankCells));
    %     bins = xMin: (xMax-xMin)/50: xMax;
    %     h = histogram(InvResults.invResults.mKeep(k,burning:end-blankCells),bins,'EdgeColor','none','Normalization','count');
    %     hold on
    %     topLim = max(h.Values);
    %     plot([InvResults.invResults.model.optimal(k),InvResults.invResults.model.optimal(k)],[0,topLim+10000],'r-') % Plot optimal value
    %     ylim([0 topLim+10000])
    %     axis square
    %     %title(invResults.model.parName(i))

    %     HTop(k) = topLim;
    %     HBins{k} = bins;
    %     HVals{k} = InvResults.invResults.mKeep(k,burning:end-blankCells);
    %     ValsX{k} = InvResults.invResults.model.optimal(k);
    % end

        % Tradeoff plot for strength and extent

        nexttile([1,2])
        scatter(InvResults.invResults.mKeep(3,burning:end-blankCells-1)./1000,InvResults.invResults.mKeep(4,burning:end-blankCells-1)./1e6,[],InvResults.invResults.PKeep(burning:end-blankCells-1),'.');
        xlabel('Extent');
        ylabel('Strength');
        %colormap(cbrewer2('OrRd',256))
    
    
        saveas(f,['/home/jl20461/GBIS_V1.1_BULK/PreProcessingFigs/',VolcName,'_',RunName,'_PreProcessingTradeoff.svg']);
        saveas(f,['/home/jl20461/GBIS_V1.1_BULK/PreProcessingFigs/',VolcName,'_',RunName,'_PreProcessingTradeoff.png']);
    
        OrigLastStep = Orig.LastStep;
        OrigLon = Orig.lon;
        OrigLat = Orig.lat;
        MaskLastStep = Mask.LastStep;
        %ICA_Reconstructed = ICA.ICA_Reconstructed_Disp./1000;
        OtsuBR = OtsuFineBB.BoundingBox;
        Conv.XVals = ConvX;
        Conv.YVals = ConvY;
        % PDF.Bins = HBins;
        % PDF.HistVals = HVals;
        % PDF.Red = ValsX;
        % PDF.RedLim = HTop;
        Tradeoff.X = InvResults.invResults.mKeep(3,burning:end-blankCells-1)./1000;
        Tradeoff.Y = InvResults.invResults.mKeep(4,burning:end-blankCells-1)./1e6;
        Tradeoff.Z = InvResults.invResults.PKeep(burning:end-blankCells-1);
    
        save(['/home/jl20461/GBIS_V1.1_BULK/PreProcessingFigs/',VolcName,'_',RunName,'_PreProcessingTradeoff.mat']...
            ,'OrigLastStep','OrigLon','OrigLat','MaskLastStep','SlideWind','OtsuBR',...
            'CompMask','DMR','Conv','Tradeoff');

    close all
end