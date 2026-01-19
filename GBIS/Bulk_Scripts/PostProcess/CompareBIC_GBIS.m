function [DeltaBIC, DeltaBICRSS, BestModel] = CompareBIC_GBIS(OutputFilepathMogi,OutputFilepathOther)

% Load Mogi results
load(OutputFilepathMogi);
MogiWRSS = invResults.model.OptweightedRSS;
MogiRSS = invResults.model.OptRSS;
MogiRMSE = invResults.model.OptRMSE;
nParaMogi = length(model.parName);

% Load Penny results
load(OutputFilepathOther);
OtherWRSS = invResults.model.OptweightedRSS;
OtherRSS = invResults.model.OptRSS;
OtherRMSE = invResults.model.OptRMSE;
nParaOther = length(model.parName);

ModelName='';
for k = 1:length(invpar.model)
% Verify other model name
    modelTypes = fieldnames(modelInput);
    for i = 1:length(modelTypes);
        if contains(modelTypes{i},invpar.model{k},'IgnoreCase',true)
            ModName = modelTypes{i};
        end

        if matches(modelTypes{i},'mctigue') % Special case for McTigue because of how it is named in GBIS
            if matches('MCTG',invpar.model{k},'IgnoreCase',true)
                ModName = modelTypes{i};
            end
        end
    end
    ModelName = append(ModelName,ModName);
end

% Recalculate WRSS based on diagonal values of invCov only
[~, ~, ResidualMogi] = RecalculateResiduals(OutputFilepathMogi);
[~, ~, ResidualOther] = RecalculateResiduals(OutputFilepathOther);

ResidMogi = [];
ResidOther = [];
NewMogiWRSS = 0;
NewOtherWRSS = 0;
NewMogiRSSTest = 0;

for k = 1:length(insar)
    % Append residuals
    ResidMogi = [ResidMogi ResidualMogi{k}'];
    ResidOther = [ResidOther ResidualOther{k}'];

    % Append weights
    WeightVals = diag(insar{k}.invCov);
    Weights = diag(WeightVals,0);

    % Calculate WRSS for each insar dataset
    NewMogiWRSS = NewMogiWRSS + ResidualMogi{k}' * Weights * ResidualMogi{k};
    NewOtherWRSS = NewOtherWRSS + ResidualOther{k}' * Weights * ResidualOther{k};

    NewMogiRSSTest = NewMogiRSSTest + sum(ResidualMogi{k}.^2);
    NewMogiRMSETest(k) = sqrt((sum(ResidualMogi{k}.^2))./length(ResidualMogi{k}));
end

NewMogiRSS = sum(ResidMogi.^2);
NewMogiRMSE = sqrt((sum(ResidMogi.^2))./nObs);
NewOtherRSS = sum(ResidOther.^2);
NewOtherRMSE = sqrt((sum(ResidOther.^2))./nObs);

OtherWRSS2 = NewOtherWRSS;
OtherRSS = NewOtherRSS;
OtherRMSE = NewOtherRMSE;
MogiWRSS2 = NewMogiWRSS;
MogiRSS = NewMogiRSS;
MogiRMSE = NewMogiRMSE;

% Do BIC
DeltaBIC = nObs * log(OtherWRSS / MogiWRSS) + ((nParaOther - nParaMogi) * log(nObs));
DeltaBICWRSS2 = nObs * log(OtherWRSS2 / MogiWRSS2) + ((nParaOther - nParaMogi) * log(nObs));
DeltaBICRSS = nObs * log(OtherRSS / MogiRSS) + ((nParaOther - nParaMogi) * log(nObs));
DeltaBICRMSE = nObs * log(OtherRMSE / MogiRMSE) + ((nParaOther - nParaMogi) * log(nObs));

if DeltaBIC < 0
    BestModel = 'Mogi';
elseif DeltaBIC > 0
    BestModel = ModelName;
else
    BestModel = 'Mogi';
end