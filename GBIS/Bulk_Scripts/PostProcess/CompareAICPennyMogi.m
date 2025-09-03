function [DeltaAIC, BestModel] = CompareAICPennyMogi(OutputFilepathMogi,OutputFilepathPenny)

% Load Mogi results
load(OutputFilepathMogi);
MogiWRSS = invResults.model.OptweightedRSS;
nParaMogi = length(invResults.mKeep(:,1))-1;

% Load Penny results
load(OutputFilepathPenny);
PennyWRSS = invResults.model.OptweightedRSS;
nParaPenny = length(invResults.mKeep(:,1))-1;

% Do AIC
DeltaAIC = nObs*(log(PennyWRSS/MogiWRSS)) + (2*nParaPenny - 2*nParaMogi);

if DeltaAIC > 0
    BestModel = 'Mogi';
elseif DeltaAIC < 0
    BestModel = 'Penny';
else
    BestModel = 'Mogi';
end
