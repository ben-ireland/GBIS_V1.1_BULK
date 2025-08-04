function model = prepareModel(modelInput, invpar, insar, gps)

% Function to prepare model parameters
%
% Usage: model = prepareModel(modelInput, invpar, insar, gps)
% Input Parameters:
%       modelInput: parameters read from input file
%       invpar: inversion parameters
%
% Output Parameters:
%       model: structure containing model settings to be used for inversion
% =========================================================================
% This function is part of the:
% Geodetic Bayesian Inversion Software (GBIS)
% Software for the Bayesian inversion of geodetic data.
% Copyright: Marco Bagnardi, 2018
%
% Email: gbis.software@gmail.com
%
% Reference: 
% Bagnardi M. & Hooper A, (2018). 
% Inversion of surface deformation data for rapid estimates of source 
% parameters and uncertainties: A Bayesian approach. Geochemistry, 
% Geophysics, Geosystems, 19. https://doi.org/10.1029/2018GC007585
%
% The function may include third party software.
% =========================================================================
% Last update: 8 August, 2018

%% Initialize model vectors
mIx = zeros(invpar.nModels+1, 1);
mIx(1) = 1;
model.m = zeros(500,1);
model.step = model.m;
model.lower = model.m;
model.upper = model.m;

%% Assign model parameters from input file
i_mogi=0;
i_yang=0;
i_mctigue=0;
i_sill=0;
i_dike=0;
i_penny=0;
i_fault=0;
i_hing=0;

