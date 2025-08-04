clear all; close all;
RunName = 'CDMsTest_LastNoOffset';
Files = dir(['/scratch/Ben/GBIS_BULK/Inversion_Results/*',RunName,'*/invert_1*/invert_1*/invert_1*.mat']);

n = 0;
m = 0;
for k = 1:length(Files)
    if endsWith(Files(k).name,'M.mat')
        n = n+1;
        MogiFiles(n) = Files(k);
    else
        m = m+1;
        OtherFiles(m) = Files(k);
    end
    VolcName{k} = extractBetween(Files(k).folder,'Results/',RunName);
end

flat_names = cellfun(@(c) c{1}, VolcName, 'UniformOutput', false);
VolcNames = unique(flat_names);
OtherNames = {OtherFiles.folder};
MogiNames = {MogiFiles.folder};

for k = 1:length(VolcNames)
    
    SubIx = find(contains(OtherNames, VolcNames{k}));
    MogIx = find(contains(MogiNames, VolcNames{k}));
    disp(num2str(k))
    for j = 1:length(SubIx)
        AIC(k,j) = CompareAIC_GBIS(strcat(MogiFiles(MogIx(length(MogIx))).folder,'/',MogiFiles(MogIx(length(MogIx))).name)...
            ,strcat(OtherFiles(SubIx(j)).folder,'/',OtherFiles(SubIx(j)).name));

        AICc(k,j) = CompareAICc_GBIS(strcat(MogiFiles(MogIx(length(MogIx))).folder,'/',MogiFiles(MogIx(length(MogIx))).name)...
            ,strcat(OtherFiles(SubIx(j)).folder,'/',OtherFiles(SubIx(j)).name));

        BIC(k,j) = CompareBIC_GBIS(strcat(MogiFiles(MogIx(length(MogIx))).folder,'/',MogiFiles(MogIx(length(MogIx))).name)...
            ,strcat(OtherFiles(SubIx(j)).folder,'/',OtherFiles(SubIx(j)).name));

        ReducedChiSq(k,j) = CalculateChiSq(strcat(OtherFiles(SubIx(j)).folder,'/',OtherFiles(SubIx(j)).name));

        ModelNames{j} = OtherFiles(SubIx(j)).name(end-4);
    end
    ReducedChiSqMogi(k) = CalculateChiSq(strcat(MogiFiles(MogIx(length(MogIx))).folder,'/',MogiFiles(MogIx(length(MogIx))).name));
end

ReducedChiSq = [ReducedChiSq, ReducedChiSqMogi'];

VolcNamesT = cell2table(VolcNames');
T = array2table(AIC);
T2 = array2table(AICc);
T3 = array2table(BIC);
T4 = array2table(ReducedChiSq);
T = [VolcNamesT T];
T2 = [VolcNamesT T2];
T3 = [VolcNamesT T3];
T4 = [VolcNamesT T4];
T.Properties.VariableNames = ['Volcano',ModelNames];
T2.Properties.VariableNames = ['Volcano',ModelNames];
T3.Properties.VariableNames = ['Volcano',ModelNames];
T4.Properties.VariableNames = ['Volcano',ModelNames,'M'];

writetable(T,[pwd,'/TestFigs/AIC_WRSS2.csv']);
writetable(T2,[pwd,'/TestFigs/AICc_WRSS2.csv']);
writetable(T3,[pwd,'/TestFigs/BIC_WRSS2.csv']);
writetable(T4,[pwd,'/TestFigs/RedChiSq_Last.csv']);