Files = dir('/local-scratch/Ben/GBIS_V1.1_BULK/Deformation_Catalogues/*CDMsNew*.csv');

mergedData = [];
for k = 1:length(Files)
    filename = strcat(Files(k).folder,'/',Files(k).name);
    T = readtable(filename);

    if i == 1
        % First file: initialize merged table
        mergedData = T;
    else
        % Append data
        mergedData = [mergedData; T];
    end
end

writetable(mergedData,[pwd,'/MergedTables/DefCatalogue_CDMsV3.csv']);
