function Mask = Manual_ExtraMask(Name,lat,lon,MANUAL_Options)
    % Ben Ireland, November 2024, University of Bristol

    if strcmp(MANUAL_Options.MaskDataFmt,'shp')
        EXT = '.shp';
    elseif strcmp(MANUAL_Options.MaskDataFmt,'mat')
        EXT = '.mat';
    end

    file = dir([pwd,'/Manual_Inputs/Mask/',Name,MANUAL_Options.Manual_Suffix,EXT]);

    if isempty(file)
        disp('Could not find manual input file for Mask')
        disp('We looked for the file:')
        disp(strcat(pwd,'/Manual_Inputs/Mask/',Name,MANUAL_Options.Manual_Suffix,EXT))
        return
    end

    if strcmp(MANUAL_Options.MaskDataFmt,'shp')
        % Read in shapefile
        S = shaperead(strcat(file.folder,'/',file.name));

        % Compare to lat and lon grids of the InSAR data
        binaryArray = ones(size(lat));

        % Loop through each shape in the shapefile
        for k = 1:length(S)
            % Extract the polygon coordinates
            xPoly = S(k).X; % Longitude values of the polygon
            yPoly = S(k).Y; % Latitude values of the polygon

            % Remove NaN values from polygons
            nanMask = isnan(xPoly) | isnan(yPoly);
            xPoly(nanMask) = [];
            yPoly(nanMask) = [];

            % Create a logical mask for the polygon area
            inPoly = inpolygon(lon, lat, xPoly, yPoly);

            % Update the binary array
            binaryArray(inPoly) = 0;
        end

        % Display the binary array
        f = figure;
        imagesc(lon(1,:), lat(:,1), binaryArray);
        axis xy;
        xlabel('Longitude');
        ylabel('Latitude');
        title('Binary Array Representation of Shapefile');
        colormap(gray);
        colorbar;

        saveas(f,[pwd,'/Manual_Inputs/Mask/',Name,MANUAL_Options.Manual_Suffix,'.png'])
        % Turn it into a binary MATLAB array and save in same folder
        save([pwd,'/Manual_Inputs/Mask/',Name,MANUAL_Options.Manual_Suffix,'.mat'],'binaryArray');
        Mask = binaryArray;

    elseif strcmp(MANUAL_Options.MaskDataFmt,'mat')
        % Read in binary array
        Mask = load(strcat(file.folder,'/',file.name));

        % Check it is the same size as the InSAR data
        if size(Mask,1) ~= size(lat,1) || size(Mask,2) ~= size(lat,2)
            disp('Size of mask does not mask size of InSAR data')
            return
        end
    end

end