function Location = Manual_Location(Name,lat,lon,MANUAL_Options)
    % Ben Ireland, November 2024, University of Bristol

    if strcmp(MANUAL_Options.LocationFmt,'shp')
        EXT = '.shp';
    elseif strcmp(MANUAL_Options.LocationFmt,'mat')
        EXT = '.mat';
    end

    file = dir([pwd,'/Manual_Inputs/Location/',Name,MANUAL_Options.Manual_Suffix,EXT]);

    if isempty(file)
        disp('Could not find manual input file for Mask')
        disp('We looked for the file:')
        disp(strcat(pwd,'/Manual_Inputs/Location/',Name,MANUAL_Options.Manual_Suffix,EXT))
        return
    end

    if strcmp(MANUAL_Options.LocationFmt,'shp')
        % Read in shapefile
        S = shaperead(strcat(file.folder,'/',file.name));

        Location = [S.X, S.Y];

        % Display the point coordinates
        fprintf('Point Coordinates: Longitude = %.6f, Latitude = %.6f\n', Location(1), Location(2));

        % Convert into pixel coordinates
        IdxX = knnsearch(lon(1,:)',Location(1));
        IdxY = knnsearch(lat(:,1),Location(2));

        Location = [IdxY, IdxX];
        fprintf('Pixel Coordinates: X = %.1f, Y = %.1f\n', IdxX, IdxY);

        % Turn it into a binary MATLAB array and save in same folder
        save([pwd,'/Manual_Inputs/Location/',Name,MANUAL_Options.Manual_Suffix,'.mat'],'Location');

    elseif strcmp(MANUAL_Options.LocationFmt,'mat')
        % Read in binary array
        Location = load(strcat(file.folder,'/',file.name));

        % Check it contains a 1x2 vector in form [pix_x, pix_y]
        if size(Location,1) ~= 1 || size(Location,2) ~= 2
            disp('Size of mask does not mask size of InSAR data')
            return
        end
    end

end