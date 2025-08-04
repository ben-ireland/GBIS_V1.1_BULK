clear all
RunName = 'V6_OldICA_Dabb';
Last = 1;
ICA_Files = dir(['/home/jl20461/GBIS_V1.1_BULK/ICA/*',RunName,'Comparison.mat']);

if Last==0
    Steps = 'NoLast';
elseif Last==1
    Steps = 'WithLast';
end
n=0;
for k = 1:length(ICA_Files)
    if contains(ICA_Files(k).name,Steps)
        n=n+1;
        File = strcat(ICA_Files(k).folder,'/',ICA_Files(k).name);
        load(File)
        RMSBefore(n) = rms(Original_Disp(:));
        RMSAfter(n) = rms(ICA_Reconstructed_Disp(:));
        Outcome{n} = Note;
        VolcName{n} = char(extractBetween(ICA_Files(k).name,'ICA_','_ICA_Buffer'));
        
        if contains(Outcome{n},'Original','IgnoreCase',true)
            RMSAfter(n) = RMSBefore(n);
        end
    end
end

RMS_Reduction = (1-(RMSAfter./RMSBefore)).*100;

T = table(VolcName', RMSBefore', RMSAfter', RMS_Reduction', Outcome', ...
    'VariableNames', {'VolcName', 'RMSBefore', 'RMSAfter', 'RMS_Reduction', 'Outcome'});

writetable(T,['ICA_RMS_Reduction_',RunName,'_',Steps,'.csv']);
