clear all; close all;

Files = dir('/scratch/Ben/GBIS_BULK/Inversion_Results/Longonot_Envisat/**/invert_1_*.mat');
% Files = dir('/scratch/Ben/GBIS_BULK/Inversion_Results/Suswa_S1_EP1/**/invert_1_2_*.mat');
% Files = dir('/scratch/Ben/GBIS_BULK/Inversion_Results/Suswa_S1_EP2/**/invert_1_2_*.mat');
RunName = 'Longonot_Envisat';
Figs =1;
Tab =1;
BIC=0;
rms=1;
Burnin = 5e4;


for k = 1:length(Files)
    if endsWith(Files(k).name,'M.mat')
        MogiIdx = k;
    end
end
MogiFile = strcat(Files(MogiIdx).folder,'/',Files(MogiIdx).name);

FullTable = [];
for k = 1:length(Files)
    OutputFilePath = strcat(Files(k).folder,'/',Files(k).name);
    Name = extractBetween(Files(k).name,'invert_1_','.mat');
    %Name = extractBetween(Files(k).name,'invert_1_2_','.mat');
    Name = Name{1};

    if Figs==1
        [Fig, ~] = PlotDMR_UNW_Wrapped(OutputFilePath,Name);
        [Fig, ~] = PlotDMR_UNW_WrappedDS(OutputFilePath,Name);
    end
    ModelName{k} = Name;

    if Tab==1
        Table = CatalogueSourceParams(OutputFilePath,Burnin);
        FullTable = vertcat([FullTable; Table]);
    end

    if BIC==1
        if k~=MogiIdx
            [DeltaBIC(k), DeltaBICUnw(k), BestModel{k}] = CompareBIC_GBIS(MogiFile,OutputFilePath);
        else
            DeltaBIC(k) = 0;
            DeltaBICUnw(k) = 0;
            BestModel{k} = 'NA';
        end
    end

    if rms==1
        Results = load(OutputFilePath);
        RMS(k) = Results.invResults.model.OptRMSE;
        clear Results
    end
end

if Tab==1
    writetable(FullTable,[pwd,'/',RunName,'_results.csv'])
end

if BIC ==1
    T = table(ModelName',RMS',DeltaBIC',DeltaBICUnw',BestModel');
    T.Properties.VariableNames = ["Model code","RMS (m)","Delta BIC vs. Mogi (Weighted)", "Delta BIC vs. Mogi (Unweighted)", "Best Model (weighted)"];
    writetable(T,[pwd,'/',RunName,'_BIC.csv']);
end

if rms==1
    keyboard
    T = table(ModelName',RMS');
    T.Properties.VariableNames = ["Model code","RMS (m)"];
    writetable(T,[pwd,'/',RunName,'_RMS.csv']);
end