for i = 1 : invpar.nModels
    index1 = mIx(i);
    keyboard
    switch invpar.model{i}
        case 'MOGI'
            i_mogi=i_mogi+1;
            nParameters = 4;
            if isstruct(modelInput.mogi) % in case no numbers assigned in input file (old format)
                atemp=modelInput.mogi;
                modelInput.mogi=[];
                modelInput.mogi{1}=atemp;
            end
            index2 = index1 + nParameters - 1;
            model.m(index1:index2) = modelInput{i_mogi}.mogi.start;
            model.step(index1:index2) = modelInput{i_mogi}.mogi.step;
            model.lower(index1:index2) = modelInput{i_mogi}.mogi.lower;
            model.upper(index1:index2) = modelInput{i_mogi}.mogi.upper;
            model.gaussPrior(index1:index2) = false(nParameters,1);
            model.parName(index1:index2) = {'MOGI X'; 'MOGI Y'; 'MOGI Depth'; 'MOGI DV'};
        case 'YANG'
            i_yang=i_yang+1;
            nParameters = 8;
            if isstruct(modelInput.yang) % in case no numbers assigned in input file (old format)
                atemp=modelInput.yang;
                modelInput.yang=[];
                modelInput.yang{1}=atemp;
            end
            index2 = index1 + nParameters - 1;
            model.m(index1:index2) = modelInput.yang{i_yang}.start;
            model.step(index1:index2) = modelInput.yang{i_yang}.step;
            model.lower(index1:index2) = modelInput.yang{i_yang}.lower;
            model.upper(index1:index2) = modelInput.yang{i_yang}.upper;
            model.gaussPrior(index1:index2) = false(nParameters,1);
            model.parName(index1:index2) = {'YANG X'; 'YANG Y'; 'YANG Depth'; 'YANG majAx'; 'YANG a/r'; ...
                'YANG strike'; 'YANG Plunge'; 'YANG DP/mu'};
        case 'MCTG'
            i_mctigue=i_mctigue+1;
            nParameters = 5;
            if isstruct(modelInput.mctigue) % in case no numbers assigned in input file (old format)
                atemp=modelInput.mctigue;
                modelInput.mctigue=[];
                modelInput.mctigue{1}=atemp;
            end
            index2 = index1 + nParameters - 1;
            model.m(index1:index2) = modelInput.mctigue{i_mctigue}.start;
            model.step(index1:index2) = modelInput.mctigue{i_mctigue}.step;
            model.lower(index1:index2) = modelInput.mctigue{i_mctigue}.lower;
            model.upper(index1:index2) = modelInput.mctigue{i_mctigue}.upper;
            model.gaussPrior(index1:index2) = false(nParameters,1);
            model.parName(index1:index2) = {'MCTG X'; 'MCTG Y'; 'MCTG Depth'; 'MCTG Radius'; 'MCTG DP/mu'};
        case 'PENN'
            i_penny=i_penny+1;
            nParameters = 5;
            if isstruct(modelInput.penny) % in case no numbers assigned in input file (old format)
                atemp=modelInput.penny;
                modelInput.penny=[];
                modelInput.penny{1}=atemp;
            end
            index2 = index1 + nParameters - 1;
            model.m(index1:index2) = modelInput.penny{i_penny}.start;
            model.step(index1:index2) = modelInput.penny{i_penny}.step;
            model.lower(index1:index2) = modelInput.penny{i_penny}.lower;
            model.upper(index1:index2) = modelInput.penny{i_penny}.upper;
            model.gaussPrior(index1:index2) = false(nParameters,1);
            model.parName(index1:index2) = {'PENN X'; 'PENN Y'; 'PENN Depth'; 'PENN Radius'; 'PENN DP/mu'};
        case 'SILL'
            i_sill=i_sill+1;
            nParameters = 7;
            if isstruct(modelInput.sill) % in case no numbers assigned in input file (old format)
                atemp=modelInput.sill;
                modelInput.sill=[];
                modelInput.sill{1}=atemp;
            end
            nParameters = 7;
            index2 = index1 + nParameters - 1;
            model.m(index1:index2) = modelInput.sill{i_sill}.start;
            model.step(index1:index2) = modelInput.sill{i_sill}.step;
            model.lower(index1:index2) = modelInput.sill{i_sill}.lower;
            model.upper(index1:index2) = modelInput.sill{i_sill}.upper;
            model.gaussPrior(index1:index2) = false(nParameters,1);
            model.parName(index1:index2) = {'SILL Length'; 'SILL Width'; 'SILL Depth'; 'SILL Strike'; 'SILL X'; 'SILL Y'; 'SILL Opening'};
        case 'DIKE'
            i_dike=i_dike+1;
            nParameters = 8;
            if isstruct(modelInput.dike) % in case no numbers assigned in input file (old format)
                atemp=modelInput.dike;
                modelInput.dike=[];
                modelInput.dike{1}=atemp;
            end
            index2 = index1 + nParameters - 1;
            model.m(index1:index2) = modelInput.dike{i_dike}.start;
            model.step(index1:index2) = modelInput.dike{i_dike}.step;
            model.lower(index1:index2) = modelInput.dike{i_dike}.lower;
            model.upper(index1:index2) = modelInput.dike{i_dike}.upper;
            model.gaussPrior(index1:index2) = false(nParameters,1);
            model.parName(index1:index2) = {'DIKE Length'; 'DIKE Width'; 'DIKE Depth'; 'DIKE Dip'; 'DIKE Strike'; 'DIKE X'; 'DIKE Y'; 'DIKE Opening'};
        case 'FAUL'
            nParameters = 9;
            index2 = index1 + nParameters - 1;
            model.m(index1:index2) = modelInput.fault.start;
            model.step(index1:index2) = modelInput.fault.step;
            model.lower(index1:index2) = modelInput.fault.lower;
            model.upper(index1:index2) = modelInput.fault.upper;
            model.gaussPrior(index1:index2) = false(nParameters,1);
            model.parName(index1:index2) = {'FAUL Length'; 'FAUL Width'; 'FAUL Depth'; 'FAUL Dip'; 'FAUL Strike'; 'FAUL X'; 'FAUL Y'; 'FAUL StrSlip'; 'FAUL DipSlip'};

        % Customised sources start here
        case 'HING'
            nParameters = 11;
            index2 = index1 + nParameters - 1;
            model.m(index1:index2) = modelInput.hing.start;
            model.step(index1:index2) = modelInput.hing.step;
            model.lower(index1:index2) = modelInput.hing.lower;
            model.upper(index1:index2) = modelInput.hing.upper;
            model.gaussPrior(index1:index2) = false(nParameters,1);
        case 'SUNC'
            nParameters = 5;
            index2 = index1 + nParameters - 1;
            model.m(index1:index2) = modelInput.SunCrack.start;
            model.step(index1:index2) = modelInput.SunCrack.step;
            model.lower(index1:index2) = modelInput.SunCrack.lower;
            model.upper(index1:index2) = modelInput.SunCrack.upper;
            model.gaussPrior(index1:index2) = false(nParameters,1);
            model.parName(index1:index2) = {'SUNC X'; 'SUNC Y'; 'SUNC Depth'; 'SUNC Radius'; 'SUNC DP/mu'};
        otherwise
            error('Invalid model')
    end
    mIx(i+1) = mIx(i) + nParameters;
end

% Add other parameters to invert for (e.g., InSAR constant offset, ramp,
% etc.)
clear index1
index1 = index2+1;
clear index2

nParameters = 0;
insarParName = {};

for i=1:length(insar)
    
    if insar{i}.constOffset == 'y';
        nParameters = nParameters + 1; % Constant offset
        if i == 1
            insarParName = {'InSAR Const.'};
        else
            insarParName = [insarParName, 'InSAR Const.'];
        end
    end
    
    if insar{i}.rampFlag == 'y'
        nParameters = nParameters + 2;  % Linear ramp
        insarParName = [insarParName, 'InSAR X-ramp', 'InSAR Y-ramp';];
    end
end

index2 = index1 + nParameters; % this also adds hyperparameter at end of each model vector

model.m(index1:index2) = zeros(nParameters+1,1);
model.step(index1:index2) = ones(nParameters+1,1)*1e-3;
model.lower(index1:index2) = ones(nParameters+1,1)*-5e-1;
model.upper(index1:index2) = ones(nParameters+1,1)*5e-1;
if ~isempty(insar)
    model.parName(index1:index2-1) = insarParName;
end

% Clear unused values
model.m = model.m(1:index2);
model.step = model.step(1:index2);
model.lower = model.lower(1:index2);
model.upper = model.upper(1:index2);

model.mIx = mIx;
