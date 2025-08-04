clear all; close all;

% Ben Ireland, May 2025, Compare number of downsampled datapoints between coarse and fine
Files = dir('/home/jl20461/GBIS_V1.1_BULK/nObs/*ICA_Buffer_WithLastV520_V2*.mat');
nowTime = now;
k = 0;
for n = 1:length(Files)
    if (nowTime - Files(n).datenum) * 24 <= 2% Files modified in the last X hours
        k = k+1;
        load(strcat(Files(n).folder,'/',Files(n).name));
        Filenames{k} = Files(n).name;
        nObsFine(k) = nObs_SS_Fine;
        nObsCoarse(k) = nObs_SS_Coarse;
        nObsRaw(k) = nObs_Raw;
        DS_Tests{k} = DS_Stats;
    end
end

nObsDS = nObsFine + nObsCoarse;