clear all; close all;
% Ben Ireland, Sept '25, University of Bristol

% Load GBIS-BULK input data and calculate signal-noise-ratio
Files = dir(['/local-scratch/Ben/GBIS_V1.1_BULK/InputData/*_BB_CF_Avg_Pgon_*Auto_NoLast_.mat']);

rad2m = 0.056./(4*pi);

for k = 1:length(Files)
    Filepath = strcat(Files(k).folder,'/',Files(k).name);
    load(Filepath);
    Vals1 = Phase(CoarseIdxs).*rad2m;
    NoiseFar_Field(k) = std(Vals1,"omitnan");
    Vals = abs(Phase(FineIdxs).*rad2m);
    Signal(k) = max(Vals);
    VolcName{k} = extractBefore(Files(k).name,'_BB_CF');
    SNR(k) = Signal(k)./NoiseFar_Field(k);
end

T = table(VolcName',NoiseFar_Field',Signal',SNR','VariableNames',{'VolcName','Far-field noise (m)','Signal strength (m)','Signal-Noise-Ratio'});
writetable(T,[pwd,'/TestFigs/Noise/EAR_SNRs.csv']);

