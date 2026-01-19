function [BoundingBox, Image, OtsuFigure, SignalLocation, largest_component_mask] = Step4_ExtractOtsuBoundingBoxV2(LastStep, Location, VolcName, lon, lat, Options)
% Ben Ireland, University of Bristol, October 2023
% Function to extract signal bounding boxes from interferograms to be used
% in efficient downsampling of the image using multi-level Otsu
% thresholding

%%%%%%%%%%%%%%%%%%%%%%%%%% INPUT VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  BB_Shape: 1 = rectangular bounding box, 2 = bounding box polygon the
%  same shape as the signal
%
%  LastStep: unwrapped interferogram containing a signal
%
%  numlevels: number of levels of Otsu thresholding to try. 5 recommended
%
%  VolcName: =  Volcano Name or unique identifier for the data
%
%%%%%%%%%%%%%%%%%%%%%%%%%% OUTPUT VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  BoundingBox: Polyshape object of the bounding box
% 
%  Image: 0-255 matrix of the Grayscale interferogram used in the
%  thresholding
% 
%  OtsuFigure: Figure object giving a summary of the Otsu thresholding
%  results
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Extra = '';
if Options.MaskVolcs ==1
    Extra = append(Extra,'_MaskVolc');
end

if Options.ICA ==1
    Extra = append(Extra,'_ICA');
end

numlevels = Options.Otsu_NumLevels;
BB_Shape = Options.Otsu_BB_Shape;
SpatialRes = Options.SpatialRes;
SignalLocation.Flag = 0; % Initialise flag variable

LastStepOrig = LastStep;
% Apply region shrinking to remove areas of poor unwrapping (if the coherence of the image is not poor e.g. <0.25)
if sum(nnz(LastStep(:)))/numel(LastStep) > Options.Otsu_RegionShrinkCohThresh
    LastStep = IFG_Region_Shrink(LastStep, Options.Otsu_RegionShrink_MinPts, Options.Otsu_RegionShrink_DiskSize,VolcName,0);
end

% Create a grayscale ifg for input in Otsu thresholding
[Image] = IFG2GrayscalePNG(LastStep,Options);

% Calulate threshold and convert image (multiple threshold) using
% Otsu thresholding across the given number of levels

