% Plot any Timeseries file with associated bounding box
% BB File
clear all
close all

load('/home/jl20461/GBIS_V1.1_Mod4/Bounding_Boxes/tullu_moje_079D_08094_131313_Shape_TEST2BoundingBox.mat');
% Create colormaps for plotting InSAR data
cmap2.Seismo = colormap_cpt('GMT_seis.cpt', 100); % GMT Seismo colormap for wrapped interferograms
cmap2.redToBlue = colormap_cpt('polar.cpt', 100); % Red to Blue colormap for unwrapped interferograms

TS_Filename = '/home/jl20461/GBIS_V1.1_Mod4/EAR_Data/tullu_moje_079D_08094_131313/timeseries/tullu_moje_079D_08094_131313.nc';
LOS = ncread(TS_Filename,'DATA');
lat = ncread(TS_Filename,'lat');
lon = ncread(TS_Filename,'lon');
LOS = permute(LOS,[2 1 3]);
LastStep = squeeze((LOS(:,:,end-1)-LOS(:,:,2)));
%LastStep = squeeze((LOS(:,:,end)));
LastStep(LastStep==0) = NaN;

Fig = imagesc(LastStep)
colormap(cmap2.redToBlue)
axis square
set(Fig, 'AlphaData', ~isnan(LastStep))
c = max(abs([min(LastStep(:)), max(LastStep(:))])); % Calculate maximu value for symmetric colormap
caxis([-c c])
%c2 = colorbar;
%c2.Label.String = 'LOS displacement (m)';
hold on
plot(FineBoundingBox)
hold off

ax = gca;
 % Turn off tick labels
 ax.XTickLabel = [];
ax.YTickLabel = [];
% If you want to remove ticks as well, uncomment the following lines
ax.XTick = [];
ax.YTick = [];

saveas(Fig,'TM_TS_BB.png');
