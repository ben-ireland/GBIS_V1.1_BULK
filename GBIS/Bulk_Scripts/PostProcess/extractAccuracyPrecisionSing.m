function [AccuracyFull, PrecisionFull, SSFactors, Info] = extractAccuracyPrecisionSing(InvResFiles, OptVal, burning)
% Ben Ireland, December 2023, Extract accuracy and precision from inversion
% results using synthetic interferograms in GBIS_Bulk

% Save downsampling method info along with this

% Load filepaths to inversion results
InvResFiles = dir(InvResFiles) % Can adapt to multiple file sources

% Look in same folder as each InvResFiles result for optimal XY values
OptXYValues = dir([InvResFiles.folder,'/OptXY*.mat'])
Filepath2 = char(strcat(OptXYValues.folder,'/',OptXYValues.name));
load(Filepath2);

% Load inversion results
Filepath = char(strcat(InvResFiles.folder,'/',InvResFiles.name));
load(Filepath);
Info.Fileapth = Filepath;

if invpar.nRuns < 10000
    blankCells = 999; 
else
    blankCells = 9999;
end
Info.OptXYFile = Filepath2;
Info.InvResFile = Filepath;
Info.nParam = length(invResults.mKeep(:,1)) - length(insar); % Number of model parameters
Info.ParaNames = invResults.model.parName; % Get parameter names
Info.Size = OptVal.Size;
Info.Downsampling = geo.BB;
Info.Quadtree = geo.QT;
Info.Name = inputFile.name; % Make counts of the size

SS_Factor = geo.SS_Factor;
SS_FactorF = geo.SS_FactorF;

% Extract percentiles (individual)
[Per_25_Results, Per_975_Results, Optimal_Results,~,~] = extractPercentiles(Filepath,burning);

% Extract individual results for each file
ParameterValues = invResults.mKeep(:,burning:end-blankCells);

% Extract downsampling parameters
SSFactors = [geo.SS_Factor, geo.SS_FactorF];

% Create matrix of optimal values (based on source size and heading/incidence angle)
% TO DO: CHANGE TO ACCOMODATE THE CORRECT NUMBER OF PARAMS IF RAMP/OFFSET IS ON
OptValues = [OptX,OptY,(OptVal.Depth*1000),OptVal.Volume];

Info.OptValues = OptValues;

% Extract accuracy and precision values
AccuracyFull = Optimal_Results - OptValues;
PrecisionFull = Per_975_Results - Per_25_Results;
end