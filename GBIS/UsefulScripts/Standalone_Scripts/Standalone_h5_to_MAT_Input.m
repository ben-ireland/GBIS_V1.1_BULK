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

% % InSAR data info
% TS_Files = dir('/local-scratch/Ben/GBIS_Sept26/EAR_Manual_Pedro_LiCS/Fentale/079D/cum.h5');
% Heading_deg = -168.61745; % Heading in degrees
% Incidence_deg = 33.8941; % Incidence angle in degrees
% OutName = '2024_fentale_079D_08094_131313';

% InSAR data info
% TS_Files = dir('/local-scratch/Ben/GBIS_Sept26/EAR_Manual_Pedro_LiCS/Fentale/087A/cum.h5');
% Heading_deg = -11.387289; % Heading in degrees
% Incidence_deg = 39.6550; % Incidence angle in degrees
% OutName = '2015_fentale_087A_08102_131312';

% TS_Files = dir('/local-scratch/Ben/GBIS_Sept26/EAR_Manual_Pedro_LiCS/Hertali/079D/cum_filt.h5');
% Heading_deg = -168.61745; % Heading in degrees
% Incidence_deg = 33.8941; % Incidence angle in degrees
% OutName = '2014_2024_hertali_079D_08094_131313';

TS_Files = dir('/local-scratch/Ben/GBIS_Sept26/EAR_Manual_Pedro_LiCS/Alutu/079D/cum_filt.h5');
Heading_deg = -168.49602; % Heading in degrees
Incidence_deg = 33.8749; % Incidence angle in degrees
OutName = '2014_2024_alutu_079D_08294_131313';

% Options
Outfolder = '/local-scratch/Ben/GBIS_Sept26/EAR_Manual_Pedro_LiCS/Alutu/079D/LiCS_TS_mat';
Wavelength_m = 0.0566; % SAR Wavelength in m
Fig = 1;
Save = 1;

crop.Lat.do = 1; % Crop Lat(?) - start and end in degrees
crop.Lat.Start = 7.7;
crop.Lat.End = 8.0;

crop.Lon.do = 1; % Crop Lon(?) - start and end in degrees
crop.Lon.Start = 38.6;
crop.Lon.End = 38.9;

crop.Time.do = 1; % Crop in time (?) - start and end dates in format yyyyMMdd
crop.Time.Start = 20140101;
crop.Time.End = 20241201;

mask.do = 1; % Mask extreme values (?) Threshold in metres, everything above that will be set to NaN
mask.Thresh = 0.5;

Filename = Standalone_h5_to_MAT_V2(TS_Files,Heading_deg,Incidence_deg,OutName,Outfolder,Wavelength_m,Fig,Save,crop,mask);