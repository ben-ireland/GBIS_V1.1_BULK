function [BoundingBox, Image, OtsuFigure, SignalLocation, largest_component_mask] = ExtractSignalBoundingBoxCheck(BB_Shape, LastStep, numlevels, VolcName, SpatialRes, lon, lat)
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

duplicateMethod = 3; % 1== try second largest displament settings. 2== try second largest connected region. 3== try both at once
AlternativeBBMethod = 2; % 1== fully automated (take ath bounding box). 2== force manual drawn bounding box (flag).

SignalLocation.Flag = 0; % Initialise flag variable

% Create a grayscale ifg for input in Otsu thresholding
[Image] = IFG2GrayscalePNG(LastStep);

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

        if length(LastStep(labels==j))>200 %Ignore classes with <200 pixels
            AvgLOS(i,j) = abs(mean(LastStep(labels==j)));

            if AvgLOS>HighLOS
                HighLOS = AvgLOS{i}(j);
                OptLevel = numlevel;
                OptLabel = j;
            end
        end
    end

    % Start creating output plot
    labelsRGB = label2rgb(labels);
    imshow(labelsRGB,jet)
    title(['Segmented Image: ',num2str(i),' levels'],'Interpreter','none')
    clim([1 i+1])
    c = colorbar;
    c.Ticks = [1:1:i+1];
    c.Label.String = 'Region number';

        if i==numlevels
            % Initialise variables
            a=0;
            VolcanoOfSignal = 'Volcano1';
            IfgVolcano = 'Volcano2';

            while ~matches(VolcanoOfSignal, IfgVolcano)
                a=a+1;
                [~, ind] = maxk(AvgLOS(:),a);

                if duplicateMethod ==1 || duplicateMethod ==3
                    [colI, rowI] = ind2sub(size(AvgLOS), ind(a));
                else
                    [colI, rowI] = ind2sub(size(AvgLOS), ind(1));
                end

                OptLevel = colI;
                OptLabel = rowI;

                % Re-run Otsu thresholding with optimum number of levels for
                % the nth largest value
                levelnum = multithresh(Image,OptLevel);
                labels = imquantize(Image,levelnum);
                LastStep2 = LastStep;
                LastStep2(labels~=OptLabel) = NaN;
                LastStep2(LastStep2==0)= NaN;
                LastStep(LastStep==0)= NaN;
        
                % Bounding box - decide the size of the bounding box based on
                % the size of the resulting signal. (Option 1)
        
                % Find biggest connected region in the mask
                % Label connected components in the array
                labeled_array = bwlabel(~isnan(LastStep2),8);
                
                % Calculate the size of each connected component
                unique_labels = unique(labeled_array); % Find unique labels
                unique_labels = unique_labels(unique_labels>0);
                component_sizes = histc(labeled_array(:), unique_labels);
                
                % Find the label of the largest connected component
                [~, largest_component_label] = maxk(component_sizes,a);
        
                % Create a binary mask for the largest connected component
                if duplicateMethod ==2 || duplicateMethod ==3
                    largest_component_mask = (labeled_array == largest_component_label(a));
                else
                    largest_component_mask = (labeled_array == largest_component_label(1));
                end
        
                % Create mask based on highest LOS region in the optimum level
                % found in previous step
                LastStep2(largest_component_mask==0)=NaN;
    
                if BB_Shape ==1
                    % Find row and col index of max displacement in masked LOS
                    [~, linearIndex] = max(abs(LastStep2(:)));
                    
                    % Convert the linear index to row and column indices
                    [colIndex, rowIndex] = ind2sub(size(LastStep2), linearIndex);
        
                    [row, col] = find(~isnan(LastStep2)); %Find non NaN values
                    
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
                    maskArea = sum(largest_component_mask(:));
                    if maskArea >5000
                        PgonBuffer = polybuffer(PgonCoords.ConvexHull,'points',10);
                    else
                        PgonBuffer = polybuffer(PgonCoords.ConvexHull,'points',(10*(maskArea^(1/3))));
                    end
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
                    
                    % Check if the polygon is closest to the same GVP volcano as
                    % the interferogram
                    [VolcanoOfSignal, IfgVolcano, SignalLocation] = ClosestGVPVolcanoToSignal(lon,lat,BoundingBox,VolcName,SpatialRes);
                    disp (['Attempt: ',num2str(a),' | IFG Volcano: ',IfgVolcano,' | ','Signal Volcano: ',VolcanoOfSignal])
                    SignalLocation.Comment = '';
                if a==5
                    if AlternativeBBMethod == 1
                        disp('3 largest regions closer to another volcano, taking latest bounding box')
                        break
                    elseif AlternativeBBMethod == 2
                        disp('3 largest regions closer to another volcano, result flagged')
                        SignalLocation.Comment = strcat(SignalLocation.Comment,' Uncertain - 3 largest regions closer to another volcano');
                        SignalLocation.Flag = 1; %Flag whether the data needs expert review or not
                        break
                    end
                else
                    SignalLocation.Flag = 0; %Flag whether the data needs expert review or not
                end
                % Mask out previous polygon extent
                %PgonMask = PgonMask | poly2mask(x,y,size(LastStep,1),size(LastStep,2));
                %LastStep(PgonMask) = NaN;
            end
     
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
        end
        hold off
    end
    if length(SignalLocation.Comment) ==0
        SignalLocation.Comment = 'None';
    end
end