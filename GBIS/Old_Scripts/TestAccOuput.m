clear all
close all

Files = dir([pwd,'/Accuracy_Precision/','*.mat']);

% Load files and split by downsampling method
for k = 1:length(Files)
    File = char(strcat(Files(k).folder,'/',Files(k).name));
    Output = load(File);
    if contains(Files(k).name,'QuadtreeV2')
        QT(k) = Output;
    elseif contains(Files(k).name,'DECB')
        DEC(k) = Output;
    elseif contains(Files(k).name,'DistCF')
        DistCF(k) = Output;
    elseif contains(Files(k).name,'CF50B')
        CF50(k) = Output;
    end
    Size{k} = Output.Info.Size;
end

% Remove empty rows (all of these should be the same length)
emptyRows = squeeze(all(cellfun(@isempty, struct2cell(QT)), 1));
QT(emptyRows)=[];
emptyRows = squeeze(all(cellfun(@isempty, struct2cell(DEC)), 1));
DEC(emptyRows)=[];
emptyRows = squeeze(all(cellfun(@isempty, struct2cell(DistCF)), 1));
DistCF(emptyRows)=[];
emptyRows = squeeze(all(cellfun(@isempty, struct2cell(CF50)), 1));
CF50(emptyRows)=[];

% Find different sizes in the input files (different sized sources)
Sizes = unique(Size);
nSizes = length(Sizes);

for i = 1:nSizes
    for j = 1:length(QT)
        QTi(i,j) = strcmp({QT(j).Info.Size}, Sizes{i});
        DECi(i,j) = strcmp({DEC(j).Info.Size}, Sizes{i});
        DistCFi(i,j) = strcmp({DistCF(j).Info.Size}, Sizes{i});
        CF50i(i,j) = strcmp({CF50(j).Info.Size}, Sizes{i});
    end
