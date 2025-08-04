clear all; close all;

TS_Files = dir(['/home/jl20461/GBIS_V1.1_Mod4/EAR_Data/**/timeseries/*.nc']);
DEM_Files = dir(['/home/jl20461/GBIS_V1.1_Mod4/EAR_Data/**/dem/*dem.tif']);

for i = 1:length(TS_Files)
    disp([num2str(i),' out of ',num2str(length(TS_Files))])

    % Load TS and load Last Step and Adjusted last step
    TS_Filename = strcat(TS_Files(i).folder,'/',TS_Files(i).name);
    DEM_Filename = strcat(DEM_Files(i).folder,'/',DEM_Files(i).name);

    %Read .nc file (time series) and extract the final time step
    LOS = ncread(TS_Filename,'DATA');
    LOS = permute(LOS,[2 1 3]);
    NoLastStep = LOS(:,:,end-1) - LOS(:,:,2);
    LastStep = LOS(:,:,end);

    % Load DEM
    [Z,~]=readgeoraster(DEM_Filename);
    Z = single(Z);

    if size(Z,1) ~=size(LastStep,1)
        % Resample DEM if needed
        Z = interp2(1:size(Z,1),(1:size(Z,1))',Z,linspace(1,size(Z,1),size(LastStep,1)),linspace(1,size(Z,1),size(LastStep,1))');
    end

    Z(LastStep==0)=NaN;
    LastStep(LastStep==0)=NaN;
    NoLastStep(LastStep==0)=NaN;

    % Plot, calculate and save phase-elevation correlation
    LinearFit = fitlm(Z(:),NoLastStep(:),'Intercept',true);
    LinearFit2 = fitlm(Z(:),LastStep(:),'Intercept',true);
    
    figure()

    % First subplot
    subplot(1,2,1)
    h1 = plot(LinearFit); % Get handles to plot elements
    title('No Last Step','FontSize',8)
    subtitle(['R^2 = ', num2str(LinearFit.Rsquared.Adjusted)],"FontSize",6);
    xlabel('Elevation (m)');
    ylabel('Cumulative LOS displacement (m)');
    axis square
    
    % Second subplot
    subplot(1,2,2)
    h2 = plot(LinearFit2);
    title('Last Step','FontSize',8)
    subtitle(['R^2 = ', num2str(LinearFit2.Rsquared.Adjusted)],"FontSize",6);
    xlabel('Elevation (m)');
    ylabel('Cumulative LOS displacement (m)');
    axis square

    saveas(gcf,['/home/jl20461/GBIS_V1.1_BULK/PhaseElevation/',TS_Files(i).name(1:end-3),'_PhaseElevation.png']);
end
