function [NC_filename, DEM_Filename] = LiCSPortalJsonToNC(file,outfolder,mask,cropTime,cropLat,cropLon,cohMask,fig)
    % file = '/scratch/Ben/EAR_Data_Portal_json/alu-dalafilla_014A_07688_131313_filt.json';
    % outfolder = '/scratch/Ben/EAR_Data_Portal_json/Coverted_NC';
    % mask = 0;

    % Read and decode .json file
    disp('Loading .json file (slow, ~1-2 mins)')
    fid = fopen(file); 
    raw = fread(fid,inf); 
    str = char(raw'); 
    fclose(fid); 
    data = jsondecode(str);

    % format for NC script
    disp('Formatting data')
    lon = data.x;
    lat = data.y;
    LOS = permute(data.data_filt,[2,3,1]); % To match required input format of Lat, Lon, Time
    LOS(isnan(LOS))=0; % Convert NaNs to zeros to match required input format
    LOS = LOS./1000; % Convert from mm (LiCSBAS output) to m (required input)

    DataMask = data.mask;
    if mask==1
        disp('Applying mask to timeseries')
        DataMask(DataMask~=1)=0;

        LOS = LOS .* DataMask;
    else
        disp('NOT Applying mask to timeseries')
    end

    if cohMask.do ==1
        disp('Applying coherence-based masking')

        MaskCoh = zeros(size(data.coh));
        if cohMask.type ==1
            disp('Using scalar threshold:')
            disp(['Threshold: ',num2str(cohMask.thresh)])
            MaskCoh(data.coh > cohMask.thresh & data.coh~=1)=1;
        elseif cohMask.type ==2
            disp('Using percentile threshold:')
            disp(['Threshold: ',num2str(cohMask.thresh)])
            CohThresh = prctile(data.coh(:),cohMask.thresh);
            MaskCoh(data.coh > CohThresh & data.coh~=1)=1;
        elseif cohMask.type ==3
            disp('Using percentile threshold with max. limit:')
            disp(['Threshold: ',num2str(cohMask.thresh)])
            disp(['Keeping any pixels with coherence >', num2str(cohMask.thresh2)]);
            CohThresh = prctile(data.coh(:),cohMask.thresh);
            MaskCoh((data.coh > CohThresh | data.coh >= cohMask.thresh2) & data.coh~=1 & data.coh > cohMask.thresh3)=1;
        end

        LOS = LOS .* MaskCoh;

        % if mask==1
        %     DataMask = DataMask & MaskCoh;
        % else
        %     DataMask = MaskCoh;
        % end
    else
        disp('NOT applying average coherence-based masking')
    end

    
    dates = string(data.dates);
    daysDT = time2num((datetime(dates,'InputFormat','yyyy-MM-dd') - datetime(dates(1),'InputFormat','yyyy-MM-dd')),"days");

    if cropLat.do==1
        disp('Cropping timeseries in Lat')
        StartLat = cropLat.Start;
        EndLat = cropLat.End;
        disp('Requested start lat is: ')
        disp(num2str(StartLat))
        disp('Requested end lat is: ')
        disp(num2str(EndLat))

        LatIdxs = lat>=StartLat & lat<=EndLat;
        LOS = LOS(LatIdxs,:,:);
    end

    if cropLon.do==1
        disp('Cropping timeseries in Lon')
        StartLon = cropLon.Start;
        EndLon = cropLon.End;
        disp('Requested start lat is: ')
        disp(num2str(StartLon))
        disp('Requested end lat is: ')
        disp(num2str(EndLon))

        LonIdxs = lon>=StartLat & lon<=EndLat;
        LOS = LOS(:,LonIdxs,:);
    end

    if cropTime.do==1
        disp('Cropping timeseries in time')
        StartDate = datetime(string(cropTime.start),'InputFormat','yyyyMMdd');
        EndDate = datetime(string(cropTime.end),'InputFormat','yyyyMMdd');
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


    % Get output name and make output folders if they don't exist
    [~,name,~] = fileparts(file);
    OutputName = extractBefore(name,'_filt');
    OutputBaseFolder = strcat(outfolder,'/',OutputName);

    if ~exist([outfolder,'/',OutputName],'dir')
        mkdir(outfolder,OutputName)
        addpath([outfolder,'/',OutputName])
    end

    if ~exist([OutputBaseFolder,'/timeseries'],'dir')
        mkdir(OutputBaseFolder,'timeseries')
        addpath([OutputBaseFolder,'/timeseries'])
    end

    OutputFile = strcat(OutputBaseFolder,'/timeseries/',OutputName);
    
    % Write .nc file with timeseries in
    disp('Saving .nc timeseries file')
    NC_filename = Save_NC_Timeseries(OutputFile,dates,daysDT,lon,lat,LOS);

    % Process DEM and save as geoTiff
    DEM = flipud(data.elev); % To match conventions of the lat/lon

    % Build CRS object for DEM
    R = georefcells([min(lat), max(lat)],[min(lon), max(lon)],size(DEM));

    if ~exist([OutputBaseFolder,'/dem'],'dir')
        mkdir(OutputBaseFolder,'dem')
        addpath([OutputBaseFolder,'/dem'])
    end

    DEM_Filename = strcat(OutputBaseFolder,'/dem/',OutputName,'_dem.tif');
    disp('Saving dem .tif file')
    geotiffwrite(DEM_Filename,DEM,R);
    
    
    if fig==1
        disp('Plotting DEM and Cum. Displacement')
        f = figure();
        subplot(2,3,1)
        imagesc(DEM)
        colorbar
        axis image
        subtitle('DEM')
        set(gca,'XTick',[])
        set(gca,'YTick',[])
        set(gca,'YDir','normal')

        subplot(2,3,2)
        imagesc(LOS(:,:,end),"AlphaData",LOS(:,:,end)~=0)
        colorbar
        axis image
        subtitle('Cum. LOS Displacement')
        set(gca,'XTick',[])
        set(gca,'YTick',[])

        subplot(2,3,3)
        imagesc(data.coh)
        colorbar
        axis image
        subtitle('Average coherence')
        set(gca,'XTick',[])
        set(gca,'YTick',[])

        subplot(2,3,4)
        imagesc(DataMask)
        colorbar
        axis image
        if mask==1
            subtitle('LiCSBAS mask')
        else
            subtitle('LiCSBAS mask (not used)')
        end
        set(gca,'XTick',[])
        set(gca,'YTick',[])

        if cohMask.do==1
            subplot(2,3,5)
            imagesc(MaskCoh)
            colorbar
            axis image
            subtitle('Coherence mask')
            set(gca,'XTick',[])
            set(gca,'YTick',[])
        end
        saveas(f,[OutputBaseFolder,'/Output_Maps.png'])

    else
        disp('NOT plotting DEM and Cum. Displacement')
    end
end