function NewDepthLims = RecalculateDepthBounds(compMask,lat,lon,outputFileName,Options)

    % Ben Ireland, August 2025, University of Bristol
    if ~exist([pwd,'/DepthEstimates'],'dir')
        mkdir(pwd,'DepthEstimates')
        addpath([pwd,'/DepthEstimates'])
    end

    % Convert coordinates of mask to m for Mogi equations
    idx = bwboundaries(compMask);
    idx = idx{1};    % only one region

    row = idx(:,1);
    col = idx(:,2);
    latSing = lat(sub2ind(size(lat), row, col));
    lonSing = lon(sub2ind(size(lon), row, col));

    refLLH = [lon(1,1),lat(end,1)];
    polyLocal = llh2local([lonSing, latSing]', refLLH);
    polyLocal = polyLocal*1000; % Convert to m
    pgon = polyshape(polyLocal(1,:), polyLocal(2,:));
    [xlim,ylim] = boundingbox(pgon);

    % Estimate radius of bounding box and Determine estimate of depth from Mogi equation
    EstA = Options.DepthEstimateA; % What proportion of Umax does the edge of the bounding box represent?

    EstStartRadius = mean([abs(ylim(2)-ylim(1)),abs(xlim(2)-xlim(1))])/2;
    EstMinRadius = min([abs(ylim(2)-ylim(1)),abs(xlim(2)-xlim(1))])/2;
    EstMaxRadius = max([abs(ylim(2)-ylim(1)),abs(xlim(2)-xlim(1))])/2;

    DepthPredStart = sqrt(EstStartRadius^2/(EstA^(-2/3)-2)); % Predict depth based on Radius and EstA (derived from Mogi Uz equation)
    DepthPredMin = sqrt(EstMinRadius^2/(EstA^(-2/3)-2));
    DepthPredMax = sqrt(EstMaxRadius^2/(EstA^(-2/3)-2));
    InitialStart = DepthPredStart;
    InitialMin = DepthPredMin;
    InitialMax = DepthPredMax;

    % Adjust if these are outisde of 'usual' bounds
    if DepthPredStart<Options.MogiMinDepth || DepthPredStart>Options.MogiMaxDepth
        DepthPredStart = Options.MogiStartDepth;
    end
    if DepthPredMin<Options.MogiMinDepth
        DepthPredMin = Options.MogiMinDepth;
    end
    if DepthPredMax>Options.MogiMaxDepth
        DepthPredMax = Options.MogiMaxDepth;
    end

    % Delimit new bounds based on these
    NewDepthLims = [round(DepthPredStart), round(DepthPredMin), round(DepthPredMax)];

    % Figure
    lon1 = lon(1,:);
    lat1 = lat(:,1);

    f = figure()
    imagesc(lat1,lon1,compMask)
    axis image
    title('Depth estimates (m) (start | min | max)')
    subtitle([num2str(round(DepthPredStart)), ' | ', num2str(round(DepthPredMin)), ' | ', num2str(round(DepthPredMax))])
    Name = extractBetween(outputFileName,'InputFiles/','.inp');
    saveas(f,[pwd,'/DepthEstimates/',Name{:},'.png']);
    save([pwd,'/DepthEstimates/',Name{:},'.mat'],'InitialStart','InitialMin','InitialMax','NewDepthLims');
end 
    