function filename = Save_NC_Timeseries(output_name,tscene,daysDT,LON,LAT,Datacube)
    % Ben Ireland, University of Bristol, 2025 - Adapted from scripts written by Fabien Albino.
    % 
    % Inputs:
    % output_name - Filename (without extension)
    % tscene - time of each timeseries slice
    % LON/LAT - n x 1 or m x 1 vectors of lon and lat, where n x m is the
    % spatial dimensions of the image
    % Datacube - 3D n x m x o matrix, giving displacements at n x m spatial
    % coordinates at o points in time
    
    filename = strcat(output_name,'.nc');
    delete(filename)
    
    %% Create
    nccreate(filename,'DATA','datatype','single','DeflateLevel',5,'Dimensions',{'lon' length(LON) 'lat' length(LAT) 'time' length(tscene)});
    nccreate(filename,'lon','DeflateLevel',5,'Dimensions',{'lon' length(LON)});
    nccreate(filename,'lat','DeflateLevel',5,'Dimensions',{'lat' length(LAT)});
    nccreate(filename,'time','DeflateLevel',5,'Dimensions',{'time' length(tscene)});
    ncdisp(filename);
    
    %% write dimensions
    % https://www.unidata.ucar.edu/software/netcdf/docs/netcdf/Dimensions.html
    DATA=permute(Datacube,[2 1 3]);
    
    %Latitude:
    ncwrite(filename,'lat',LAT);
    ncwriteatt(filename, 'lat', 'standard_name', 'latitude');
    ncwriteatt(filename, 'lat', 'long_name', 'latitude');
    ncwriteatt(filename, 'lat', 'units', 'degrees');
    ncwriteatt(filename, 'lat', '_CoordinateAxisType', 'Lat');
    %Longitude:
    ncwrite(filename,'lon',LON);
    ncwriteatt(filename, 'lon', 'standard_name', 'longitude');
    ncwriteatt(filename, 'lon', 'long_name', 'longitude');
    ncwriteatt(filename, 'lon', 'units', 'degrees');
    ncwriteatt(filename, 'lon', '_CoordinateAxisType', 'Lon');
    % Time:
    tinit=datestr(tscene(1),'yyyy-mm-dd');
    ref_date= ['days since',' ',tinit];
    ncwrite(filename,'time',daysDT);
    ncwriteatt(filename, 'time', 'long_name', 'Time variable');
    ncwriteatt(filename, 'time', 'units', ref_date);
    ncwriteatt(filename, 'time', '_CoordinateAxisType', 'Time');
    %% write data
    ncwrite(filename,'DATA',DATA);
    ncwriteatt(filename, 'DATA', 'standard_name', 'disp');
    ncwriteatt(filename, 'DATA', 'long_name', 'LOS displacements');
    ncwriteatt(filename, 'DATA', 'units', 'meters');
    ncwriteatt(filename, 'DATA', '_CoordinateAxisType', 'Z');
end