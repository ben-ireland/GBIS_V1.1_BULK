Files = dir('/local-scratch/Ben/GBIS_Sept26/GBIS_V1.1_BULK/Deformation_Catalogues/*__2014_2024*.csv');
OutDir = '/local-scratch/Ben/GBIS_Sept26/GBIS_V1.1_BULK';
if ~exist([OutDir,'/MergedTables'],'dir')
    mkdir(OutDir,'MergedTables')
    addpath([OutDir,'/MergedTables'])
end

mergedData = [];
for k = 1:length(Files)
    filename = strcat(Files(k).folder,'/',Files(k).name);
    T = readtable(filename);

    mergedData = [mergedData; T];
end

writetable(mergedData,[OutDir,'/MergedTables/LiCSVolc_2014_2024.csv']);