HighLOS=0;
AvgLOS = zeros(numlevels,length(numlevels)+1);
PgonMask = false(size(LastStep,1),size(LastStep,2));
OtsuFigure = figure()
for i=1:numlevels
    subplot(3,2,i)
    levelnum = multithresh(Image,i);
    labels = imquantize(Image,levelnum);
    
    % Across all thresholding levels, find which region and level has the highest weighted
    % LOS
    for j=1:length(levelnum)+1
        numlevel = length(levelnum);

        if length(LastStep(labels==j))>Options.Otsu_MinClassSize %Ignore classes with <200 pixels

            % Extract connected components
            BW_Mask = labels==j;
            CC = bwconncomp(BW_Mask,Options.Otsu_RegionConnectivity);
            AllCCs{i,j} = CC;
            stats = regionprops("table",CC,"Area","ConvexHull");
            stats(stats.Area < Options.Otsu_MinConCompSize,:)=[]; % Delete connected components with less than 100 pixels
            
            % Find which connected component completely overlaps the sliding window ROI
            LocationMask = poly2mask(Location.pgon.Vertices(:,1),Location.pgon.Vertices(:,2),size(LastStep,1),size(LastStep,2));
            %LocationMask = LocationMask==1 & LastStep~=0; 
            %TestLOS = mean(LastStep(LocationMask),'omitnan');
            Overlap = [];
            for k = 1:size(stats,1) % Loop through each connected component
                MaskAreaBefore = cell2mat(stats{k,2});
                MaskAreaBefore = poly2mask(MaskAreaBefore(:,1),MaskAreaBefore(:,2),size(LastStep,1),size(LastStep,2));
                
                if sum(MaskAreaBefore(:))/numel(Image)> Options.Otsu_SizeLimit % To prevent large background regions being chosen due to their overlap
                    continue
                end
                MaskAfter = MaskAreaBefore;
                MaskAfter(LocationMask==1) = 1; % Set up binary mask of location estimate

                % Work out which proportion of the connected component overlaps with the location estimate
                Overlap(k) = 1 - ((sum(MaskAfter(:)) - sum(MaskAreaBefore(:))) / sum(LocationMask(:)));


                if Overlap(k) == 1 % If it fully overlaps, take this component
                    AvgLOSMask(i,j) = mean(abs(LastStep(MaskAreaBefore==1)),'omitnan');
                    MaskCC{i,j} = MaskAreaBefore;
                    break
                end

                FullOverlaps(i,j,k) = Overlap(k);
                FullMaskBefore(i,j,k) = sum(MaskAreaBefore(:));
                FullMaskAfter(i,j,k) = sum(MaskAfter(:));
                FullLocMask(i,j,k) = sum(LocationMask(:));
                
                if k==size(stats,1) % After going through all connected components
                    [MaxOverlap, idx] = max(Overlap); % Find which connected component had the greatest overlap with the location estimate
                    
                    AllOverlaps(i,j) = MaxOverlap; % Add this to overlaps from other segments (i) and regions (j)
                    AltMaskAreaBefore = cell2mat(stats{idx,2});
                    AltMaskAreaBefore = poly2mask(AltMaskAreaBefore(:,1),AltMaskAreaBefore(:,2),size(LastStep,1),size(LastStep,2)); % Create mask of this connected component
                    AllAvgLOS(i,j) = mean(abs(LastStep(AltMaskAreaBefore==1)),'omitnan'); % Work out average LOS within this connected component
                    AllMaskCC{i,j} = MaskAreaBefore; % Make mask of the connected component
                    AllMaskCC2{i,j} = AltMaskAreaBefore; % Make mask of the connected component

                    disp(['Segment ',num2str(i),'| Class ',num2str(j),'| Overlap: ',num2str(MaxOverlap)])
                    % If no connected components overlap it a lot, set the average disp to zero
                    if MaxOverlap < Options.Otsu_MaxOverlap % Check if max overlap is greater than the threshold
                        AvgLOSMask(i,j)=0;
                        MaskCC{i,j} = [];
                    else % If a connected component overlaps >80% of it, take that value for that level and segment
                        MaskAreaBefore = cell2mat(stats{idx,2});
                        MaskAreaBefore = poly2mask(MaskAreaBefore(:,1),MaskAreaBefore(:,2),size(LastStep,1),size(LastStep,2));

                        AvgLOSMask(i,j) = mean(abs(LastStep(MaskAreaBefore==1)),'omitnan');
                        MaskCC{i,j} = MaskAreaBefore;
                    end
                end
            end
        end
    end

    % Start creating output plot
    labelsRGB = label2rgb(labels);
    
    OtsuOutputs(:,:,i) = labels; 
    imshow(labelsRGB,jet)
    title(['Segmented Image: ',num2str(i),' levels'],'Interpreter','none')
    clim([1 i+1])
    c = colorbar;
    c.Ticks = [1:1:i+1];
    c.Label.String = 'Region number';

    if i==numlevels
        if max(AvgLOSMask(:)) ~=0 % In case no regions overlap well, take the highest disp region out of highest overlapping region for each segment/class combo
            [~, ind] = max(AvgLOSMask(:));
            [rowI, colI] = ind2sub(size(AvgLOSMask), ind);
            largest_component_mask = MaskCC{rowI,colI};
        else
            [~, ind] = max(AllAvgLOS(:));
            [rowI, colI] = ind2sub(size(AllAvgLOS), ind);
            largest_component_mask = AllMaskCC{rowI,colI};
        end

        OptLevel = rowI;
        OptLabel = colI;

        if BB_Shape ==1
            % Find row and col index of max displacement in masked LOS
            [~, linearIndex] = max(abs(LastStep(:)));
            
            % Convert the linear index to row and column indices
            [colIndex, rowIndex] = ind2sub(size(LastStep), linearIndex);

            [row, col] = find(~isnan(LastStep)); %Find non NaN values
            
            Buffer = 100;
            BoundingGeo = [max(row), max(col); min(row), min(col)];
           
            % Create buffer and cap and min and max indicies
            BoundingGeo(1, :) = BoundingGeo(1, :) + Buffer;
            BoundingGeo(2, :) = BoundingGeo(2, :) - Buffer;
            BoundingGeo(1, 1) = min(BoundingGeo(1, 1), size(LastStep,1));
            BoundingGeo(1, 2) = min(BoundingGeo(1, 2), size(LastStep,2));
            BoundingGeo(2, :) = max(BoundingGeo(2, :), 0);

            % Create polygon
            x = [BoundingGeo(2, 2), BoundingGeo(1, 2), BoundingGeo(1, 2), BoundingGeo(2, 2)];
            y = [BoundingGeo(2, 1), BoundingGeo(2, 1), BoundingGeo(1, 1), BoundingGeo(1, 1)];
    
        elseif BB_Shape ==2
            % Create convex hull of the largest connected region
            PgonCoords = regionprops(largest_component_mask,'ConvexHull');

            % Buffer coordinates and create convex hull of
            % buffered polygon (convhull generally ensures more of
            % the signal is captured)
            MaskAreaCount = largest_component_mask ==1 & ~isnan(LastStep);
            maskArea = sum(MaskAreaCount(:)); % Changed to account for incoherent areas
            newCoords = PgonCoords.ConvexHull;
            BuffDist = -maskArea^(1/2) + size(LastStep,1)./4;
            if BuffDist <25
                BuffDist = 25;
            end
            PgonBuffer = polybuffer(newCoords,'points',BuffDist);
            PgonBuffer = convhull(PgonBuffer);
            BufferCoords = PgonBuffer.Vertices;

            BufferCoords(:,1) = min(BufferCoords(:,1), size(LastStep,1));
            BufferCoords(:,2) = min(BufferCoords(:,2), size(LastStep,2));
            BufferCoords = max(BufferCoords, 0);
            
            x = BufferCoords(:,1);
            y = BufferCoords(:,2);
        end

        % Create bounding box
        BoundingBox = polyshape(x,y);
        BoundingBoxMask = poly2mask(BoundingBox.Vertices(:,1),BoundingBox.Vertices(:,2),size(LastStep,1),size(LastStep,2));

        % Check if the polygon is closest to the same GVP volcano as
        % the interferogram
        VolcanoOfSignal = 'Volcano1';
        IfgVolcano = 'Volcano2';
        a=1;
        [VolcanoOfSignal, IfgVolcano, SignalLocation] = ClosestGVPVolcanoToSignal(lon,lat,BoundingBox,VolcName,SpatialRes);
        disp (['Attempt: ',num2str(a),' | IFG Volcano: ',IfgVolcano,' | ','Signal Volcano: ',VolcanoOfSignal])
        SignalLocation.Comment = '';
        SignalLocation.Flag = 0;
        % Extract location of largest magnitude pixel within the bounding box area (for temporal parameter extraction)
        PgonMask = poly2mask(x,y,size(LastStep,1),size(LastStep,2));
        LastStepMask = abs(LastStep);
        LastStepMask(~PgonMask) = 0;
        [~, Maxidx] = max(LastStepMask(:));
        [SignalLocation.Pix(1), SignalLocation.Pix(2)] = ind2sub([size(LastStep,1), size(LastStep,2)],Maxidx);

        if SignalLocation.Pix(1) >400 || SignalLocation.Pix(2) >400 || SignalLocation.Pix(1) <100 || SignalLocation.Pix(2) <100
            SignalLocation.Flag = 1;
            SignalLocation.Comment = strcat(SignalLocation.Comment, ' Signal location near the edge of the frame - large offset');
        end

        % Finish plotting
        subplot(3,2,6)
        h = imagesc(LastStep)
        title('LOS displacement (m)')
        if SignalLocation.Flag ==1
            sgtitle({VolcName,['Opt. level: ',num2str(OptLevel),' | Opt. region: ',num2str(OptLabel)]...
                ,['Signal offset: ',num2str(SignalLocation.OffsetDistanceKm),' km at ',num2str(SignalLocation.OffsetBearing),' degrees'],...
                ['Number of attempts = ',num2str(a)],['Signal FLAGGED for review']},'interpreter','none')

            %subtitle({['Opt. level: ',num2str(OptLevel),' | Opt. region: ',num2str(OptLabel)]...
            %    ,['Signal offset: ',num2str(SignalLocation.OffsetDistanceKm),' km at ',num2str(SignalLocation.OffsetBearing),' degrees'],...
            %    ['Number of attempts = ',num2str(a)],['Signal FLAGGED for review']},'interpreter','none')
        else
            sgtitle({VolcName,['Opt. level: ',num2str(OptLevel),' | Opt. region: ',num2str(OptLabel)]...
                ,['Signal offset: ',num2str(SignalLocation.OffsetDistanceKm),' km at ',num2str(SignalLocation.OffsetBearing),' degrees'],...
                ['Number of attempts = ',num2str(a)],['Signal NOT FLAGGED for review']},'interpreter','none')
        end

        set(gca,'XTick',[])
        set(gca,'YTick',[])
        set(gca,'Xticklabel',[])
        set(gca,'Yticklabel',[])

        axis square
        c = colorbar;
        c.Label.String = 'LOS Disp. (m)';
        cmax = max(abs(LastStep(:)));
        clim([-cmax, cmax])
        colormap jet;
        set(h, 'AlphaData', ~isnan(LastStep))
        hold on
        plot(BoundingBox)
        hold on
        scatter(SignalLocation.Pix(2),SignalLocation.Pix(1),[],'r',"filled")
        hold on
        scatter(size(LastStep,1)/2,size(LastStep,2)/2,[],'b',"filled")
        hold on
        if BB_Shape==1
            plot(rowIndex,colIndex,'MarkerSize',10,'Marker','square','MarkerFaceColor','r')
        end

        if length(SignalLocation.Comment) ==0
            SignalLocation.Comment = 'None';
        end
    end
    hold off
    if i==numlevels
        OtsuGrayFilename = strcat(pwd,'/Bounding_Boxes/',VolcName,'GrayIfg','_Shape_',num2str(BB_Shape),'_',Options.RunID,Extra,'.png');
        OtsuFigFilename = strcat(pwd,'/Bounding_Boxes/',VolcName,'OtsuFig','_Shape_',num2str(BB_Shape),'_',Options.RunID,Extra,'.png');
        imwrite(uint8(Image),OtsuGrayFilename);
        saveas(OtsuFigure,OtsuFigFilename);
    end
