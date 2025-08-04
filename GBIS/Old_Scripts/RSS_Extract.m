close all
clear all
Results = dir([pwd,'/Inversion_Results/**/invert_1_*.mat']);

for k = 1:length(Results)
    Filepath = char(strcat(Results(k).folder,'/',Results(k).name));
    load(Filepath)
    wRSS_Opt(k) = invResults.model.OptweightedRSS;
    wRSS_LOS(k) = invResults.model.WeightedRSSLOS;
    wRSS_Reduction(k) = ((invResults.model.WeightedRSSLOS-invResults.model.OptweightedRSS)/invResults.model.WeightedRSSLOS)*100;
end
% Get the footprint of the model and use that as the area to test the wRSS
% over, or just over the mask?
figure()
Sc = scatter(wRSS_LOS,wRSS_Reduction)
saveas(Sc,[pwd,'/','wRSS_Graph.png']);