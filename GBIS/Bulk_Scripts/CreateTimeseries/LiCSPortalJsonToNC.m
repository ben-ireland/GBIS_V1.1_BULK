function [NC_filename, DEM_Filename] = LiCSPortalJsonToNC(file,outfolder,mask)
    % file = '/scratch/Ben/EAR_Data_Portal_json/alu-dalafilla_014A_07688_131313_filt.json';
    % outfolder = '/scratch/Ben/EAR_Data_Portal_json/Coverted_NC';
    % mask = 0;

    % Read and decode .json file
    disp('Loading .json file (slow)')
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

    if mask==1
        DataMask = data.mask';
        LOS = LOS .* DataMask;
    end
    
    dates = string(data.dates);
    daysDT = time2num((datetime(dates,'InputFormat','yyyy-MM-dd') - datetime(dates(1),'InputFormat','yyyy-MM-dd')),"days");

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
    
    
    % f = figure()
    % imagesc(DEM)
    % colorbar
    % axis image
    % saveas(f,[outfolder,'/Test_DEM.png'])

    % f = figure()
    % imagesc(LOS(:,:,end))
    % colorbar
    % axis image
    % saveas(f,[outfolder,'/Test.png'])
end