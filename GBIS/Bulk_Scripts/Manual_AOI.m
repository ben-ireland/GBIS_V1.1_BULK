function AOI = Manual_AOI(Name,lat,lon,MANUAL_Options)
    % Ben Ireland, November 2024, University of Bristol

    if strcmp(MANUAL_Options.AOIFmt,'shp')
        EXT = '.shp';
    elseif strcmp(MANUAL_Options.AOIFmt,'mat')
        EXT = '.mat';
    end

    file = dir([pwd,'/Manual_Inputs/AOI/',Name,MANUAL_Options.Manual_Suffix,EXT]);

    if isempty(file)
        disp('Could not find manual input file for Mask')
        disp('We looked for the file:')
        disp(strcat(pwd,'/Manual_Inputs/AOI/',Name,MANUAL_Options.Manual_Suffix,EXT))
        return
    end

    if strcmp(MANUAL_Options.AOIFmt,'shp')
        % Read in shapefile
        S = shaperead(strcat(file.folder,'/',file.name));

        % Compare to lat and lon grids of the InSAR data
        binaryArray = zeros(size(lat));

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
            binaryArray(inPoly) = 1;
        end

        AOI.Mask = binaryArray;

        % Turn it into a binary MATLAB array and save in same folder
        save([pwd,'/Manual_Inputs/AOI/',Name,MANUAL_Options.Manual_Suffix,'.mat'],'AOI');
        

    elseif strcmp(MANUAL_Options.AOIFmt,'mat')
        % Read in binary array
        AOI.Mask = load(strcat(file.folder,'/',file.name));

        % Check it is the same size as the InSAR data
        if size(AOI,1) ~= size(AOI,1) || size(AOI,2) ~= size(AOI,2)
            disp('Size of mask does not mask size of InSAR data')
            return
        end
    end

    boundaries = bwboundaries(AOI.Mask);
    AOI.pgon = polyshape(boundaries{1}(:,2),boundaries{1}(:,1));

    % Display the AOI
    lon1 = lon(1,:);
    lat1 = lat(:,1);

    f = figure;
    imagesc(lon1, lat1, AOI.Mask);
    %plot(Location.pgon)
    axis xy;
    xlabel('Longitude');
    ylabel('Latitude');
    title('Binary Array Representation of AOI');
    colormap(gray);
    colorbar;

    saveas(f,[pwd,'/Manual_Inputs/AOI/',Name,MANUAL_Options.Manual_Suffix,'.png'])

end