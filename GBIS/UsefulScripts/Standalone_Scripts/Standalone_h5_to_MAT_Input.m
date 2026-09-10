clear variables; close all;

% Create .h5 LiCSBAS timeseries file for use with other GBIS scripts from a single image

% Data filepath and geometry
%130A_09212_131313
%TS_Files = dir('/scratch/Ben/Suswa_Longonot_Connectivity/LiCSBAS_Outputs/Suswa_S1_130A/TS_GEOCml2mask/cum_filt.h5');
% Heading_deg = -12.122097; % Heading in degrees
% Incidence_deg = 39.5879; % Incidence angle in degrees
% OutName = 'Suswa_EP1_130A_09212_131313_V2';

% %130A_09032_111110
% TS_Files = dir('/scratch/Ben/Suswa_Longonot_Connectivity/LiCSBAS_Outputs/Longonot_S1_130A/TS_GEOCml2mask/cum_filt.h5');
% Heading_deg = -11.992946; % Heading in degrees
% Incidence_deg = 39.6203; % Incidence angle in degrees
% OutName = 'Longonot_130A_09032_111110_V2';

%152D_09114_131313
% TS_Files = dir('/scratch/Ben/Suswa_Longonot_Connectivity/LiCSBAS_Outputs/Suswa_S1_152D/TS_GEOCml2mask/cum_filt.h5');
% Heading_deg = -167.9484; % Heading in degrees
% Incidence_deg = 33.7971; % Incidence angle in degrees
% OutName = 'Suswa_EP2_152D_09114_131313_V2';

%152D_09114_131313
% TS_Files = dir('/scratch/Ben/Suswa_Longonot_Connectivity/LiCSBAS_Outputs/Longonot_S1_152D/TS_GEOCml2mask/cum_filt.h5');
% Heading_deg = -167.9484; % Heading in degrees
% Incidence_deg = 33.7971; % Incidence angle in degrees
% OutName = 'Longonot_152D_09114_131313_V2';

%014A_07688_131313
% TS_Files = dir('/scratch/Ben/Dabbahu_Dyke_2026/LiCSBAS_Outputs/014A/TS_GEOCml2mask/cum.h5');
% Heading_deg = -11.147556; % Heading in degrees
% Incidence_deg = 39.6593; % Incidence angle in degrees
% OutName = '2026_Dabbahu_014A_07688_131313';

%079D_07694_131313
TS_Files = dir('/scratch/Ben/Dabbahu_Dyke_2026/LiCSBAS_Outputs/079D/TS_GEOCml2mask/cum.h5');
Heading_deg = -168.84906; % Heading in degrees
Incidence_deg = 33.8999; % Incidence angle in degrees
OutName = '2026_Dabbahu_079D_07694_131313';

% Options
Outfolder = '/scratch/Ben/Dabbahu_Dyke_2026/LiCS_TS_mat';
Wavelength_m = 0.0566; % SAR Wavelength in m
Fig = 1;
Save = 1;
Crop = 1;
CropStart = 1; 
CropEnd = 308; % Suswa - 70-126 for dsc, 109-280 for asc; Longonot - 54 for dsc, 51 for asc
% 2-320 for dabb ASC, 308 for Dabb dsc
crop.Lat.do = 1;
crop.Lat.Start = 8.85;
crop.Lat.End = 9.1;

crop.Lon.do = 1;
crop.Lon.Start = 39.8;
crop.Lon.End = 40.05;

crop.Time.do = 1;
crop.Time.Start = 20140101;
crop.Time.End = 20151201;

Filename = Standalone_h5_to_MAT_V2(TS_Files,Heading_deg,Incidence_deg,OutName,Outfolder,Wavelength_m,Fig,Save,crop);