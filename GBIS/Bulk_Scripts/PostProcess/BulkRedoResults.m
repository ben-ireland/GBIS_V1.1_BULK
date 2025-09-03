clear all; close all;

FullTable = [];
% InvResults
invRes = dir('/local-scratch/Ben/GBIS_V1.1_BULK/Inversion_Results/paka_152D_08915_131313SeedingTestV2/invert_1_*/invert_1_*/invert_1_*.mat');

count = 0;
for k = 1:length(invRes)
    Name = extractBetween(invRes(k).name,'1_','.mat');
    Test = length(Name{1})==1;

    if Test
        count = count+1;
        OutputFilepaths{count} = strcat(invRes(k).folder,'/',invRes(k).name);
    end
end

% Names
VolcNames = {'paka_152D_08915_131313'};
VolcName = {'paka_152D_08915_131313'};

if matches(VolcName{1},VolcNames{1})
    NumFrames = 1;
else
    NumFrames = 2;
end

% Options
load '/local-scratch/Ben/GBIS_V1.1_BULK/Options/2808_SeedingTestV2_Options.mat';

FullTable = Step9_GenerateReportsTableV2(FullTable,OutputFilepaths,NumFrames,VolcNames,VolcName,Options);
[FullTable, filepath] = Step10_CreateCatalogue(FullTable,Options);

disp('Table filepath:')
disp(filepath)