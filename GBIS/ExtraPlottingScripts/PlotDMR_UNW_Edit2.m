% Plot any data file
% LOS File
load('/home/jl20461/GBIS_V1.1_Mod4/Inversion_Results/tullu_moje_079D_08094_131313SQRTV71/invert_1_M/invert_1_M/invert_1_M.mat');
%oad('/home/jl20461/GBIS_V1.1_Mod4/Inversion_Results/suswa_130A_09212_131313SQRTV71/invert_1_M/invert_1_M/invert_1_M.mat');
% BB File
load('/home/jl20461/GBIS_V1.1_Mod4/Bounding_Boxes/tullu_moje_079D_08094_131313_Shape_TEST2BoundingBox.mat');
%load('/home/jl20461/GBIS_V1.1_Mod4/Bounding_Boxes/suswa_130A_09212_131313_Shape_2BoundingBox.mat');
% Create colormaps for plotting InSAR data
cmap2.Seismo = colormap_cpt('GMT_seis.cpt', 100); % GMT Seismo colormap for wrapped interferograms
cmap2.redToBlue = colormap_cpt('polar.cpt', 100); % Red to Blue colormap for unwrapped interferograms

%% Load InSAR data and results data
for i=1:length(insar)
    loadedData = load(insar{i}.dataPath);

    convertedPhase = (loadedData.Phase / (4*pi) )  * insar{i}.wavelength;    % Convert phase from radians to m
    los = single(-convertedPhase);  % Convert to Line-of-sigth displacement in m
    ll = [single(loadedData.Lon) single(loadedData.Lat)];   % Create Longitude and Latitude 2Xn matrix
    xy = llh2local(ll', geo.referencePoint);    % Transform from geografic to local coordinates
    
    nPointsThis = size(ll, 1);   % Calculate length of current InSAR data vector
    xy = double([(1:nPointsThis)', xy'*1000]);   % Add ID number column to xy matrix with local coordinates
    nObs2 = size(xy,1);
    Heading = loadedData.Heading;
    Inc = loadedData.Inc;

    %% Offset and ramp values
    % Calculate MODEL
    constOffset = 0;
    xRamp = 0;
    yRamp = 0;
    
    if i == 1
        if insar{i}.constOffset == 'y'
            constOffset = invResults.model.mIx(end);
            invResults.model.mIx(end) = invResults.model.mIx(end)+1;
        end
        if insar{i}.rampFlag == 'y'
            xRamp = invResults.model.mIx(end);
            yRamp = invResults.model.mIx(end)+1;
            invResults.model.mIx(end) = invResults.model.mIx(end)+2;
        end
    end
    
    if i > 1
        if insar{i}.constOffset == 'y'
            constOffset = invResults.model.mIx(end);
            invResults.model.mIx(end) = invResults.model.mIx(end)+1;
        end
        if insar{i}.rampFlag == 'y'
            xRamp = invResults.model.mIx(end);
            yRamp = invResults.model.mIx(end)+1;
            invResults.model.mIx(end) = invResults.model.mIx(end)+2;
        end
    end
    

    % Raw data - unwrapped
    Fig = figure()
    scatter(xy(:,2)/100, xy(:,3)/100,50,los,'square', 'filled');
    set(gca,'Color',[0.5 0.5 0.5]);
    colormap(cmap2.redToBlue); 
    c = max(abs([min(los), max(los)])); % Calculate maximu value for symmetric colormap
    caxis([-c c])
    axis square
    %xlim([min(ll_raw(:,1)) max(ll_raw(:,1))])
    %ylim([min(ll_raw(:,2)) max(ll_raw(:,2))])
    xtickangle(45)

    %hold on
    %plot(FineBoundingBox')
    %hold off
    ax = gca;
    
    % Turn off axis labels
    %ax.XAxis.Visible = 'off';
    %ax.YAxis.Visible = 'off';

    % Turn off tick labels
    ax.XTickLabel = [];
    ax.YTickLabel = [];

    % If you want to remove ticks as well, uncomment the following lines
    ax.XTick = [];
    ax.YTick = [];
%     title('Data','interpreter','none')
%     subtitle(['RMSE (mm) = ',num2str(1000*RMSE_LOSRaw,4)],'interpreter','none')

end
    saveas(Fig,'CSMRawFigTM_DS.png');
    %saveas(Fig2,'CSMTestTM.png');