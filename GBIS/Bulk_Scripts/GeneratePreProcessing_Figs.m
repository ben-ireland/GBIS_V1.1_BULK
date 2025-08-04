close all;clear all
addpath(genpath([pwd,'/GBIS'])); 

wavelength = 0.056;
rad2m = wavelength./(4*pi);
m2rad = (4*pi)./wavelength;
RunName = 'ICA_Buffer_NoLastV4'; % For inversion results

OrigData = dir('/home/jl20461/GBIS_V1.1_BULK/OriginalData/*.mat');
Masks = dir('/home/jl20461/GBIS_V1.1_BULK/Buffers/*.mat');
SlidingWindows = dir('/home/jl20461/GBIS_V1.1_BULK/SignalLocation/*_SlidingWindow_Clustering_50_7_Box_20.mat');
ICAs = dir('/home/jl20461/GBIS_V1.1_BULK/ICA/*Comparison.mat');
OtsuBBs = dir('/home/jl20461/GBIS_V1.1_BULK/Bounding_Boxes/*_BoundingBox_2_MaskVolc_ICA.mat');
OtsuMasks = dir('/home/jl20461/GBIS_V1.1_BULK/Bounding_Boxes/*_LargestMask_2_MaskVolc_ICA.mat');


for i = 1:length(ICAs)
    disp(num2str(i))

    % Define filepaths
    OriginalData = strcat(OrigData(i).folder,'/',OrigData(i).name);
    MaskData = strcat(Masks(i).folder,'/',Masks(i).name);
    SlidingWindow = strcat(SlidingWindows(i).folder,'/',SlidingWindows(i).name);
    ICAData = strcat(ICAs(i).folder,'/',ICAs(i).name);
    OtsuBB = strcat(OtsuBBs(i).folder,'/',OtsuBBs(i).name);
    OtsuMask = strcat(OtsuMasks(i).folder,'/',OtsuMasks(i).name);

    % Generate DMR from volcano
    VolcName = OrigData(i).name(1:end-4);
    InvResFile = strcat('/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/',VolcName,RunName,'/invert_1_M/invert_1_M/invert_1_M.mat');
    PlotDMR_UNW_Wrapped(InvResFile,['/ICA_DMRs/',VolcName]);
    DMRData = dir(['/home/jl20461/GBIS_V1.1_BULK/ICA_DMRs/',VolcName,'*DS.mat']);
    DMRData = strcat(DMRData(1).folder,'/',DMRData(1).name);

    f = figure()
    t = tiledlayout(3,2,"TileSpacing","compact","Padding","compact");

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

    % ICA + Sliding window and clustering results
    nexttile
    ICA = load(ICAData);
    imagesc(ICA.ICA_Reconstructed_Disp./1000,"AlphaData",ICA.ICA_Reconstructed_Disp~=0);
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
    imagesc(ICA.ICA_Reconstructed_Disp./1000,"AlphaData",ICA.ICA_Reconstructed_Disp~=0);
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
    saveas(f,['/home/jl20461/GBIS_V1.1_BULK/PreProcessingFigs/',VolcName,'_PreProcessingLast.svg']);
    saveas(f,['/home/jl20461/GBIS_V1.1_BULK/PreProcessingFigs/',VolcName,'_PreProcessingLast.png']);

    OrigLastStep = Orig.LastStep;
    OrigLon = Orig.lon;
    OrigLat = Orig.lat;
    MaskLastStep = Mask.LastStep;
    ICA_Reconstructed = ICA.ICA_Reconstructed_Disp./1000;
    OtsuBR = OtsuFineBB.BoundingBox;

    save(['/home/jl20461/GBIS_V1.1_BULK/PreProcessingFigs/',VolcName,'_PreProcessingLast2.mat']...
        ,'OrigLastStep','OrigLon','OrigLat','MaskLastStep','ICA_Reconstructed','SlideWind','OtsuBR',...
        'CompMask','DMR');

    close all
end