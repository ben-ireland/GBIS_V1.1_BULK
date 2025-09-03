clear all;close all

%Files = dir('/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/*ICA_Buffer_WithLastV520_V6_OldICA/**/invert_1_M*.mat');
Files = dir('/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/*ICA_Buffer_WithLastV520_V6_OldICA_Dabb/**/invert_1_M*.mat');
%Files = dir('/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/*NoICA_Buffer_WithLast_V4Manual/**/invert_1_M*.mat');
%Files = dir('/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/paka_152D_08915_131313NoICA_Buffer_WithLastV4/**/invert_1_M*.mat');
FullRes=0;
RemoveNoICA =0;
if RemoveNoICA ==1
    n=0;
    for k = 1:length(Files)
        if contains(Files(k).folder,'NoICA')
            continue
        else
            n = n+1;
            Files2(n) = Files(k);
        end
    end
    Files = Files2;
end

for k = 1:length(Files)
    disp(num2str(k))

    OutputFilePath = strcat(Files(k).folder,'/',Files(k).name);
    if FullRes==1
        RMS = ExtractFullResRMSOne(OutputFilePath,0);
    else
        RMS = ExtractFullResRMSOne(OutputFilePath,1);
    end
    Name = string(extractAfter(Files(k).folder,'Inversion_Results/'));
    RMS_Data = RMS.LOS;
    RMS_Residual = RMS.RMSE;

    if k ==1
        T = table(Name,RMS_Data,RMS_Residual);
    else
        T2 = table(Name,RMS_Data,RMS_Residual);
        T = vertcat(T,T2);
    end
end

writetable(T,'RMSE_ICA_Buffer_WithLastV520_V6_OldICA_Dabb.csv');