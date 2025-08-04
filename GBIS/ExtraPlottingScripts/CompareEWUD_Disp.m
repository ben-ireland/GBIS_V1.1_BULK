clear all
close all
%% Input data

AscData = '/home/jl20461/GBIS_V1.1_Mod4/EAR_Data/suswa_130A_09212_131313/timeseries/suswa_130A_09212_131313.nc';
DscData = '/home/jl20461/GBIS_V1.1_Mod4/EAR_Data/suswa_152D_09114_131313/timeseries/suswa_152D_09114_131313.nc';
InvResFile = '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/suswa_130A_09212_131313_152D_09114_131313Sill_Test_Last/invert_1_2_M/invert_1_2_M/invert_1_2_M.mat';
RowIdx = 250; % Idx of profiles

ResName = extractBetween(InvResFile,'Results/','/invert_');
ModelName = extractBetween(InvResFile,strcat(ResName,'/invert_'),'/');

Name = strcat(ResName,'_',ModelName);

%% Do decomposition and extract model
[EW,UD,Cumulative_asc,Cumulative_dsc,ResidAsc,ResidDsc,LOS_vector,lat,lon] = DecompEWUD(AscData,DscData);
[ForwardModel,UComp,lonlat] = MakeForwardModel(InvResFile); % UComp = EW,NS,UD

%% Set up profiles
% Get lat value at RowIdx
LatIdxA = lat.Asc(RowIdx);
LatIdxD = lat.Dsc(RowIdx);

% Find idx of closest lat value in the forward model coordinates
LatIdxModelA = knnsearch(unique(lonlat{1}(:,2)),LatIdxA);
LatIdxModelD = knnsearch(unique(lonlat{2}(:,2)),LatIdxD);
ProfileLatsAsc = unique(lonlat{1}(:,2));
ProfileLatsDsc = unique(lonlat{2}(:,2));
ProfileLatAsc = ProfileLatsAsc(LatIdxModelA);
ProfileLatDsc = ProfileLatsDsc(LatIdxModelD);

% Extract corresponding foward model values
ModelProfileAsc = ForwardModel{1}(lonlat{1}(:,2)==ProfileLatAsc);
ModelProfileDsc = ForwardModel{2}(lonlat{2}(:,2)==ProfileLatDsc);
%ModelProfileAsc = ForwardModel{1}(lonlat{1}(:,2)==unique(lonlat{1}(LatIdxModelA,2)));
%ModelProfileDsc = ForwardModel{2}(lonlat{2}(:,2)==unique(lonlat{2}(LatIdxModelD,2)));
LonValuesAsc = lonlat{1}((lonlat{1}(:,2)==ProfileLatAsc),1);
LonValuesDsc = lonlat{2}((lonlat{2}(:,2)==ProfileLatDsc),1);

ModelAscEW = UComp{1}((lonlat{1}(:,2)==ProfileLatAsc),1);
ModelAscUD = UComp{1}((lonlat{1}(:,2)==ProfileLatAsc),3);
ModelDscEW = UComp{2}((lonlat{2}(:,2)==ProfileLatDsc),1);
ModelDscUD = UComp{2}((lonlat{2}(:,2)==ProfileLatDsc),3);
%ModelAscEW = ModelProfileAsc./LOS_vector(1,1);
%ModelAscUD = ModelProfileAsc./LOS_vector(1,2);
%ModelDscEW = ModelProfileDsc./LOS_vector(2,1);
%ModelDscUD = ModelProfileDsc./LOS_vector(2,2);

%% PLOTS
% Display LOS, UD, and EW components and residuals of original data
f1 = figure()
subplot(2,2,1)
imagesc(Cumulative_asc,'AlphaData',~isnan(Cumulative_asc))
axis image
colorbar
title('Ascending LOS (m)')

subplot(2,2,2)
imagesc(UD,'AlphaData',~isnan(UD))
axis image
colorbar
title('Vertical (m)')

subplot(2,2,3)
imagesc(EW,'AlphaData',~isnan(EW))
axis image
colorbar
title('East-West (m)')

subplot(2,2,4)
imagesc(ResidAsc,'AlphaData',~isnan(ResidAsc))
axis image
colorbar
title('Residual (m)')

sgtitle('Decomposition results (ASC)')

f2 = figure()
subplot(2,2,1)
imagesc(Cumulative_dsc,'AlphaData',~isnan(Cumulative_dsc))
axis image
colorbar
title('Descending LOS (m)')

subplot(2,2,2)
imagesc(UD,'AlphaData',~isnan(UD))
axis image
colorbar
title('Vertical (m)')

subplot(2,2,3)
imagesc(EW,'AlphaData',~isnan(EW))
axis image
colorbar
title('East-West (m)')

subplot(2,2,4)
imagesc(ResidDsc,'AlphaData',~isnan(ResidDsc))
axis image
colorbar
title('Residual (m)')
sgtitle('Decomposition results (DSC)')

% Display E-W profile through signal centre
ProfileAsc = Cumulative_asc(RowIdx,:);
ProfileDsc = Cumulative_dsc(RowIdx,:);
ProfileEW = EW(RowIdx,:);
ProfileUD = UD(RowIdx,:);

f3 = figure()
% LOS
subplot(1,3,1)
plot(lon.Asc,ProfileAsc,'r','LineWidth',1)
hold on
plot(lon.Dsc,ProfileDsc,'g','LineWidth',1)
hold on
plot(LonValuesAsc,ModelProfileAsc,'b','LineWidth',1,'LineStyle',':')
hold on
plot(LonValuesDsc,ModelProfileDsc,'k','LineWidth',1,'LineStyle',':')
hold off
title('LOS Displacement')
xlabel('Longitude')
ylabel('Displacement (m)')
axis square
grid on
legend({'DATA Asc','DATA Dsc','Model Asc','Model Dsc'},"Location","southoutside");

% Vertical
subplot(1,3,2)
plot(lon.Asc,ProfileUD,'m','LineWidth',1)
hold on
plot(LonValuesAsc,ModelAscUD,'b','LineWidth',1,'LineStyle',':')
hold on
plot(LonValuesDsc,ModelDscUD,'k','LineWidth',1,'LineStyle',':')
hold off
title('UD')
xlabel('Longitude')
ylabel('Displacement (m)')
axis square
grid on
legend({'DATA','Model Asc','Model Dsc'},"Location","southoutside");

% Horizontal (EW)
subplot(1,3,3)
plot(lon.Asc,ProfileEW,'m','LineWidth',1)
hold on
plot(LonValuesAsc,ModelAscEW,'b','LineWidth',1,'LineStyle',':')
hold on
plot(LonValuesDsc,ModelDscEW,'k','LineWidth',1,'LineStyle',':')
hold off
title('EW')
xlabel('Longitude')
ylabel('Displacement (m)')
axis square
grid on
legend({'DATA','Model Asc','Model Dsc'},"Location","southoutside");
sgtitle(['Horizontal Profile at Row ', num2str(RowIdx), 'Model: ',ModelName],'Interpreter','none');

filename1 = strcat(pwd,'/DecomposeLOS/',ResName,'_Asc_Decomp.png');
filename2 = strcat(pwd,'/DecomposeLOS/',ResName,'_Dsc_Decomp.png');
filename3 = strcat(pwd,'/DecomposeLOS/',Name,'_Profiles.png');

% Save plots
saveas(f1,filename1{1});
saveas(f2,filename2{1});
saveas(f3,filename3{1});

