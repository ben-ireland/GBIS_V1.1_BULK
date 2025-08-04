function [BoundingBox, Image, OtsuFigure] = ExtractSignalBoundingBox(BB_Shape, LastStep, numlevels, VolcName)
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

% Create a grayscale ifg for input in Otsu thresholding
[Image] = IFG2GrayscalePNG(LastStep);

% Calulate threshold and convert image (multiple threshold) using
% Otsu thresholding across the given number of levels

HighLOS=0;
OtsuFigure = figure();
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

            if AvgLOS(i,j)>HighLOS
                HighLOS = AvgLOS(i,j);
                OptLevel = numlevel;
                OptLabel = j;
            end
        end
    end

    % Start creating output plot
    labelsRGB = label2rgb(labels);
    imshow(labelsRGB,jet)
    title(['Segmented Image: ',num2str(i),' levels'],'Interpreter','none')
    sgtitle(VolcName,'interpreter','none')
    clim([1 i+1])
    c = colorbar;
    c.Ticks = [1:1:i+1];
    c.Label.String = 'Region number';

    if i==numlevels
        % Re-run Otsu thresholding with optimum number of levels

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
        [~, largest_component_label] = max(component_sizes);

        % Create a binary mask for the largest connected component
        largest_component_mask = (labeled_array == largest_component_label);

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
            maskArea = sum(largest_component_mask(:));

            PgonBuffer = polybuffer(PgonCoords.ConvexHull,'points',(10*(maskArea^(1/3))));
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

        % Finish plotting
        subplot(3,2,6)
        h = imagesc(LastStep)
        title('LOS displacement (m)')
        subtitle(['Opt. level: ',num2str(OptLevel),' | Opt. region: ',num2str(OptLabel)],'interpreter','none')
        axis square
        %colorbar
        set(h, 'AlphaData', ~isnan(LastStep))
        hold on
        plot(BoundingBox)
        if BB_Shape==1
            plot(rowIndex,colIndex,'MarkerSize',10,'Marker','square','MarkerFaceColor','r')
        end
    end
    hold off
end

    