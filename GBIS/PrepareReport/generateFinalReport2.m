function generateFinalReport2(invResFile,burning)

% Function to generate summary text file, results plots, and html report
%
% Usage: generateFinalReport(invResFile,burning)
% Input parameters:
%           invResFile: path and name to file with final results of
%                       inversion 
%                       (e.g.,'VolcanoExercise/invert_1__MOGI_DIKE.mat')
%           burning:    number of iterations to ignore in pdf histogram plot
%                       and in computation of mean/median/confidence interval
% =========================================================================
% This function is part of the:
% Geodetic Bayesian Inversion Software (GBIS)
% Software for the Bayesian inversion of geodetic data.
% Copyright: Marco Bagnardi, 2018
%
% Email: gbis.software@gmail.com
%
% Reference: 
% Bagnardi M. & Hooper A, (2018). 
% Inversion of surface deformation data for rapid estimates of source 
% parameters and uncertainties: A Bayesian approach. Geochemistry, 
% Geophysics, Geosystems, 19. https://doi.org/10.1029/2018GC007585
%
% The function may include third party software.
% =========================================================================
% Last update: 8 August, 2018
%
% NOVEMBER 2023 - BEN IRELAND - ADDED FIGURES USING RAW DATA AND REMOVED CHOICE STATEMENTS FOR BULK APPLICATIONS

%%
if nargin < 2
    disp('!!!!!!! Not enough input parameters. !!!!!!!!!')
    return;
end

clear  outputDir  % Clear global variables
global outputDir  % Set global variables

%% ADDED - Make directories for figures - create folder structure
global inputFileN %Added

warning('off','all')

load(invResFile);   % load results

outputDir = pwd;

% Make a folder for the forward model if it does not exist
if ~exist([pwd,'/Model'],'dir')
    mkdir(pwd,'/Model')
    addpath([pwd,'/Model'])
end
% Make a folder for residuals if it does not exist
if ~exist([pwd,'/Residual'],'dir')
    mkdir(pwd,'/Residual')
    addpath([pwd,'/Residual'])
end
% Make a folder for summary figures if it does not exist
if ~exist([pwd,'/Summary_Figures'],'dir')
    mkdir(pwd,'/Summary_Figures')
    addpath([pwd,'/Summary_Figures'])
end
% Make a folder for summary reports if it does not exist
if ~exist([pwd,'/Summary_Reports'],'dir')
    mkdir(pwd,'/Summary_Reports')
    addpath([pwd,'/Summary_Reports'])
end

% Create colormaps for plotting InSAR data
cmap.Seismo = colormap_cpt('GMT_seis.cpt', 100); % GMT Seismo colormap for wrapped interferograms
cmap.RnB = colormap_cpt('polar.cpt', 100); % Red to Blue colormap for unwrapped interferograms

nParam = length(invResults.mKeep(:,1)); % Number of model parameters

% Number of empty cells at the end of mKeep and pKeep
if invpar.nRuns < 10000
    blankCells = 999; 
else
    blankCells = 9999;
end

inputFileN = inputFile.name; %Added
saveName = saveName(1:end-4); %Added
mkdir([outputDir,'/','Summary_Figures/',inputFile.name,'/',saveName]); %Added
mkdir([outputDir,'/','Summary_Reports/',inputFile.name,'/',saveName]); %Added


%% Print results to text file
% Print optimal, mean, median, 2.5th and 97.5th percentiles 
format shortG

txtName = ['/summary',saveName(7:end-4),'.txt']; % name of text file
fileID = fopen([outputDir,'/','Summary_Reports/',inputFile.name,'/',saveName,txtName],'w');
fprintf(fileID,'%s\r\n','GBIS');
fprintf(fileID,'%s\r\n',['Summary for ',saveName(1:end-4)]);
fprintf(fileID,'%s\r\n',['Number of iterations: ',num2str(invpar.nRuns)]);
fprintf(fileID,'%s\r\n',['Burning time (n. of iterations): ',num2str(burning)]);
fprintf(fileID,'%s\r\n','================================================================================================');
fprintf(fileID,'%s\r\n','MODEL PARAM.      OPTIMAL         MEAN            Median          2.5%            97.5%');

