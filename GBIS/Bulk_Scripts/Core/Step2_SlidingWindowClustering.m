function Location = Step2_SlidingWindowClustering(LastStep, VolcName, Options)
    % Ben Ireland, September 2024, University of Bristol
    disp('Locating signal using sliding windows')

    if ~exist([pwd,'/SignalLocation'],'dir')
        mkdir(pwd,'SignalLocation')
        addpath([pwd,'/SignalLocation'])
    end

    cblind = load([pwd,'/GBIS/Bulk_Scripts/colorblind_colormap/colorblind_colormap.mat']);
    rad2m = Options.WavelengthM./(4.*pi);
    m2rad= (4.*pi)./Options.WavelengthM;

    LastStep(LastStep==0) = NaN;

    % Remove mean to normalise values
    LastStep = LastStep - mean(LastStep(:),'omitnan');

    if Options.SW_RegionShrink == 1
        % Apply region shrinking to remove areas of poor unwrapping
        LastStep = IFG_Region_Shrink(LastStep,Options.SW_RegionShrink_MinPts,Options.SW_RegionShrink_DiskSize,VolcName,1);
    end

    %WindowSize = [2,4,8,16,32,64,128];
    %WindowSize = 2:2:50;
    WindowSize = Options.SW_WindowSizes;
    if Options.SW_CropEdges == 1
        X_range = round(Options.SW_CropEdges_Mag.*size(LastStep,1)) : round((1-Options.SW_CropEdges_Mag).*size(LastStep,1));
        Y_range = round(Options.SW_CropEdges_Mag.*size(LastStep,2)) : round((1-Options.SW_CropEdges_Mag).*size(LastStep,2));
    end
    
    NaN_Threshold = Options.SW_NaN_Thresh;
    maxMeanValue = 0;
    OutMask = true(size(LastStep));
    if Options.SW_CropEdges == 1
        OutMask(X_range,Y_range) = false;
        LastStep(OutMask) = NaN;
    end

    % Find biggest region for different sliding windows
    for k = 1:length(WindowSize)
        maxMeanValue(k) = 0;
        for i = 1:(size(LastStep,1)-WindowSize(k)+1)
            for j = 1:(size(LastStep,2)-WindowSize(k)+1)
                block = LastStep(i:i+WindowSize(k)-1, j:j+WindowSize(k)-1);

                % Calculate the mean of the absolute values, ignoring NaNs
                if sum(sum(~isnan(block)))/numel(block) > NaN_Threshold
                    meanValue = abs(mean(block(~isnan(block)), 'all'));
                else
                    meanValue = 0;
                end
                
                % Update if this block has the largest mean absolute value
                if meanValue > maxMeanValue(k)
                    maxMeanValue(k) = meanValue;
                    bestBlockRow(k) = i;
                    bestBlockCol(k) = j;
                end
            end
        end

        if maxMeanValue(k) ==0
            maxPixelRow(k) = 0;
            maxPixelCol(k) = 0;
        else
            bestBlock = LastStep(bestBlockRow(k):bestBlockRow(k)+WindowSize(k)-1, bestBlockCol(k):bestBlockCol(k)+WindowSize(k)-1);

            [maxVal(k), maxIdx] = max(abs(bestBlock(k)));
            [maxRow, maxCol] = ind2sub(size(bestBlock), maxIdx);
            maxPixelRow(k) = bestBlockRow(k) + maxRow - 1;
            maxPixelCol(k) = bestBlockCol(k) + maxCol - 1;
        end
    end

    maxMeanValue(maxMeanValue==0) = NaN;

    % Visualise and cluster the results
    f = figure();
    subplot(1,3,1);
    imagesc(LastStep,'AlphaData',~isnan(LastStep).*0.5);
    axis image
    hold on
    scatter(maxPixelCol,maxPixelRow,(maxMeanValue./max(maxMeanValue)*100),copper(length(WindowSize)),'filled');
    title('Input data')
    subtitle('Lighter: larger window | Size: magnitude')
    hold off

    maxPixelRow(maxPixelRow==0) = NaN;
    maxPixelCol(maxPixelCol==0) = NaN;
    maxMeanValue(maxMeanValue==0) = NaN;

    valid = ~isnan(maxPixelRow) & ~isnan(maxPixelCol) & ~isnan(maxMeanValue);

    maxPixelRow = maxPixelRow(valid);
    maxPixelCol = maxPixelCol(valid);
    maxMeanValue = maxMeanValue(valid);

    Points = [maxPixelRow', maxPixelCol'];
    Points2 = [maxPixelRow', maxPixelCol', maxMeanValue'];

    Epsilon = Options.SW_DBSCAN_Eps;
    minPts = Options.SW_DBSCAN_MinPts;
    [idx, corePts] = dbscan(Points,Epsilon,minPts);
    [idx2, corePts2] = dbscan(Points2,Epsilon,minPts);

    if all(idx2==-1)
        % Edge case where all points come back as noise...take the value from max. pixel area
        [~, Chosen_Idx] = max(Points2(:,3));
        Locations = [maxPixelRow(Chosen_Idx)', maxPixelCol(Chosen_Idx)'];
    else
        % Extract bounding box of core points in the cluster with the most observations
        LocationMask = idx2 == mode(idx2(idx2~=-1)) & corePts2 ==1; % Find core points in largest non-noise cluster
        Locations = [maxPixelRow(LocationMask)', maxPixelCol(LocationMask)'];
    end
    XLimits = [min(Locations(:,2)), max(Locations(:,2))];
    YLimits = [min(Locations(:,1)), max(Locations(:,1))];

    minBBSize = Options.SW_MinBBSize;
    if (XLimits(2) - XLimits(1)) < minBBSize
        XStart = round(mean(XLimits));
        XLimits = [XStart-(minBBSize/2), XStart+(minBBSize/2)];
    end

    if (YLimits(2) - YLimits(1)) < minBBSize
        YStart = round(mean(YLimits));
        YLimits = [YStart-(minBBSize/2), YStart+(minBBSize/2)];
    end

    XCoords = [XLimits(1) XLimits(2) XLimits(2) XLimits(1)];
    YCoords = [YLimits(1) YLimits(1) YLimits(2) YLimits(2)];

    pgon = polyshape(XCoords,YCoords);  
    Location.Limits = [XLimits', YLimits'];
    Location.pgon = pgon;

    bestRows = Location.Limits(1,2):Location.Limits(2,2);
    bestCols = Location.Limits(1,1):Location.Limits(2,1);

    bestBlock = LastStep(bestRows,bestCols);
    [~, maxIdx] = max(abs(bestBlock(:)));
    MaxDef = max(bestBlock(:));
    [maxRow, maxCol] = ind2sub(size(bestBlock), maxIdx);
    % Convert local block coordinates to global image coordinates
    Pix_y = Location.Limits(1,2) + maxRow - 1;
    Pix_x = Location.Limits(1,1) + maxCol - 1;
    Location.pix = [Pix_y, Pix_x];

    subplot(1,3,2);
    gscatter(maxPixelCol,maxPixelRow,idx);
    xlim([0,size(LastStep,1)])
    ylim([0,size(LastStep,2)])
    set(gca,'YDir','reverse')
    title('Clustering - location')
    subtitle(['Epsilon: ',num2str(Epsilon)])
    axis square
    hold on
    %scatter(maxPixelCol(corePts),maxPixelRow(corePts),[],'*','white')

    subplot(1,3,3);
    gscatter(maxPixelCol,maxPixelRow,idx2);
    xlim([0,size(LastStep,1)])
    ylim([0,size(LastStep,2)])
    set(gca,'YDir','reverse')
    title('Clustering - location/mag')
    subtitle(['minPts: ',num2str(minPts)])
    axis square
    hold on
    scatter(maxPixelCol(corePts2),maxPixelRow(corePts2),15,'*','black');
    hold on
    plot(pgon)

    f2 = figure();
    subplot(1,2,1);
    imagesc(-LastStep*rad2m,'AlphaData',~isnan(LastStep));
    colormap(gcf, flipud(cbrewer2('RdBu', 256)));
    caxis([-0.1 0.1]);
    axis image
    hold on
    %c = colorbar('EastOutside');
    %c.Label.String = 'LOS Displacement (m)';
    % Create new colourmap (grey-black)
    cRamp = flipud(gray(100));
    cRamp = cRamp(20:end-10,:);
    newSize = length(WindowSize);
    origSize = 1:size(cRamp,1);
    newId = linspace(1,max(origSize),newSize);
    cRamp = interp1(origSize, cRamp, newId, 'linear');
    cRamp = max(0, min(1, cRamp));
    %cRamp = gray(length(WindowSize));
    scatter(maxPixelCol,maxPixelRow,(maxMeanValue./max(maxMeanValue)*40),cRamp(1:length(maxPixelCol),:),'MarkerFaceColor','flat');
    xticklabels({''});
    yticklabels({''});
    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
    hold off
    subplot(1,2,2)
    gscatter(maxPixelCol,maxPixelRow,idx2,cblind.colorblind(1:length(unique(idx2)),:),'o',[],'doleg','off','filled');
    xlim([0,size(LastStep,1)]);
    ylim([0,size(LastStep,2)]);
    set(gca,'YDir','reverse');
    axis square
    hold on
    plot(pgon,"EdgeColor",'k','FaceAlpha',0.3,'FaceColor','k');
    xlabel({''});
    ylabel({''});
    xticklabels({''});
    yticklabels({''});
    set(gca,'XTick',[]);
    set(gca,'YTick',[]);

    saveas(f,[pwd,'/SignalLocation/',VolcName,'_SlidingWindow_Clustering_',num2str(Options.SW_DBSCAN_Eps),'_',num2str(Options.SW_DBSCAN_MinPts),'_Box_',num2str(Options.SW_MinBBSize),'.png']);
    saveas(f2,[pwd,'/SignalLocation/',VolcName,'_SlidingWindow_Clustering_',num2str(Options.SW_DBSCAN_Eps),'_',num2str(Options.SW_DBSCAN_MinPts),'_Box_',num2str(Options.SW_MinBBSize),'clean.png']);
    if Options.IgnoreLastStep ==1
        saveas(f2,[pwd,'/SignalLocation/',VolcName,'_SlidingWindow_Clustering_',num2str(Options.SW_DBSCAN_Eps),'_',num2str(Options.SW_DBSCAN_MinPts),'_Box_',num2str(Options.SW_MinBBSize),'cleanNoLast.png']);
    else
        saveas(f2,[pwd,'/SignalLocation/',VolcName,'_SlidingWindow_Clustering_',num2str(Options.SW_DBSCAN_Eps),'_',num2str(Options.SW_DBSCAN_MinPts),'_Box_',num2str(Options.SW_MinBBSize),'cleanWithLast.png']);
    end
    save([pwd,'/SignalLocation/',VolcName,'_SlidingWindow_Clustering_',num2str(Options.SW_DBSCAN_Eps),'_',num2str(Options.SW_DBSCAN_MinPts),'_Box_',num2str(Options.SW_MinBBSize),'.mat'],'Location','Points2','idx2','corePts2','WindowSize','pgon',"LastStep","MaxDef");
end