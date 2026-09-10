function Filename = Standalone_h5_to_MAT_V2(TS_Files,Heading_deg,Incidence_deg,OutName,Outfolder,Wavelength_m,Fig,Save,crop)
    m2rad= (4.*pi)./Wavelength_m;
    rad2m= Wavelength_m./(4.*pi);

    % Main code
    % Load imagery
    LOS = h5read(char(strcat(TS_Files.folder,'/',TS_Files.name)),'/cum');
    cLat = h5read(char(strcat(TS_Files.folder,'/',TS_Files.name)),'/corner_lat');
    cLon = h5read(char(strcat(TS_Files.folder,'/',TS_Files.name)),'/corner_lon');
    postLat = h5read(char(strcat(TS_Files.folder,'/',TS_Files.name)),'/post_lat');
    postLon = h5read(char(strcat(TS_Files.folder,'/',TS_Files.name)),'/post_lon');
    endLat = (size(LOS,1)-1)*postLat + cLat;
    endLon = (size(LOS,1)-1)*postLon + cLon;
    lat1 = cLat:postLat:endLat;
    lon1 = cLon:postLon:endLon;
    ImDates = h5read(char(strcat(TS_Files.folder,'/',TS_Files.name)),'/imdates');
    DatesDT = datetime(ImDates,'ConvertFrom','yyyymmdd');
    LOS = permute(LOS,[2,1,3]); % To get in correct dimensions format (lat,lon,disp)

    if crop.Lat.do==1
        disp('Cropping timeseries in Lat')
        StartLat = crop.Lat.Start;
        EndLat = crop.Lat.End;
        disp('Requested start lat is: ')
        disp(num2str(StartLat))
        disp('Requested end lat is: ')
        disp(num2str(EndLat))

        LatIdxs = lat>=StartLat & lat<=EndLat;
        LOS = LOS(LatIdxs,:,:);
    end

    if crop.Lon.do==1
        disp('Cropping timeseries in Lon')
        StartLon = crop.Lon.Start;
        EndLon = crop.Lon.End;
        disp('Requested start lat is: ')
        disp(num2str(StartLon))
        disp('Requested end lat is: ')
        disp(num2str(EndLon))

        LonIdxs = lon>=StartLat & lon<=EndLat;
        LOS = LOS(:,LonIdxs,:);
    end

    if crop.Time.do==1
        disp('Cropping timeseries in time')
        StartDate = datetime(string(crop.Time.start),'InputFormat','yyyyMMdd');
        EndDate = datetime(string(crop.Time.end),'InputFormat','yyyyMMdd');
        disp('Requested start date is: ')
        disp(StartDate)
        disp('Requested end date is: ')
        disp(EndDate)
        
        % Find closest date to StartDate and EndDate
        [~, StartDateIdx] = min(abs(time2num((datetime(dates,'InputFormat','yyyy-MM-dd') - StartDate),"days")));
        [~, EndDateIdx] = min(abs(time2num((datetime(dates,'InputFormat','yyyy-MM-dd') - EndDate),"days")));

        disp('Closest start date is: ')
        disp(datetime(dates(StartDateIdx),'InputFormat','yyyy-MM-dd'))
        disp('Closest end date is: ')
        disp(datetime(dates(EndDateIdx),'InputFormat','yyyy-MM-dd'))

        LOS = LOS(:,:,StartDateIdx:EndDateIdx);
        dates = dates(StartDateIdx:EndDateIdx);
        daysDT = daysDT(StartDateIdx:EndDateIdx);
    else
        disp('NOT Cropping timeseries')
    end

    % if Crop==1
    %     Img = LOS(:,:,CropEnd) - LOS(:,:,CropStart);
    % else
    %     Img = LOS(:,:,end);
    % end

    % Make square if not square
    if size(Img,1) ~= size(Img,2)
        disp("Making arrays square")
        [lon1,lat1,Img] = MakeSquare(lon1,lat1,Img);
    end

    % Make lat/lon grids
    [lon,lat] = meshgrid(lon1,lat1);

    % lon = lon1.';
    % lon = repmat(lon,(length(lon)),1);
    % lat = repmat(lat1,1,(length(lat1)));

    % % Set any NaN values to zero
    % Img(isnan(Img)) = 0;

    % Convert to metres
    % Img = Img .* rad2m;
    Img = Img / 1000; % Convert to m from mm
    Img = Img .* m2rad; % Convert to radians
    Img = -Img; % GBIS convention - phase is +ive away from satellite

    if Fig ==1
        f = figure();
        imagesc(lon1,lat1,Img,"AlphaData",Img~=0 & ~isnan(Img))
        axis image
        c = colorbar;
        c.Label.String = 'Phase change (radians, +ive away from satellite)';
        set(gca,'YDir','normal')
        saveas(f,strcat(Outfolder,"/",OutName,".png"))
    end

    % Name based on GBIS conventions
    Phase = Img;
    Lat = lat;
    Lon = lon;
    Heading = zeros(size(Phase)) + Heading_deg;
    Inc = zeros(size(Phase)) + Incidence_deg;
    Filename = strcat(Outfolder,'/',OutName,'.mat');
    if Save==1
        save(strcat(Outfolder,'/',OutName,'.mat'),"Phase","Lat","Lon","Heading","Inc");
    end

    close all
