function ImageAft = Manual_IFG_Region_Shrink(Image,minSize,DiskSize,Name,Fig)
    % Ben Ireland, September 2024, University of Bristol

    if ~exist([pwd,'/SignalLocation'],'dir')
        mkdir(pwd,'SignalLocation')
        addpath([pwd,'/SignalLocation'])
    end

    if ~exist([pwd,'/Manual_Inputs/RegionShrink'],'dir')
        mkdir(pwd,'Manual_Inputs/RegionShrink')
        addpath([pwd,'/Manual_Inputs/RegionShrink'])
    end

    Image(Image==0) = NaN; 

    % Prepare mask to identify NaN regions to be expanded
    BeforeMask = ones(size(Image,1),size(Image,2)) .* isnan(Image);
    CC = bwconncomp(BeforeMask,4);
    stats = regionprops('table',CC,'Area');
    bigArea = stats.Area<minSize; % minimum size NaN area (pixels) to expand 
    MaskPix = CC.PixelIdxList(bigArea);
    BeforeMask(vertcat(MaskPix{:})) = 0;

    % Expand areas using a disk structural element
    SE = strel("disk",DiskSize); % Radius in pixels of disk
    AfterMask = imdilate(BeforeMask,SE);

    % Apply new mask to image
    ImageAft = Image.*~AfterMask;
    ImageAft(ImageAft==0) = NaN;

    if Fig==1

        % Visualise results
        f = figure()
        subplot(2,2,1)
        imagesc(Image,'AlphaData',~isnan(Image))
        colormap jet
        axis image
        title('Before - image')
        xticklabels({''})
        yticklabels({''})
        set(gca,'XTick',[])
        set(gca,'YTick',[])
        %caxis([-0.1 0.1])

        subplot(2,2,2)
        imagesc(ImageAft,'AlphaData',~isnan(ImageAft))
        colormap jet
        axis image
        title('After - image')
        xticklabels({''})
        yticklabels({''})
        set(gca,'XTick',[])
        set(gca,'YTick',[])
        %caxis([-0.1 0.1])

        subplot(2,2,3)
        imshow(BeforeMask)
        colormap jet
        axis image
        title('Before - mask')
        xticklabels({''})
        yticklabels({''})
        set(gca,'XTick',[])
        set(gca,'YTick',[])

        subplot(2,2,4)
        imshow(AfterMask)
        colormap jet
        axis image
        title('After - mask')
        xticklabels({''})
        yticklabels({''})
        set(gca,'XTick',[])
        set(gca,'YTick',[])
        

        sgtitle(Name,'interpreter','none')

        saveas(f,[pwd,'/Manual_Inputs/RegionShrink/',Name,'_RegionShrink.png'])
    end
end