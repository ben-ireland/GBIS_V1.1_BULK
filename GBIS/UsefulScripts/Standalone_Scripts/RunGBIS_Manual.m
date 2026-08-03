clear all; close all;
addpath(genpath('/scratch/Ben/GBIS_BULK/Connectivity_Suswa_Longonot'));
addpath(genpath([pwd,'/GBIS']));

%/scratch/Ben/GBIS_BULK/InputData/Longonot_Envi_Dsc_BB_CF_Avg_Pgon_21_5_0.5_Test_.mat

StartDir = pwd;
inputFileName = '/scratch/Ben/GBIS_BULK/Connectivity_Suswa_Longonot/Suswa_S1_EP1.inp';
insarDataCode = [1,2];
gpsDataFlag = 'n';
modelCode = {'M','T','S','V','E','I','J','L','O'}; % Mogi, Sill, Sun 1969, Spheroid, CDM sill, CDM elongated sill, Prolate CDM, Oblate CDM
%modelCode = {'E'};
nRuns = 3e5;
Burnin = 5e4;
skipSimulatedAnnealing = 'n';

for k = 1:length(modelCode)
    OutputFile = GBISrun(inputFileName, insarDataCode, gpsDataFlag, modelCode{k}, nRuns, skipSimulatedAnnealing);
    cd(StartDir);
    OutputFilepath{k} = [pwd,OutputFile];
    generateFinalReport2(OutputFilepath{k},Burnin);
    cd(StartDir);
end

FullTable = [];
for k = 1:length(modelCode)
    disp(num2str(k))
    if k~=1
        [DeltaBIC(k), DeltaBICUnw(k), BestModel{k}] = CompareBIC_GBIS(OutputFilepath{k},OutputFilepath{1});
    else
        DeltaBIC(k) = 0;
        DeltaBICUnw(k) = 0;
        BestModel{k} = 'NA';
    end
    Results = load(OutputFilepath{k});
    RMS(k) = Results.invResults.model.OptRMSE;
    clear Results

    Table = CatalogueSourceParams(OutputFilepath{k},Burnin);
    FullTable = vertcat([FullTable; Table]);
end

T = table(modelCode',RMS',DeltaBIC',DeltaBICUnw',BestModel');
T.Properties.VariableNames = ["Model code","RMS (m)","Delta BIC vs. Mogi (Weighted)", "Delta BIC vs. Mogi (Unweighted)", "Best Model (weighted)"];
writetable(T,[pwd,'/Connectivity_Suswa_Longonot/Suswa_S1_EP1_BIC.csv']);
writetable(FullTable,[pwd,'/Connectivity_Suswa_Longonot/Suswa_S1_EP1_results.csv']);