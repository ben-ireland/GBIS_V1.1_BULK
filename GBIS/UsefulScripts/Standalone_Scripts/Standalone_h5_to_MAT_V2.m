function Filename = Standalone_h5_to_MAT_V2(TS_Files,Heading_deg,Incidence_deg,OutName,Outfolder,Wavelength_m,Fig,Save,crop,mask)
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

        LatIdxs = lat1>=StartLat & lat1<=EndLat;
        LOS = LOS(LatIdxs,:,:);
        lat1 = lat1(LatIdxs);
    end

    if crop.Lon.do==1
        disp('Cropping timeseries in Lon')
        StartLon = crop.Lon.Start;
        EndLon = crop.Lon.End;
        disp('Requested start lon is: ')
        disp(num2str(StartLon))
        disp('Requested end lon is: ')
        disp(num2str(EndLon))

        LonIdxs = lon1>=StartLon & lon1<=EndLon;
        LOS = LOS(:,LonIdxs,:);
        lon1 = lon1(LonIdxs);
    end

    if crop.Time.do==1
        disp('Cropping timeseries in time')
        StartDate = datetime(string(crop.Time.Start),'InputFormat','yyyyMMdd');
        EndDate = datetime(string(crop.Time.End),'InputFormat','yyyyMMdd');
        disp('Requested start date is: ')
        disp(StartDate)
        disp('Requested end date is: ')
        disp(EndDate)
        
        % Find closest date to StartDate and EndDate
        [~, StartDateIdx] = min(abs(time2num((datetime(DatesDT,'InputFormat','yyyy-MM-dd') - StartDate),"days")));
        [~, EndDateIdx] = min(abs(time2num((datetime(DatesDT,'InputFormat','yyyy-MM-dd') - EndDate),"days")));

        disp('Closest start date is: ')
        disp(DatesDT(StartDateIdx))
        disp('Closest end date is: ')
        disp(DatesDT(EndDateIdx))

        LOS = LOS(:,:,StartDateIdx:EndDateIdx);
    else
        disp('NOT Cropping timeseries')
    end

    Img = LOS(:,:,end);
    if mask.do==1
        disp(strcat("Masking extreme values - everything above |",num2str(mask.Thresh),"|m"))
        Img(abs(Img)>(mask.Thresh*1000)) = NaN;
    end

    % Make square if not square
    if size(Img,1) ~= size(Img,2)
        disp("Making arrays square")
        [lon1,lat1,Img] = MakeSquare(lon1,lat1,Img);
    end

    % Make lat/lon grids
    [lon,lat] = meshgrid(lon1,lat1);

    % Convert to metres
    Img = Img / 1000; % Convert to m from mm
    Img = Img .* m2rad; % Convert to radians
    Img = -Img; % GBIS convention - phase is +ive away from satellite


    if Fig ==1
        f = figure();
        imagesc(lon1,lat1,Img,"AlphaData",Img~=0 & ~isnan(Img))
        axis image
        c = colorbar;
        c.Label.String = 'Phase change (radians, +ive away from satellite)';
        if mask.do==1
            Val = mask.Thresh * m2rad;
            clim([-Val Val])
        else
            clim([-50 50])
        end
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
    Filename2 = strcat(Outfolder,'/',OutName,'.txt');
    if Save==1
        save(Filename,"Phase","Lat","Lon","Heading","Inc");
        fid = fopen(Filename2,'wt');
        fprintf(fid, 'crop.Lat.do = %d\n', crop.Lat.do); 
        fprintf(fid, 'crop.Lat.Start = %.2f\n', crop.Lat.Start);
        fprintf(fid, 'crop.Lat.End = %.2f\n\n', crop.Lat.End); 
        fprintf(fid, 'crop.Lon.do = %d\n', crop.Lon.do); 
        fprintf(fid, 'crop.Lon.Start = %.2f\n', crop.Lon.Start); 
        fprintf(fid, 'crop.Lon.End = %.2f\n\n', crop.Lon.End); 
        fprintf(fid, 'crop.Time.do = %d\n', crop.Time.do); 
        fprintf(fid, 'crop.Time.Start = %d\n', crop.Time.Start); 
        fprintf(fid, 'crop.Time.End = %d\n\n', crop.Time.End); 
        fprintf(fid, 'mask.do = %d\n', mask.do); 
        fprintf(fid, 'mask.Thresh = %.2f\n', mask.Thresh);
        fclose(fid);
    end

    close all
end
