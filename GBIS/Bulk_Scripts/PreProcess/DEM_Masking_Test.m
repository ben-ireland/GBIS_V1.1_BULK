% Ben Ireland, July 2025
clear all; close all;
TS_Files = dir(['/scratch/Ben/EAR_Data/**/timeseries/*.nc']);
DEMs = dir('/scratch/Ben/EAR_Data/**/dem/*.tif');
BBs = dir('/scratch/Ben/GBIS_BULK/Bounding_Boxes/*_BoundingBox_2_MaskVolc_ICA_DS_BoundingBoxNoLast.mat');
%BBs = dir('/scratch/Ben/GBIS_BULK/Bounding_Boxes/*_BoundingBox_2_MaskVolc_ICA_DS_BoundingBox.mat');



for k = 1:length(TS_Files)
    TS_Filename = char(strcat(TS_Files(k).folder,'/',TS_Files(k).name));
    DEM_Filename = char(strcat(DEMs(k).folder,'/',DEMs(k).name));
    BB_Filename = char(strcat(BBs(k).folder,'/',BBs(k).name));

    % Process last step
    TS = ncread(TS_Filename,'DATA');
    TS = permute(TS,[2 1 3]);
    LastStep = TS(:,:,end);
    
    % Resize DEM if needed
    [DEM, ~] = readgeoraster(DEM_Filename);
    DEM = imresize(DEM,[size(LastStep,1), size(LastStep,2)]);
    DEM = double(DEM);

    % Identify far-field noise region
    [XCoords, YCoords] = meshgrid(1:size(LastStep,1),1:size(LastStep,2));
    load(BB_Filename)
    in = inpolygon(XCoords,YCoords,BoundingBox.Vertices(:,1),BoundingBox.Vertices(:,2));

    % Find DEM stats in near-field
    MeanElev = mean(DEM(in),'omitnan');
    StdElev = std(DEM(in),'omitnan');
    MaxElev = MeanElev + StdElev;
    MinElev = MeanElev - StdElev;

    % Mask far-field region
    Mask = ((DEM>MinElev & DEM<MaxElev)) | in==1;
    LastStep_DEMMask = LastStep.*Mask;
    DEM_Mask = DEM.*Mask;

    % Add additional buffer
    Poly2 = polybuffer(BoundingBox,size(LastStep,1).*0.05);
    Poly3 = polybuffer(BoundingBox,size(LastStep,1).*0.1);

    in2 = inpolygon(XCoords,YCoords,Poly2.Vertices(:,1),Poly2.Vertices(:,2));
    in3 = inpolygon(XCoords,YCoords,Poly3.Vertices(:,1),Poly3.Vertices(:,2));
    % Mask2 = ((DEM>MinElev & DEM<MaxElev)) | in2==1;
    % Mask3 = ((DEM>MinElev & DEM<MaxElev)) | in3==1;
    Mask2 = Mask & in2==1;
    Mask3 = Mask & in3==1;
    LastStep_DEMMask2 = LastStep.*Mask2;
    LastStep_DEMMask3 = LastStep.*Mask3;


    % Plot masks and save
    f = figure()
    t = tiledlayout(3,2,"TileSpacing","compact","Padding","compact",'TileIndexing','rowmajor');
    nexttile
    imagesc(DEM)
    axis image
    c = colorbar
    c.Label.String = 'Elevation (m)';
    clim([min(DEM(:)), max(DEM(:))]);
    subtitle(['Min elev lim: ',num2str(round(MinElev)),'m | ','Max elev lim: ',num2str(round(MaxElev)),'m']);
    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
    set(gca,'FontSize',8);
    box on

    nexttile
    hold on
    imagesc(DEM_Mask,'AlphaData',Mask)
    axis image
    clim([min(DEM(:)), max(DEM(:))]);
    % c = colorbar
    % c.Label.String = 'Elevation (m)';
    plot(BoundingBox,'FaceAlpha',0,'EdgeColor','k','LineStyle','-','DisplayName','Otsu box')
    plot(Poly2,'FaceAlpha',0,'EdgeColor','k','LineStyle',':','DisplayName','Otsu + 5% img width')
    plot(Poly3,'FaceAlpha',0,'EdgeColor','k','LineStyle','--','DisplayName','Otsu + 10% img width')
    set(gca,'YDir','reverse')
    l = legend('Location','eastoutside')
    fontsize(l,8,'points')
    subtitle(['Mean elev: ',num2str(round(MeanElev)),'m | ','Std elev: ',num2str(round(StdElev)),'m']);
    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
    set(gca,'FontSize',8);
    box on

    nexttile
    imagesc(LastStep,'AlphaData',LastStep~=0)
    axis image
    c = colorbar
    c.Label.String = 'LOS displacement (m)';
    clim([-max(abs(LastStep(:))), max(abs(LastStep(:)))]);
    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
    set(gca,'FontSize',8);
    box on

    nexttile
    hold on
    imagesc(LastStep_DEMMask,'AlphaData',LastStep~=0 & Mask)
    axis image
   % c = colorbar
    % c.Label.String = 'LOS displacement (m)';
    clim([-max(abs(LastStep(:))), max(abs(LastStep(:)))]);
    plot(BoundingBox,'FaceAlpha',0,'EdgeColor','k','LineStyle','-','DisplayName','Otsu box')
    plot(Poly2,'FaceAlpha',0,'EdgeColor','k','LineStyle',':','DisplayName','Otsu + 5% img width')
    plot(Poly3,'FaceAlpha',0,'EdgeColor','k','LineStyle','--','DisplayName','Otsu + 10% img width')
    set(gca,'YDir','reverse')
    l = legend('Location','eastoutside')
    fontsize(l,8,'points')
    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
    set(gca,'FontSize',8);
    box on

    nexttile
    imagesc(LastStep_DEMMask2,'AlphaData',LastStep_DEMMask2~=0 & Mask2)
    axis image
    c = colorbar
    c.Label.String = 'LOS displacement (m)';
    clim([-max(abs(LastStep(:))), max(abs(LastStep(:)))]);
    set(gca,'YDir','reverse')
    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
    set(gca,'FontSize',8);
    box on

    nexttile
    imagesc(LastStep_DEMMask3,'AlphaData',LastStep_DEMMask3~=0 & Mask3)
    axis image
    % c = colorbar
    % c.Label.String = 'LOS displacement (m)';
    clim([-max(abs(LastStep(:))), max(abs(LastStep(:)))]);
    set(gca,'YDir','reverse')
    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
    set(gca,'FontSize',8);
    box on

    saveas(f,['/scratch/Ben/GBIS_BULK/TestFigs/DEMsTest/DEM_Mask_',TS_Files(k).name(1:end-3),'NoLast.png']);
    %saveas(f,['/scratch/Ben/GBIS_BULK/TestFigs/DEMsTest/DEM_Mask_',TS_Files(k).name(1:end-3),'.png']);
end