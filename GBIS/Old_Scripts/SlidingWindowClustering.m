function Location = SlidingWindowClustering(LastStep, TS_File)
    % Ben Ireland, September 2024, University of Bristol
    disp('Locating signal using sliding windows')

    if ~exist([pwd,'/SignalLocation'],'dir')
        mkdir(pwd,'SignalLocation')
        addpath([pwd,'/SignalLocation'])
    end

    LastStep(LastStep==0) = NaN;

    % Apply region shrinking to remove areas of poor unwrapping
    LastStep = IFG_Region_Shrink(-LastStep,500,3,TS_File.name(1:end-3),1);

    %WindowSize = [2,4,8,16,32,64,128];
    %WindowSize = 2:2:50;
    WindowSize = 2:25;
    X_range = round(0.2.*size(LastStep,1)) : round(0.8.*size(LastStep,1));
    Y_range = round(0.2.*size(LastStep,2)) : round(0.8.*size(LastStep,2));
    
    NaN_Threshold = 0.95;
    maxMeanValue = 0;
    OutMask = true(size(LastStep));
    OutMask(X_range,Y_range) = false;
    LastStep(OutMask) = NaN;

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
    f = figure()
    subplot(1,3,1)
    imagesc(LastStep,'AlphaData',~isnan(LastStep).*0.5)
    axis image
    hold on
    scatter(maxPixelCol,maxPixelRow,(maxMeanValue./max(maxMeanValue)*100),copper(length(WindowSize)),'filled')
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

    Epsilon = 50;
    minPts = 7;
    [idx, corePts] = dbscan(Points,Epsilon,minPts);
    [idx2, corePts2] = dbscan(Points2,Epsilon,minPts);

    % Extract bounding box of core points in the cluster with the most observations
    LocationMask = idx2 == mode(idx2(idx2~=-1)) & corePts2 ==1; % Find core points in largest non-noise cluster
    Locations = [maxPixelRow(LocationMask)', maxPixelCol(LocationMask)'];
    XLimits = [min(Locations(:,2)), max(Locations(:,2))];
    YLimits = [min(Locations(:,1)), max(Locations(:,1))];

    minBBSize = 20;
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
    [maxRow, maxCol] = ind2sub(size(bestBlock), maxIdx);
    % Convert local block coordinates to global image coordinates
    Pix_y = Location.Limits(1,2) + maxRow - 1;
    Pix_x = Location.Limits(1,1) + maxCol - 1;
    Location.pix = [Pix_y, Pix_x];

    subplot(1,3,2)
    gscatter(maxPixelCol,maxPixelRow,idx)
    xlim([0,size(LastStep,1)])
    ylim([0,size(LastStep,2)])
    set(gca,'YDir','reverse')
    title('Clustering - location')
    subtitle(['Epsilon: ',num2str(Epsilon)])
    axis square
    hold on
    %scatter(maxPixelCol(corePts),maxPixelRow(corePts),[],'*','white')

    subplot(1,3,3)
    gscatter(maxPixelCol,maxPixelRow,idx2)
    xlim([0,size(LastStep,1)])
    ylim([0,size(LastStep,2)])
    set(gca,'YDir','reverse')
    title('Clustering - location/mag')
    subtitle(['minPts: ',num2str(minPts)])
    axis square
    hold on
    scatter(maxPixelCol(corePts2),maxPixelRow(corePts2),15,'*','black')
    hold on
    plot(pgon)

    saveas(f,[pwd,'/SignalLocation/',TS_File.name(1:end-3),'_SlideWindow_Cluster50_7_Shrink_Alt_newBox.png'])
    save([pwd,'/SignalLocation/',TS_File.name(1:end-3),'_SlideWindow_Cluster50_7_Shrink_Alt_newBox.mat'],'Location','Points2','idx2','corePts2','WindowSize');
end