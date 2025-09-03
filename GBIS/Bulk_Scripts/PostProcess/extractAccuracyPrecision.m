function [AccuracyFull, PrecisionFull, SSFactors, Info] = extractAccuracyPrecision(InvResFiles, OptVal, burning)
% Ben Ireland, December 2023, Extract accuracy and precision from inversion
% results using synthetic interferograms in GBIS_Bulk

% Load filepaths to inversion results
InvResFiles = dir(InvResFiles); % Can adapt to multiple file sources
Info.NSizes = 0;
for k = 1:length(InvResFiles)

    % Look in same folder as each InvResFiles result for optimal XY values
    OptXYValues = dir([InvResFiles(k).folder,'/OptXY*.mat']);
    Filepath2 = char(strcat(OptXYValues.folder,'/',OptXYValues.name));
    load(Filepath2);
    
    % Load inversion results
    Filepath{k} = char(strcat(InvResFiles(k).folder,'/',InvResFiles(k).name));
    load(Filepath{k});
    
    if invpar.nRuns < 10000
        blankCells = 999; 
    else
        blankCells = 9999;
    end

    Info.nParam = length(invResults.mKeep(:,1)) - length(insar); % Number of model parameters
    Info.ParaNames = invResults.model.parName; % Get parameter names

    Name = inputFile.name; % Make counts of the size

    if contains(Name,'Shallow')
        Info.Size{k} = 'Shallow';
        Info.NSizes(1) = 1;
    elseif contains(Name,'Small')
        Info.Size{k} = 'Small';
        Info.NSizes(2) = 1;
    elseif contains(Name,'Medium')
        Info.Size{k} = 'Medium';
        Info.NSizes(3) = 1;
    elseif contains(Name,'Large')
        Info.Size{k} = 'Large';
        Info.NSizes(4) = 1;
    end

    SS_Factor = geo.SS_Factor;
    SS_FactorF = geo.SS_FactorF;

    % Extract percentiles (individual)
    [Per_25_Results, Per_975_Results, Optimal_Results,~,~] = extractPercentiles(Filepath{k},burning);

    % Extract individual results for each file
    ParameterValues{k} = invResults.mKeep(:,burning:end-blankCells);

    % Extract downsampling parameters
    SSFactors(k,:) = [geo.SS_Factor, geo.SS_FactorF];

    % Create matrix of optimal values (based on source size and heading/incidence angle)
    OptValues = [OptX,OptY,OptVal.Depth,OptVal.Volume];

    % Extract accuracy and precision values
    AccuracyFull{k} = Optimal_Results - OptValues;
    PrecisionFull{k} = Per_975_Results - Per_25_Results;
end
Info.NSizes = sum(Info.NSizes); 
end