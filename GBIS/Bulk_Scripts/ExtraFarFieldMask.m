function [DefImgMasked, DefImg] = ExtraFarFieldMask(TS_Files,DefImg,BoundingBox,Options)
    % Ben Ireland, July 2025
    % Automatically mask far-field data based on DEM or buffered near-field/far-field boundary
    
    disp('Applying additional masking')
    % Create output folder
    if ~exist([pwd,'/FarfieldMasks'],'dir')
        mkdir(pwd,'FarfieldMasks')
        addpath([pwd,'/FarfieldMasks'])
    end

    rad2m = Options.WavelengthM./(4.*pi);

    % Identify far-field noise region
    [XCoords, YCoords] = meshgrid(1:size(DefImg,1),1:size(DefImg,2));
    in = inpolygon(XCoords,YCoords,BoundingBox.Vertices(:,1),BoundingBox.Vertices(:,2));
    
    if Options.FarFieldMaskMethod == 1 || Options.FarFieldMaskMethod ==3
        % Reconstruct DEM filename
        DEM_Folder = dir([extractBefore(TS_Files.folder,'timeseries'),'dem/*.tif']);
        DEM_Filename = strcat(DEM_Folder.folder,'/',DEM_Folder.name);
        
        % Resize DEM if needed
        [DEM, ~] = readgeoraster(DEM_Filename);
        DEM = imresize(DEM,[size(DefImg,1), size(DefImg,2)]);
        DEM = double(DEM);

        % Find DEM stats in near-field
        MeanElev = mean(DEM(in),'omitnan');
        StdElev = std(DEM(in),'omitnan');
        MaxElev = MeanElev + (StdElev*Options.FarFieldDEM_StdLimit);
        MinElev = MeanElev - (StdElev*Options.FarFieldDEM_StdLimit);

        % Mask far-field region
        Mask = double(((DEM>MinElev & DEM<MaxElev)) | in==1);
        Mask(Mask==0)=NaN;
        DefImg_DEMMask = DefImg.*Mask;
        DEM_Mask = DEM.*Mask;

        DefImgMasked = DefImg_DEMMask;
        MaskMethod = ['DEM_',num2str(Options.FarFieldDEM_StdLimit)];

        if Options.FarFieldMaskMethod ==3
            % Add additional buffer to near-field region and mask outside that
            Poly2 = polybuffer(BoundingBox,size(DefImg,1).*(Options.FarFieldAdditionalBuffer/100));
            in2 = inpolygon(XCoords,YCoords,Poly2.Vertices(:,1),Poly2.Vertices(:,2));
            Mask = double(Mask==1 & in2==1);
            Mask(Mask==0)=NaN;
            DefImg_DEMMask2 = DefImg.*Mask;
            DefImgMasked = DefImg_DEMMask2;
            MaskMethod = ['DEM_and_Near-field buffer',num2str(Options.FarFieldDEM_StdLimit),'_',num2str(Options.FarFieldAdditionalBuffer)];
        end

    elseif Options.FarFieldMaskMethod == 2
        % Add additional buffer to near-field region and mask outside that
        Poly2 = polybuffer(BoundingBox,size(DefImg,1).*(Options.FarFieldAdditionalBuffer/100));
        in2 = inpolygon(XCoords,YCoords,Poly2.Vertices(:,1),Poly2.Vertices(:,2));
        Mask = double(in2==1);
        Mask(Mask==0)=NaN;
        DefImg_DEMMask2 = DefImg.*Mask;
        DefImgMasked = DefImg_DEMMask2;
        MaskMethod = ['Near-field buffer_',num2str(Options.FarFieldAdditionalBuffer)];
    end

    % Find newly masked areas
    OldMasked = isnan(DefImg);
    Incoherent = DefImg==0;
    NewMasked = isnan(DefImgMasked) + OldMasked;
    NewMasked = NewMasked + 1;
    NewMasked(Incoherent)=0;

    % Plot before and after masking
    f = figure();
    t = tiledlayout(2,2,"TileSpacing","compact","Padding","compact",'TileIndexing','rowmajor');

    nexttile
    hold on
    imagesc(-DefImg.*rad2m,'AlphaData',~isnan(DefImg) & DefImg~=0)
    axis image
    c = colorbar;
    c.Label.String = 'LOS displacement (m)';
    c.Location = "westoutside";
    clim([-max(abs(DefImg(:).*rad2m)), max(abs(DefImg(:).*rad2m))]);
    plot(BoundingBox,'FaceAlpha',0,'EdgeColor','k','LineStyle','-','DisplayName','Otsu box')
    if Options.FarFieldMaskMethod == 2 || Options.FarFieldMaskMethod == 3
        plot(Poly2,'FaceAlpha',0,'EdgeColor','k','LineStyle',':','DisplayName','Otsu + 5% img width')
    end
    set(gca,'YDir','reverse')
    %l = legend('Location','eastoutside');
    title('Input deformation image')
    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
    set(gca,'FontSize',8);
    box on

    nexttile
    hold on
    imagesc(-DefImgMasked.*rad2m,'AlphaData',~isnan(DefImgMasked) & DefImgMasked~=0)
    axis image
    clim([-max(abs(DefImg(:).*rad2m)), max(abs(DefImg(:).*rad2m))]);
    plot(BoundingBox,'FaceAlpha',0,'EdgeColor','k','LineStyle','-','DisplayName','Otsu box')
    if Options.FarFieldMaskMethod == 2 || Options.FarFieldMaskMethod == 3
        plot(Poly2,'FaceAlpha',0,'EdgeColor','k','LineStyle',':','DisplayName','Otsu + 5% img width')
    end
    set(gca,'YDir','reverse')
    l = legend('Location','eastoutside');
    title('Output deformation image')
    subtitle(['Method: ',MaskMethod],"interpreter","none")
    fontsize(l,8,'points');
    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
    set(gca,'FontSize',8);
    box on

    ax2 = nexttile;
    hold on
    imagesc(OldMasked,'AlphaData',OldMasked)
    axis image
    set(gca,'YDir','reverse')
    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
    set(gca,'FontSize',8);   
    title('Masked pixels (before)')
    box on

    ax2 = nexttile;
    hold on
    imagesc(NewMasked,'AlphaData',NewMasked)
    axis image
    colormap(ax2,[1 1 1;
          0 0 1;       
          1 0 0;
          0 1 0]);      
    caxis([0 3]);
    hold on;
    h0 = patch(NaN, NaN, [1 1 1]);  
    h1 = patch(NaN, NaN, [0 0 1]);  
    h2 = patch(NaN, NaN, [1 0 0]);
    h3 = patch(NaN, NaN, [0 1 0]);
    legend([h0 h1 h2 h3], {'Incoherent','Retained', 'Removed', 'Other Volcanoes',},"Location","eastoutside"); 
    set(gca,'YDir','reverse')
    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
    set(gca,'FontSize',8);     
    title('Masked pixels (after)')
    box on

    if Options.IgnoreLastStep ==1
        saveas(f,['/scratch/Ben/GBIS_BULK/FarfieldMasks/DEM_Mask_',TS_Files.name(1:end-3),'_',MaskMethod,'NoLast.png']);
    elseif Options.IgnoreLastStep ==0
        saveas(f,['/scratch/Ben/GBIS_BULK/FarfieldMasks/DEM_Mask_',TS_Files.name(1:end-3),'_',MaskMethod,'.png']);
    end
end