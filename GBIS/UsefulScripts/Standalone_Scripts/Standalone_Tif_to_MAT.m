clear variables; close all;

% Create .mat file for use with other GBIS scripts from a single image
Tif_File = '/scratch/Ben/Suswa_Longonot_Connectivity/Envisat_IFG/Longonot_Dsc_20040628_20060529.geo.unw.tif';
Outfolder = '/scratch/Ben/Suswa_Longonot_Connectivity/Envisat_IFG/';
OutName = 'Envisat_20040628_20060529_Longonot';
Heading_deg = -167.5357; % Heading in degrees
Incidence_deg = 22.3; % Incidence angle in degrees
Wavelength_m = 0.0566; % SAR Wavelength in m
Fig = 1;
Save = 1;

m2rad= (4.*pi)./Wavelength_m;
rad2m= Wavelength_m./(4.*pi);

% Load imagery
[Img,R] = readgeoraster(Tif_File);
[lat,lon] = geographicGrid(R,'fullgrid');
[lat1,lon1] = geographicGrid(R,'gridvectors'); % For figure

% lon = lon1.';
% lon = repmat(lon,(length(lon)),1);
% lat = repmat(lat1,1,(length(lat1)));

% % Set any NaN values to zero
% Img(isnan(Img)) = 0;

% Convert to metres
% Img = Img .* rad2m;

Img = -Img; % GBIS convention - phase is +ive away from satellite

if Fig ==1
    f = figure();
    imagesc(lon1,lat1,Img,"AlphaData",Img~=0)
    axis image
    c = colorbar;
    c.Label.String = 'Phase change (radians, +ive away from satellite)';
    set(gca,'YDir','normal')
    saveas(f,strcat(Outfolder,"/Test.png"))
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
