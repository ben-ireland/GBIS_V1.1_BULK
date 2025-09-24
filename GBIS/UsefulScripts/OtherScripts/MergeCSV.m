Files = dir('/local-scratch/Ben/GBIS_V1.1_BULK/Deformation_Catalogues/*All_2stdSpheroids*.csv');

if ~exist([pwd,'/MergedTables'],'dir')
    mkdir(pwd,'MergedTables')
    addpath([pwd,'/MergedTables'])
end

mergedData = [];
for k = 1:length(Files)
    filename = strcat(Files(k).folder,'/',Files(k).name);
    T = readtable(filename);

    mergedData = [mergedData; T];
end

writetable(mergedData,[pwd,'/MergedTables/DefCatalogue_All_2stdSpheroids.csv']);