for i = 1:nParam-1
    fprintf(fileID,'%12s\t %8g\t %8g\t %8g\t %8g\t %8g\r\n', ...
        char(invResults.model.parName(i)), invResults.model.optimal(i), ...
        mean(invResults.mKeep(i, burning:end-blankCells)), median(invResults.mKeep(i, burning:end-blankCells)), ...
        prctile(invResults.mKeep(i, burning:end-blankCells),2.5), prctile(invResults.mKeep(i, burning:end-blankCells),97.5));
end

% Display text on screen
clc
type([outputDir,'/','Summary_Reports/',inputFile.name,'/',saveName,txtName])

%% Create report html file
htmlName = ['/report',saveName(7:end-4),'.html']; % HTML file name

% Print header and summary to file
fidHTML = fopen([outputDir,'/','Summary_Reports/',inputFile.name,'/',saveName,htmlName],'w');
fprintf(fidHTML, '%s\r\n', '<!DOCTYPE html>');
fprintf(fidHTML, '%s\r\n', '<html>');
fprintf(fidHTML, '%s\r\n', '<head>');
fprintf(fidHTML, '%s\r\n', ['<H1>GBIS Final report for <i>', saveName(1:end-4),'</i></H1>']);
fprintf(fidHTML, '%s\r\n', ['<H3>Results file: <i>',outputDir,'/',saveName,'</i></H3>']);
fprintf(fidHTML, '%s\r\n', ['<p>Number of iterations: ', num2str(invpar.nRuns),'</p>']);
fprintf(fidHTML, '%s\r\n', ['<p>Burning time (n. of iterations from start): ', num2str(burning),'</p>']);
fprintf(fidHTML, '%s\r\n', '<hr>');
fprintf(fidHTML, '%s\r\n', '<H3>Model parameters</H3>');
fprintf(fidHTML, '%s\r\n', '<style>');
fprintf(fidHTML, '%s\r\n', 'table {font-family: arial, sans-serif; border-collapse: collapse; width:100%%;}');
fprintf(fidHTML, '%s\r\n', 'td, th {border: 1px solid #dddddd;text-align: right;padding: 8px;}');
fprintf(fidHTML, '%s\r\n', 'tr:nth-child(even) {background-color: #bbb;}');
fprintf(fidHTML, '%s\r\n', '</style>');
fprintf(fidHTML, '%s\r\n', '</head>');
fprintf(fidHTML, '%s\r\n', '<body>');
fprintf(fidHTML, '%s\r\n', '<table>');
fprintf(fidHTML, '%s\r\n', '<tr> <th>Parameter</th> <th>Optimal</th> <th>Mean</th> <th>Median</th> <th>2.5%</th> <th>97.5%</th></tr>');
for i = 1:nParam-1
    fprintf(fidHTML, '%s\r\n',['<tr> <td>',char(invResults.model.parName(i)),...
        '</td> <td>', num2str(invResults.model.optimal(i), '%.2f'), ...
        '</td> <td>', num2str(mean(invResults.mKeep(i,burning:end-blankCells)), '%.2f'), ...
        '</td> <td>', num2str(median(invResults.mKeep(i,burning:end-blankCells)), '%.2f'),...
        '</td> <td>', num2str(prctile(invResults.mKeep(i,burning:end-blankCells),2.5), '%.2f'), ...
        '</td> <td>', num2str(prctile(invResults.mKeep(i,burning:end-blankCells),97.5), '%.2f'), ...
        '</td> </tr>']);
end
fprintf(fidHTML, '%s\r\n', '</table> </body>');


%% Plot convergence of all parameters

figure('Position', [1, 1, 1200, 1000]);
for i = 1:nParam-1
    subplot(round(nParam/3),3,i)    % Determine poistion in subplot
    plot(1:100:length(invResults.mKeep(1,:))-blankCells, invResults.mKeep(i,1:100:end-blankCells),'r.') % Plot one point every 100 iterations
    title(invResults.model.parName(i))
end
% Save image as png
img = getframe(gcf);
imwrite(img.cdata, [outputDir,'/','Summary_Figures/',inputFile.name,'/',saveName,'/Convergence.png']); %Edited

% Add image to html report
fprintf(fidHTML, '%s\r\n', '<hr>');
fprintf(fidHTML, '%s\r\n', '<H3>Convergence plots</H3>');
filepath = [outputDir,'/','Summary_Figures/',inputFile.name,'/',saveName,'/Convergence.png']; %Added
fprintf(fidHTML, '<img src="%s" alt="HTML5 Icon">\n', filepath); %Edited