end

    % Save Otsu results for each of the segment levels
    for k = 1:size(OtsuOutputs,3)
        f = figure();
        image(OtsuOutputs(:,:,k));
        numcolors=size(OtsuOutputs,3)+1;
        %numcolors = k+1;
        cblind = load('colorblind_colormap.mat');
        cmap = cblind.colorblind(1:numcolors,:);
        %cmap = lines(6);
        colormap(cmap);
        if k==size(OtsuOutputs,3)
            caxis([1 numcolors+1]);
            c = colorbar('YTick',...
            [(1:numcolors)+0.5],...
            'YTickLabel',int2str([1:numcolors]'), 'YLim', [1 numcolors+1]);
            %c = colorbar;
            c.Label.String = 'Region number';
            fontsize(gcf,16,"points")
        end
        axis image
        set(gca,'XTick',[]);
        set(gca,'YTick',[]);

        saveas(f,[pwd,'/Bounding_Boxes/',VolcName,'_Segment',num2str(k),'_',num2str(BB_Shape),Extra,'_',Options.RunID,'.png']);
    end
    save([pwd,'/Bounding_Boxes/',VolcName,'_Steps_',num2str(BB_Shape),Extra,'_',Options.RunID,'.mat'],"LastStepOrig","Image","LastStep","LocationMask","AllOverlaps","AllAvgLOS","largest_component_mask","maskArea","BoundingBox","BoundingBoxMask","BuffDist","AllCCs","AllMaskCC2","AllMaskCC","MaskCC","OptLevel","OptLabel","FullOverlaps","FullLocMask","FullMaskAfter","FullMaskBefore");
    save([pwd,'/Bounding_Boxes/',VolcName,'_BoundingBox_',num2str(BB_Shape),Extra,'_',Options.RunID,'.mat'],"BoundingBox");
    save([pwd,'/Bounding_Boxes/',VolcName,'_RegionShrinkResults_',num2str(BB_Shape),Extra,'_',Options.RunID,'.mat'],"LastStepOrig","LastStep");
    save([pwd,'/Bounding_Boxes/',VolcName,'_Segments_',num2str(BB_Shape),Extra,'_',Options.RunID,'.mat'],"OtsuOutputs");
    save([pwd,'/Bounding_Boxes/',VolcName,'_LargestMask_',num2str(BB_Shape),Extra,'_',Options.RunID,'.mat'],"largest_component_mask");
end