close all;clear all
addpath(genpath([pwd,'/GBIS'])); 

RunName = 'ICA_Buffer_WithLastV520_V6_OldICA_Dabb'; % For inversion results
OrigData = dir('/home/jl20461/GBIS_V1.1_BULK/OriginalData/dabb*WithLast.mat');

for i = 1:length(OrigData)
    disp(num2str(i))
    OriginalData = strcat(OrigData(i).folder,'/',OrigData(i).name);
    % Generate DMR from volcano
    VolcName = extractBefore(OrigData(i).name,'WithLast');

    InvResFile = strcat('/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/',VolcName,RunName,'/invert_1_M/invert_1_M/invert_1_M.mat');
    PlotDMR_UNW_Wrapped(InvResFile,[VolcName,RunName]);
end