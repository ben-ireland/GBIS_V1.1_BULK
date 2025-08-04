function Figure = plotSummarySynResults(Accuracy,Precision,Info,ID)

% Accuracy and precision should be split by size and have n x m cols

% Import colorblind colormap and InSAR colormaps
load([pwd,'/GBIS/Bulk_Scripts/colorblind_colormap/colorblind_colormap.mat']);
boxColors = [colorblind(7,:); colorblind(8,:); colorblind(6,:); colorblind(11,:)];

% Box and whisker plots
for n = 1:length(Info.Sizes)
    figure()
    BoxPlotAcc(n) = tiledlayout(2,2);
    BoxPlotAcc(n).TileSpacing = 'tight';
    BoxPlotAcc(n).Title.String = {['Run ID: ',ID]};
    Units = {'X location (m)','Y location (m)', 'Depth (m)', 'Volume change (m^3)'};
    
    for m = 1:length(Info.ParaNames)
        ax = nexttile
        title(ParaNames{m})
        ylabel(Units{m})
        fontsize(ax,16,'points')
        hold on
        
        BoxData = [AccSmallCoherence(:,m),AccSmallAvg(:,m),AccSmallDec(:,m),AccSmallCoThresh(:,m)];

        AccBox = boxchart(reshape(BoxData',1,[]), 'GroupByColor', repmat(1:4, 1,size(BoxData, 1))); % Plot boxchart and assign color groups

        OptScat = yline(OptValues(n,m),'--','Synthetic value','LineWidth',1.5);

        xticklabels({''});

        if m==2                
            legend([DS_Methods,'Synthetic source parameter'],'Location','northeastoutside')
        end
    end
    hold off
end
end