end
DS_Methods = {'Quadtree', 'Decimation', 'Otsu-distance-based', 'Otsu-based CF'};
%% Box plots of accuracy and precision
% Plot boxplots of 'inversion result - optimal value'
for i = 1:nSizes
    % New figure for each size
    f(i) = figure();
    tl(i) = tiledlayout(2,2,"TileSpacing","tight",'Padding','tight');
    tl(i).Title.String  = [Sizes{i},': Accuracy'];

    for m = 1:QT(1).Info.nParam
        nexttile
        BoxData = [QT(QTi(i,:)).AccuracyFull(m),DEC(DECi(i,:)).AccuracyFull(m),CF0(CF0i(i,:)).AccuracyFull(m),CF50(CF50i(i,:)).AccuracyFull(m),CF100(CF100i(i,:)).AccuracyFull(m)];
        AccHeat(m,i,:) = abs(mean(BoxData,1));
        AccBox = boxchart(reshape(BoxData',1,[]),'GroupByColor',BoxData); % Assign color groups
        xticklabels({''});
        ylim([-1*max(abs(BoxData(:))),max(abs(BoxData(:)))]);
        if m==1
            ylabel('X Location (m)');
        end
        if m==2
            ylabel('Y Location (m)')
            % Add legend
            legend([DS_Methods],'Location','northeastoutside')
        end
        if m==3
            ylabel('Depth (m)')
        end
        if m==4
            ylabel('Volume change (m^3)')
        end
    end

end

Plot boxplots of inversion results with y line for each optimal value
for i = 1:nSizes
    % New figure for each size
    f2(i) = figure();
    tl2(i) = tiledlayout(2,2,"TileSpacing","tight",'Padding','tight');
    tl2(i).Title.String  = [Sizes{i},': Optimal Results'];

    for m = 1:QT(1).Info.nParam
        nexttile
        BoxData = [QT(QTi(i,:)).AccuracyFull(m) + QT(QTi(i,:)).Info.OptValues(m)...
            ,DEC(DECi(i,:)).AccuracyFull(m) + DEC(DECi(i,:)).Info.OptValues(m)...
            ,CF0(CF0i(i,:)).AccuracyFull(m) + CF0(CF0i(i,:)).Info.OptValues(m)...
            ,CF50(CF50i(i,:)).AccuracyFull(m) + CF50(CF50i(i,:)).Info.OptValues(m)...
            ,CF100(CF100i(i,:)).AccuracyFull(m) + CF100(CF100i(i,:)).Info.OptValues(m)];
        AccBox = boxchart(reshape(BoxData',1,[]),'GroupByColor',BoxData); % Assign color groups
        xticklabels({''});
        ylim([-1*max(abs(BoxData(:))),max(abs(BoxData(:)))]);

        hold on
        yline(QT(QTi(i,:)).Info.OptValues(m),'--','Synthetic value','LineWidth',1.5);
        hold off
        if m==1
            ylabel('X Location (m)');
        end
        if m==2
            ylabel('Y Location (m)')
            % Add legend
            legend([DS_Methods,'Synthetic source parameter'],'Location','northeastoutside')
        end
        if m==3
            ylabel('Depth (m)')
        end
        if m==4
            ylabel('Volume change (m^3)')
        end
    end
end

% Plot boxplots of precision
for i = 1:nSizes
    % New figure for each size
    f3(i) = figure();
    tl3(i) = tiledlayout(2,2,"TileSpacing","tight",'Padding','tight');
    tl3(i).Title.String  = [Sizes{i},': Precision'];

    for m = 1:QT(1).Info.nParam
        nexttile
        BoxData = [QT(QTi(i,:)).PrecisionFull(m),DEC(DECi(i,:)).PrecisionFull(m),CF0(CF0i(i,:)).PrecisionFull(m),CF50(CF50i(i,:)).PrecisionFull(m),CF100(CF100i(i,:)).PrecisionFull(m)];
        PrecHeat(m,i,:) = abs(mean(BoxData,1));
        PrecBox = boxchart(reshape(BoxData',1,[]),'GroupByColor',BoxData); % Assign color groups
        xticklabels({''});
        ylim([-1*max(abs(BoxData(:))),max(abs(BoxData(:)))]);
        if m==1
            ylabel('X Location (m)');
        end
        if m==2
            ylabel('Y Location (m)')
            % Add legend
            legend([DS_Methods],'Location','northeastoutside')
        end
        if m==3
            ylabel('Depth (m)')
        end
        if m==4
            ylabel('Volume change (m^3)')
        end
    end
end
%% Heatmaps of accuracy and precision
% Accuracy heatmap
f4 = figure();
tl4 = tiledlayout(2,2,"TileSpacing","tight",'Padding','tight');
tl4.Title.String  = 'Accuracy';
for m = 1:QT(1).Info.nParam
    nexttile
    H(m) = heatmap(Sizes,DS_Methods,(squeeze(AccHeat(m,:,:)))','Colormap',summer,'ColorbarVisible','off','ColorScaling','scaledcolumns','ColorLimits',[0 1]);
    if m==1
        title('X Location (m)');
    end
    if m==2
        title('Y Location (m)')
    end
    if m==3
        title('Depth (m)')
    end
    if m==4
        title('Volume change (m^3)')
    end
end

% Precision heatmap
f5 = figure();
tl5 = tiledlayout(2,2,"TileSpacing","tight",'Padding','tight');
tl5.Title.String  = 'Precision (95% confidence)';
for m = 1:QT(1).Info.nParam
    nexttile
    H2(m) = heatmap(Sizes,DS_Methods,(squeeze(PrecHeat(m,:,:)))','Colormap',summer,'ColorbarVisible','off','ColorScaling','scaledcolumns','ColorLimits',[0 1]);
    if m==1
        title('X Location (m)');
    end
    if m==2
        title('Y Location (m)')
    end
    if m==3
        title('Depth (m)')
    end
    if m==4
        title('Volume change (m^3)')
    end
end