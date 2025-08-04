% Plot any data file
% LOS File
load('/home/jl20461/GBIS_V1.1_Mod4/Inversion_Results/tullu_moje_079D_08094_131313SQRTV71/invert_1_M/invert_1_M/invert_1_M.mat');
% BB File
load('/home/jl20461/GBIS_V1.1_Mod4/Bounding_Boxes/tullu_moje_079D_08094_131313_Shape_TEST2BoundingBox.mat');
% Create colormaps for plotting InSAR data
cmap2.Seismo = colormap_cpt('GMT_seis.cpt', 100); % GMT Seismo colormap for wrapped interferograms
cmap2.redToBlue = colormap_cpt('polar.cpt', 100); % Red to Blue colormap for unwrapped interferograms

%% Load InSAR data and results data
for i=1:length(insar)
    rawData = load(insar{i}.rawDataPath);
    
    convertedPhase_raw = (rawData.Phase / (4*pi) )  * insar{i}.wavelength;    % Convert phase from radians to m
    los_raw = single(-convertedPhase_raw);  % Convert to Line-of-sigth displacement in m
    ll_raw = [single(rawData.Lon) single(rawData.Lat)];   % Create Longitude and Latitude 2Xn matrix
    xy_raw = llh2local(ll_raw', geo.referencePoint);    % Transform from geografic to local coordinates
    nPointsThis_raw = size(ll_raw, 1);   % Calculate length of current InSAR data vector
    xy_raw = double([(1:nPointsThis_raw)', xy_raw'*1000]);   % Add ID number column to xy matrix with local coordinates
    nObsRaw = length(convertedPhase_raw);
    HeadingRaw = rawData.Heading;
    IncRaw = rawData.Inc;


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
    scatter(xy_raw(:,2)/100, xy_raw(:,3)/100,3,los_raw,'square', 'filled');
    set(gca,'Color',[0.5 0.5 0.5]);
    colormap(cmap2.redToBlue); 
    c = max(abs([min(los_raw), max(los_raw)])); % Calculate maximu value for symmetric colormap
    caxis([-c c])
    axis square
    %xlim([min(ll_raw(:,1)) max(ll_raw(:,1))])
    %ylim([min(ll_raw(:,2)) max(ll_raw(:,2))])
    xtickangle(45)

    vertices = FineBoundingBox.Vertices;
    % Flip through the y-axis (swap x coordinates)
    %vertices(:, 1) = -vertices(:, 1);

    % Flip through the x-axis (swap y coordinates)
    %vertices(:, 2) = -vertices(:, 2);
    FlipPoly = polyshape(vertices);
    %FlipVer = Vertices(:,[2 1]);
    %FlipPoly = polyshape(FlipVer);
    hold on
    %plot(FineBoundingBox)
    plot(FlipPoly)
    hold off
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
    saveas(Fig,'CSMRawFigTMBB2.png');
    %saveas(Fig2,'CSMTestTM.png');