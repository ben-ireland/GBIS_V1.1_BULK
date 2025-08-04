function ReportFilename = generateFinalReportPDF(invResFile,SignalLocationGBIS,burning,Options)

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


import mlreportgen.report.* 
import mlreportgen.dom.*


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
if invpar.nRuns <= 10000
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
type([outputDir,'/','Summary_Reports/',inputFile.name,'/',saveName,txtName])

%% Initialise Report
disp('Creating PDF report of GBIS results')
% Create report html file
PDFName = ['/report',saveName(7:end-4),'.pdf']; % PDF file name
OutputReportName = [outputDir,'/','Summary_Reports/',inputFile.name,'/',saveName,PDFName(1:end-4)];
ReportFilename = [OutputReportName,'.pdf'];
rpt = Report(OutputReportName,'pdf');

% Beginning of report
ch1 = Chapter();
ch1.Title =sprintf(['GBIS Final report for ', saveName]);

sec1 = Section;
sec1.Title = ['Results file path: ',invResFile];
para = Paragraph([...
    ['Number of iterations: ',num2str(invpar.nRuns)],newline,...
    [' | ','Burn-in time (n. of iterations from start): ',num2str(burning)],...
    [' | ', 'Number of InSAR datasets used: ',num2str(length(insar))]]);

para2 = Paragraph(['Signal location and offset parameters:'...
    ' Signal location (Lat/Lon): [', num2str(SignalLocationGBIS.LatLon(1)),', ',num2str(SignalLocationGBIS.LatLon(2)),'] | ',...
    'Signal offset from target volcano (km): ',num2str(SignalLocationGBIS.offsetKm),' | ',...
    'Signal offset bearing from target volcano (degrees from north): ',num2str(SignalLocationGBIS.bearingDeg)]);

append(sec1,para)
append(sec1,para2)
append(ch1,sec1)

% Add figures and tables
disp('')
disp('Adding elements to report: ')

%% Plot comparison betweem data, model, and residual
sec2 = Section;
sec2.Title = 'Comparison InSAR Data - Model - Residual (Downsampled data)';

% Plot GPS data, model

