function LastStep = Step1_CreateBufferGVP(LastStep, lat, lon, VolcName, rad2m, Options)

% Ben Ireland, July 2024, University of Bristol
BufferDist = Options.Mask_BufferDist; % Buffer size (Pixels) - buffer is circular

GVP_List = readtable([pwd,'/GBIS/GVP/','GVP_Volcano_List_HoloceneXLS.xls']);

if ~exist([pwd,'/Buffers'],'dir')
    mkdir(pwd,'Buffers')
    addpath([pwd,'/Buffers'])
end
% Extract name of closest volcano to the centrepoint of the
% interferogram and compare this to the name of the interferogram (should be the same)
lon = lon(1,:).';
lat = lat(:,1);

CentrePointLL = [lon(round(length(lon)/2)), lat(round(length(lat)/2))];
data.LonDiff = table2array(GVP_List(:,10)) - CentrePointLL(1);
data.LatDiff = table2array(GVP_List(:,9)) - CentrePointLL(2);
data.Distance = sqrt(data.LatDiff.^2 + data.LonDiff.^2);

% Find the row with the minimum distance
[~, minIdx] = min(data.Distance);

% Corresponding Volcano Name and check if this matches filename
IfgVolcano = char(GVP_List.VolcanoName(minIdx));

if ~contains(VolcName,IfgVolcano,'IgnoreCase',true)
    disp('GVP name and given volcano name do not match')
end

disp('Removing data around other volcanoes in the frame')

% Extend lat and lon by the buffer amount to exclude pixels of volcanoes just outside the AOI
lonDiff = lon(2)-lon(1);
if sign(lonDiff) ==1
    minlonExt = min(lon) - (lonDiff*BufferDist);
    maxlonExt = max(lon) + (lonDiff*(BufferDist+1));
else
    minlonExt = min(lon) + (lonDiff*BufferDist);
    maxlonExt = max(lon) - (lonDiff*BufferDist);
end
lonExt = minlonExt:abs(lonDiff):maxlonExt;
lonExt = lonExt';

latDiff = lat(2)-lat(1);
if sign(latDiff) ==1
    minlatExt = min(lat) - (latDiff*BufferDist);
    maxlatExt = max(lat) + (latDiff*BufferDist);
else
    minlatExt = min(lat) + (latDiff*(BufferDist+1));
    maxlatExt = max(lat) - (latDiff*BufferDist);
end

if latDiff<0
    latExt = maxlatExt:latDiff:minlatExt;
    latExt = latExt';
else
    latExt = maxlatExt:-latDiff:minlatExt;
    latExt = latExt';
end

if size(latExt,1) > (size(lat,1) + 2*BufferDist)
    latExt = latExt(1:(size(lat,1) + 2*BufferDist));
end
if size(lonExt,1) > (size(lon,1) + 2*BufferDist)
    lonExt = lonExt(1:(size(lon,1) + 2*BufferDist));
end

% Extract all volcanoes within the ifg region (currently calculates on a normal and extended grid (for volcanoes just outside the frame) 
% but only the extended one is needed
iInBox = find(GVP_List.Latitude < max(lat) & GVP_List.Latitude > min(lat)  & GVP_List.Longitude > min(lon) & GVP_List.Longitude < max(lon));
iInBoxExt = find(GVP_List.Latitude < max(latExt) & GVP_List.Latitude > min(latExt)  & GVP_List.Longitude > min(lonExt) & GVP_List.Longitude < max(lonExt));
iInBox(iInBox==minIdx) = [];
iInBoxExt(iInBoxExt==minIdx) = [];

if ~isempty(iInBox)
    AllVolcs = GVP_List.VolcanoName(iInBox);
    disp('Other volcanoes in the frame are:')
    disp(char(AllVolcs))
    AllVolcsExt = GVP_List.VolcanoName(iInBoxExt);
    disp('Other volcanoes in the frame and just outside are:')
    disp(char(AllVolcsExt))

    % Create buffers around volcano
    VolcPoints = [GVP_List.Latitude(iInBox), GVP_List.Longitude(iInBox)];
    VolcPointsExt = [GVP_List.Latitude(iInBoxExt), GVP_List.Longitude(iInBoxExt)];

    % Convert lat-lon to pixels (find closest lat and lon idx)
    LatIdxs = knnsearch(lat,VolcPoints(:,1));
    LonIdxs = knnsearch(lon,VolcPoints(:,2));

    LatIdxsExt = knnsearch(latExt,VolcPointsExt(:,1));
    LonIdxsExt = knnsearch(lonExt,VolcPointsExt(:,2));

    VolcBuffers = polybuffer([LonIdxs,LatIdxs],'points',BufferDist);
    [x, y] = boundary(VolcBuffers);
    VolcBuffersExt = polybuffer([LonIdxsExt,LatIdxsExt],'points',BufferDist);
    [xExt, yExt] = boundary(VolcBuffersExt);

    MaskVolc = mpoly2mask([x,y],[size(LastStep,1),size(LastStep,2)]);
    MaskVolcExt = mpoly2mask([xExt,yExt],[size(latExt,1),size(lonExt,1)]);
    MaskVolcExtCrop = MaskVolcExt(BufferDist+1:end-BufferDist,BufferDist+1:end-BufferDist);

    % Mask displacement data
    LastStep(MaskVolcExtCrop) = NaN;
    LastStep2 = LastStep;
    LastStep2(LastStep==0) = NaN;
    
    f = figure();
    h = imagesc(-1*LastStep2.*rad2m);
    set(h, 'AlphaData', ~isnan(LastStep2));
    axis image
    colormap(gcf, flipud(cbrewer2('RdBu', 256)));
    c = colorbar;
    c.Label.String = 'LOS Disp. (m)';
    cmax = max(abs(-1*LastStep2(:))).*rad2m;
    clim([-cmax, cmax]);
    title('Volcanoes in frame and just outside:');
    subtitle(strjoin(AllVolcsExt,', '));

    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
    set(gca,'Xticklabel',[]);
    set(gca,'Yticklabel',[]);

    hold on
    plot(LonIdxs,LatIdxs,'k.','MarkerSize',10);
    hold off
    saveas(f,[pwd,'/Buffers/',VolcName,'_Buffer.png']);
else
    disp('No other volcanoes within the frame')
    LastStep2 = LastStep;
    LastStep2(LastStep==0) = NaN;
    f = figure();
    h = imagesc(-1*LastStep2.*rad2m);
    set(h, 'AlphaData', ~isnan(LastStep2));
    axis image
    colormap(gcf, flipud(cbrewer2('RdBu', 256)));
    c = colorbar;
    c.Label.String = 'LOS Disp. (m)';
    cmax = max(abs(-1*LastStep2(:))).*rad2m;
    clim([-cmax, cmax]);
    title('No other volcanoes in the frame');

    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
    set(gca,'Xticklabel',[]);
    set(gca,'Yticklabel',[]);
    saveas(f,[pwd,'/Buffers/',VolcName,'_Buffer.png']);
end

if Options.IgnoreLastStep ==1
    save([pwd,'/Buffers/',VolcName,'_BufferNoLast.mat'],'LastStep');
else
    save([pwd,'/Buffers/',VolcName,'_BufferWithLast.mat'],'LastStep');
end

end