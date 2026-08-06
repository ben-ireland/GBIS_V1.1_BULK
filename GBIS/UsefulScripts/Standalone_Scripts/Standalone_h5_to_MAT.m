clear variables; close all;

% Create .h5 LiCSBAS timeseries file for use with other GBIS scripts from a single image

% Data filepath and geometry
%130A_09212_131313
%TS_Files = dir('/scratch/Ben/Suswa_Longonot_Connectivity/LiCSBAS_Outputs/Suswa_S1_130A/TS_GEOCml2mask/cum_filt.h5');
% Heading_deg = -12.122097; % Heading in degrees
% Incidence_deg = 39.5879; % Incidence angle in degrees
% OutName = 'Suswa_EP1_130A_09212_131313_V2';

%152D_09114_131313
TS_Files = dir('/scratch/Ben/Suswa_Longonot_Connectivity/LiCSBAS_Outputs/Suswa_S1_152D/TS_GEOCml2mask/cum_filt.h5');
Heading_deg = -167.9484; % Heading in degrees
Incidence_deg = 33.7971; % Incidence angle in degrees
OutName = 'Suswa_EP2_152D_09114_131313_V2';

% Options
Outfolder = '/scratch/Ben/Suswa_Longonot_Connectivity/LiCS_TS_mat';
Wavelength_m = 0.0566; % SAR Wavelength in m
Fig = 1;
Save = 1;
Crop = 1;
CropStart = 70; 
CropEnd = 126; % 70-126 for dsc, 109-280 for asc
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
LOS = permute(LOS,[2,1,3]); % To get in correct dimensions format (lat,lon,disp)

if Crop==1
    Img = LOS(:,:,CropEnd) - LOS(:,:,CropStart);
else
    Img = LOS(:,:,end);
end

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

if Save==1
    save(strcat(Outfolder,'/',OutName,'.mat'),"Phase","Lat","Lon","Heading","Inc");
end

close all