%% Plot histograms and optimal values

figure('Position', [1, 1, 1200, 1000]);
for i = 1:nParam-1
    subplot(round(nParam/3),3,i) % Determine poistion in subplot
    xMin = mean(invResults.mKeep(i,burning:end-blankCells))-4*std(invResults.mKeep(i,burning:end-blankCells));
    xMax = mean(invResults.mKeep(i,burning:end-blankCells))+4*std(invResults.mKeep(i,burning:end-blankCells));
    bins = xMin: (xMax-xMin)/50: xMax;
    h = histogram(invResults.mKeep(i,burning:end-blankCells),bins,'EdgeColor','none','Normalization','count');
    hold on
    topLim = max(h.Values);
    plot([invResults.model.optimal(i),invResults.model.optimal(i)],[0,topLim+10000],'r-') % Plot optimal value
    ylim([0 topLim+10000])
    title(invResults.model.parName(i))
end
% Save image as png
img = getframe(gcf);

imwrite(img.cdata,[outputDir,'/','Summary_Figures/',inputFile.name,'/',saveName,'/PDFs.png']); %Edited

% Add image to html report
fprintf(fidHTML, '%s\r\n', '<hr>');
fprintf(fidHTML, '%s\r\n', '<BR></BR><H3>Model parameters posterior probabilities and optimal values</H3>');
filepath = [outputDir,'/','Summary_Figures/',inputFile.name,'/',saveName,'/PDFs.png']; %Added
fprintf(fidHTML, '<img src="%s" alt="HTML5 Icon">\n', filepath); %Edited

%% Plot joint probabilities
        
        figure('Position', [1, 1, 1200, 1000]);
        plotmatrix_lower(invResults.mKeep(1:nParam-1,burning:invpar.nRuns-1)','contour'); %Edited
        img1 = getframe(gcf);
        imwrite(img1.cdata,[outputDir,'/','Summary_Figures/',inputFile.name,'/',saveName,'/JointProbabilities.png']); %Edited
        filepath = [outputDir,'/','Summary_Figures/',inputFile.name,'/',saveName,'/JointProbabilities.png']; %Added
        
        % Add image to html report
        fprintf(fidHTML, '%s\r\n', '<hr>');
        fprintf(fidHTML, '%s\r\n', '<H3>Joint probabilities</H3>');
        fprintf(fidHTML, '<img src="%s" alt="HTML5 Icon">\n', filepath); %Edited

%% Plot comparison betweem data, model, and residual

% Optional

        % Plot GPS data, model
        
        if exist('gps') ==1 %Modified from original code (didn't have the ==1)
            plotGPSDataModel(gps,geo,invpar, invResults, modelInput, saveName, 'y')
                        
            % Add image to html report
            fprintf(fidHTML, '%s\r\n', '<hr>');
            fprintf(fidHTML, '%s\r\n', '<H3>Comparison GPS Data vs. Model</H3>');
            fprintf(fidHTML, '<img src="%s" alt="HTML5 Icon">\n', filepath); %Edited
        end
        
        % Plot InSAR data, model, residual
        if exist('insarDataCode') ==1
            plotInSARDataModelResidual(insar, geo, invpar, invResults, modelInput, saveName, fidHTML, 'y')
        end

%% Plot comparison betweem raw data, model, and residual - added

% Optional
        % Plot GPS data, model
        
        if exist('gps') ==1 %Modified from original code (didn't have the ==1)
            plotGPSDataModel(gps,geo,invpar, invResults, modelInput, saveName, 'y')
                        
            % Add image to html report
            fprintf(fidHTML, '%s\r\n', '<hr>');
            fprintf(fidHTML, '%s\r\n', '<H3>Comparison GPS Data vs. Model</H3>');
            fprintf(fidHTML, '<img src="%s" alt="HTML5 Icon">\n', filepath); %Edited
        end
        
        % Plot InSAR data, model, residual
        if exist('insarDataCode') ==1
            plotInSARDataModelResidual_raw(insar, geo, invpar, invResults, modelInput, saveName, fidHTML, 'y')
        end

fclose(fidHTML);
