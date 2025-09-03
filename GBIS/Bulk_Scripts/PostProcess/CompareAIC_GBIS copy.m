function [DeltaAIC, BestModel] = CompareAIC_GBIS(OutputFilepathMogi,OutputFilepathOther)

% Load Mogi results
load(OutputFilepathMogi);
MogiWRSS = invResults.model.OptweightedRSS;
nParaMogi = length(model.parName);

% Load Penny results
load(OutputFilepathOther);
OtherWRSS = invResults.model.OptweightedRSS;
nParaOther = length(model.parName);

ModelName='';
for k = 1:length(invpar.model)
% Verify other model name
    modelTypes = fieldnames(modelInput);
    for i = 1:length(modelTypes);
        if contains(modelTypes{i},invpar.model{k},'IgnoreCase',true)
            ModName = modelTypes{i};
        end
    end
    ModelName = append(ModelName,ModName);
end

% Do AIC
DeltaAIC = nObs*(log(OtherWRSS/MogiWRSS)) + (2*nParaOther - 2*nParaMogi);

if DeltaAIC > 0
    BestModel = 'Mogi';
elseif DeltaAIC < 0
    BestModel = ModelName;
else
    BestModel = 'Mogi';
end