if exist('gps') ==1 %Modified from original code (didn't have the ==1)
    plotGPSDataModel(gps,geo,invpar, invResults, modelInput, saveName, 'y')
end

% Plot InSAR data, model, residual
if exist('insarDataCode') ==1
    disp('Downsampled DMRs')
    name = plotInSARDataModelResidualPDF(insar, geo, invpar, invResults, modelInput, saveName, 'y');

    for k = 1:length(insar)
        % Add image to PDF report
        image = FormalImage();
        image.Image = [outputDir,'/','Summary_Figures/',inputFileN,'/',saveName,'/InSAR_Data_Model_Residual_',name{k},num2str(k),'.png'];
        image.Caption = ['Image filepath: ','Summary_Figures/',inputFileN,'/',saveName,'/InSAR_Data_Model_Residual_',name{k},num2str(k),'.png'];
        append(sec2, image);
        clear image
    end
end
append(ch1, sec2)

%% Plot comparison betweem raw data, model, and residual - added
sec3 = Section;
sec3.Title = 'Comparison InSAR Data - Model - Residual (Full resolution)';

% Optional
% Plot GPS data, model

if exist('gps') ==1 %Modified from original code (didn't have the ==1)
    plotGPSDataModel(gps,geo,invpar, invResults, modelInput, saveName, 'y')
end

% Plot InSAR data, model, residual
if exist('insarDataCode') ==1
    disp('Full-res DMRs (takes longer)')
    name_raw = plotInSARDataModelResidual_rawPDF(insar, geo, invpar, invResults, modelInput, saveName, 'y');

    for k = 1:length(insar)
        % Add image to PDF report
        image = FormalImage();
        image.Image = [outputDir,'/','Summary_Figures/',inputFileN,'/',saveName,'/InSAR_Data_Model_Residual_',name_raw{k},num2str(k),'.png'];
        image.Caption = ['Image filepath: ','Summary_Figures/',inputFileN,'/',saveName,'/InSAR_Data_Model_Residual_',name_raw{k},num2str(k),'.png'];
        append(sec3, image);
        clear image
    end
end
append(ch1, sec3)

% Table of model parameters
% Add table of starting parameters
sec4 = Section;
disp('Model input and output tables')
for k = 1:length(invpar.model)
    sec4.Title = ['Model input parameters - ',invpar.model{k}];

    % Verify model names
    modelTypes = fieldnames(modelInput);
    for i = 1:length(modelTypes);
        if contains(modelTypes{i},invpar.model{k},'IgnoreCase',true)
            ModelName = modelTypes{i};
        end
    end

    if isstruct(modelInput.(ModelName))
        Inputs = [modelInput.(ModelName).start,...
                modelInput.(ModelName).step,...
                modelInput.(ModelName).lower,...
                modelInput.(ModelName).upper];
    else
        Inputs = [modelInput.(ModelName){k}.start,...
                modelInput.(ModelName){k}.step,...
                modelInput.(ModelName){k}.lower,...
                modelInput.(ModelName){k}.upper];
    end

    Inputs = num2cell(Inputs);
    Inputs = cellfun(@(x) sprintf('%.2f', x), Inputs, 'UniformOutput', false);
    Inputs = [{'Start','Step','Lower','Upper'}; Inputs];
    newCol = [{'Parameters'},cell(invResults.model.parName)];

    if insar{1}.constOffset=='y' % Remove constant offset values
        NewNPara = size(Inputs,1)-1;
        newCol = newCol(1:NewNPara+1);
    end
    
    if length(invpar.model) >1
        NewNPara = length(modelInput.(ModelName).start);
        if k==1
            newCol = newCol(1:NewNPara+1);
            LastIdx = NewNPara+1;
        else
            newCol = newCol([1,LastIdx+1:LastIdx+NewNPara]);
        end
    end
    
    Inputs = [newCol',Inputs];

    tbl2 = Table(Inputs);
    tbl2.Style = {... 
        RowSep('solid','black','1px'),... 
        ColSep('solid','black','1px'),...
            FontSize('12pt')}; 
    tbl2.Border = 'double'; 
    tbl2.TableEntriesStyle = {HAlign('center')}; 

    append(sec4,tbl2)
end
append(ch1, sec4)

sec5 = Section;
sec5.Title = 'Model Parameters';
ModelParams = [invResults.model.optimal(1:nParam-1),...
    round(mean(invResults.mKeep(1:nParam-1,burning:end-blankCells),2),2),...
    round(median(invResults.mKeep(1:nParam-1,burning:end-blankCells),2),2),...
    round(prctile(invResults.mKeep(1:nParam-1,burning:end-blankCells),2.5,2),2),...
    round(prctile(invResults.mKeep(1:nParam-1,burning:end-blankCells),97.5,2),2)];

% Parameter names
Parameter = char(invResults.model.parName);

if contains(invpar.model,'SILL') || contains(invpar.model,'DIKE')
    % Change strike if needed (4th column if sill, 5th column if dike)
    IdxStrike = find(contains(model.parName,'Strike'));
    % Convert strike to be within 0 and 180 degrees (if Sill)
    if contains(invpar.model,'SILL')
        if ModelParams(IdxStrike,1) >180
            for j = 1:width(ModelParams)
                ModelParams(IdxStrike,j) = ModelParams(IdxStrike,j)-180;
            end
        end
    end

    if Options.ModifyStrike==1 % Change strike if width is bigger than length
        if ModelParams(IdxStrike,1) + 90 <=180 & ModelParams(IdxStrike,1) + 90 >=0
            for j = 1:width(ModelParams)
                ModelParams(IdxStrike,j) = ModelParams(IdxStrike,j) + 90;
            end
        else
            for j = 1:width(ModelParams)
                ModelParams(IdxStrike,j) = ModelParams(IdxStrike,j) - 90;
            end
        end
    end

    % Add on volume column 
    pIdxL = find(contains(model.parName,'Length'));
    pIdxW = find(contains(model.parName,'Width'));
    pIdxO = find(contains(model.parName,'Opening'));

    numRows = height(ModelParams);
    
    for j = 1:width(ModelParams)
        ModelParams(numRows+1,j) = ModelParams(pIdxL,j)*ModelParams(pIdxW,j)*ModelParams(pIdxO,j);
    end
    
    Parameter = char(Parameter,'Volume');
end

T = array2table(ModelParams,...
    'VariableNames',{'Optimal', 'Mean', 'Median', '2.5%', '97.5%'});
T2 = table(Parameter);
T = [T2,T];
Tcell = table2cell(T(:,2:end));
Tcell = cellfun(@(x) sprintf('%.2f', x), Tcell, 'UniformOutput', false);
Tcell = [cellstr(Parameter), Tcell];
newRow = {'Parameter','Optimal', 'Mean', 'Median', '2.5%', '97.5%'};
Tcell = [newRow; Tcell];

tbl = Table(Tcell);
tbl.Style = {... 
    RowSep('solid','black','1px'),... 
    ColSep('solid','black','1px'),...
        FontSize('12pt')}; 
tbl.Border = 'double'; 
tbl.TableEntriesStyle = {HAlign('center')}; 
append(sec5,tbl)
append(ch1, sec5)


%% Add summary figures

sec6 = Section;
sec6.Title = 'Convergence Plots';
disp('Convergence plots')

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

% Add image to PDF report
image = FormalImage();
image.Image = [outputDir,'/','Summary_Figures/',inputFile.name,'/',saveName,'/Convergence.png'];
image.Caption = ['Image filepath: ','Summary_Figures/',inputFile.name,'/',saveName,'/Convergence.png'];
append(sec6, image); 
append(ch1, sec6)

clear image

%% Plot histograms and optimal values
sec7= Section;
sec7.Title = 'Model parameters posterior probabilities and optimal values';
disp('PDFs')

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

% Add image to PDF report
image = FormalImage();
image.Image = [outputDir,'/','Summary_Figures/',inputFile.name,'/',saveName,'/PDFs.png'];
image.Caption = ['Image filepath: ','Summary_Figures/',inputFile.name,'/',saveName,'/PDFs.png'];
append(sec7, image); 
append(ch1, sec7)

clear image

%% Plot joint probabilities
sec8 = Section;
sec8.Title = 'Joint probabilities';
disp('Joint probabilities')


figure('Position', [1, 1, 1200, 1000]);
try
    plotmatrix_lower(invResults.mKeep(1:nParam-1,burning:invpar.nRuns-1)','contour'); %Edited
catch
    plot(NaN,NaN);
    title('plotmatrix_lower function crashed')
    subtitle('Try re-running step 9')
end
img1 = getframe(gcf);
imwrite(img1.cdata,[outputDir,'/','Summary_Figures/',inputFile.name,'/',saveName,'/JointProbabilities.png']); %Edited
filepath = [outputDir,'/','Summary_Figures/',inputFile.name,'/',saveName,'/JointProbabilities.png']; %Added

% Add image to PDF report
image = FormalImage();
image.Image = [outputDir,'/','Summary_Figures/',inputFile.name,'/',saveName,'/JointProbabilities.png'];
image.Caption = ['Image filepath: ','Summary_Figures/',inputFile.name,'/',saveName,'/JointProbabilities.png'];
append(sec8, image); 
append(ch1, sec8)

disp('')
disp('Finalising report')
append(rpt,ch1)
close(rpt)

close all
end