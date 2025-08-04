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
% Last update: 16 Jan, 2023

global outputDir  % Set global variables

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
i_sunc=0;
i_sunv=0;
i_cerv=0;
i_cerp=0;
i_cdmn=0;
i_cdmb=0;
i_cdmg=0;
i_cdmi=0;
i_cdmj=0;
i_cdmk=0;
i_cdml=0;
i_cdmo=0;

  for i = 1 : invpar.nModels
    index1 = mIx(i);
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
            model.m(index1:index2) = modelInput.mogi{i_mogi}.start;
            model.step(index1:index2) = modelInput.mogi{i_mogi}.step;
            model.lower(index1:index2) = modelInput.mogi{i_mogi}.lower;
            model.upper(index1:index2) = modelInput.mogi{i_mogi}.upper;
            model.gaussPrior(index1:index2) = false(nParameters,1);
            model.modelName(index1:index2)={['MOGI',num2str(i_mogi)]};
            model.parName(index1:index2) = {'X'; 'Y'; 'Depth'; 'DV'};
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
            model.modelName(index1:index2)={['Yang',num2str(i_yang)]};
            model.parName(index1:index2) = {'X'; 'Y'; 'Depth'; 'majAx'; 'a/r'; ...
                'strike'; 'Plunge'; 'DP/mu'};
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
            model.modelName(index1:index2)={['Mctigue',num2str(i_mctigue)]};
            model.parName(index1:index2) = {'X'; 'Y'; 'Depth'; 'Radius'; 'DP/mu'};
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
            model.modelName(index1:index2)={['Penny',num2str(i_penny)]};
            model.parName(index1:index2) = {'X'; 'Y'; 'Depth'; 'Radius'; 'DP/mu'};
        case 'SILL'
            i_sill=i_sill+1;
            nParameters = 7;
            if isstruct(modelInput.sill) % in case no numbers assigned in input file (old format)
                atemp=modelInput.sill;
                modelInput.sill=[];
                modelInput.sill{1}=atemp;
            end
            index2 = index1 + nParameters - 1;
            model.m(index1:index2) = modelInput.sill{i_sill}.start;
            model.step(index1:index2) = modelInput.sill{i_sill}.step;
            model.lower(index1:index2) = modelInput.sill{i_sill}.lower;
            model.upper(index1:index2) = modelInput.sill{i_sill}.upper;
            model.gaussPrior(index1:index2) = false(nParameters,1);
            model.modelName(index1:index2)={['Sill',num2str(i_fault)]};
            model.parName(index1:index2) = {'Length'; 'Width'; 'Depth'; 'Strike'; 'X'; 'Y'; 'Opening'};
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
            model.modelName(index1:index2)={['Dike',num2str(i_dike)]};
            model.parName(index1:index2) = {'Length'; 'Width'; 'Depth'; 'Dip'; 'Strike'; 'X'; 'Y'; 'Opening'};
        case 'FAUL'
            i_fault=i_fault+1;
            nParameters = 9;
            if isstruct(modelInput.fault) % in case no numbers assigned in input file (old format)
                atemp=modelInput.fault;
                modelInput.fault=[];
                modelInput.fault{1}=atemp;
            end
            index2 = index1 + nParameters - 1;
            model.m(index1:index2) = modelInput.fault{i_fault}.start;
            model.step(index1:index2) = modelInput.fault{i_fault}.step;
            model.lower(index1:index2) = modelInput.fault{i_fault}.lower;
            model.upper(index1:index2) = modelInput.fault{i_fault}.upper;
            model.gaussPrior(index1:index2) = false(nParameters,1);
            model.modelName(index1:index2)={['Fault',num2str(i_fault)]};
            model.parName(index1:index2) = {'Length'; 'Width'; 'Depth'; 'Dip'; 'Strike'; 'X'; 'Y'; 'StrSlip'; 'DipSlip'};
        case 'HING'
            i_hing=i_hing+1;
            nParameters = 11;
            if isstruct(modelInput.hing) % in case no numbers assigned in input file (old format)
                atemp=modelInput.hing;
                modelInput.hing=[];
                modelInput.hing{1}=atemp;
            end
            index2 = index1 + nParameters - 1;
            model.m(index1:index2) = modelInput.hing{i_hing}.start;
            model.step(index1:index2) = modelInput.hing{i_hing}.step;
            model.lower(index1:index2) = modelInput.hing{i_hing}.lower;
            model.upper(index1:index2) = modelInput.hing{i_hing}.upper;
            model.gaussPrior(index1:index2) = false(nParameters,1);
            model.modelName(index1:index2)={['Hinge',num2str(i_hing)]};
            model.parName(index1:index2) = {'X'; 'Y'; 'Length'; 'Width1'; 'Depth1'; 'Phi1'; 'Open1'; 'Width2'; 'Phi2';'Open2'; 'Strike'};
        case 'SUNC'
            i_sunc=i_sunc+1;
            nParameters = 5;
            if isstruct(modelInput.SunCrack) % in case no numbers assigned in input file (old format)
                atemp=modelInput.SunCrack;
                modelInput.SunCrack=[];
                modelInput.SunCrack{1}=atemp;
            end
            index2 = index1 + nParameters - 1;
            model.m(index1:index2) = modelInput.SunCrack{i_sunc}.start;
            model.step(index1:index2) = modelInput.SunCrack{i_sunc}.step;
            model.lower(index1:index2) = modelInput.SunCrack{i_sunc}.lower;
            model.upper(index1:index2) = modelInput.SunCrack{i_sunc}.upper;
            model.gaussPrior(index1:index2) = false(nParameters,1);
            model.modelName(index1:index2)={['SUNC',num2str(i_sunc)]};
            model.parName(index1:index2) = {'SUNC X'; 'SUNC Y'; 'SUNC Depth'; 'SUNC Radius'; 'SUNC DP/mu'};
        case 'SUNV'
            i_sunv=i_sunv+1;
            nParameters = 5;
            if isstruct(modelInput.SunVCrack) % in case no numbers assigned in input file (old format)
                atemp=modelInput.SunVCrack;
                modelInput.SunVCrack=[];
                modelInput.SunVCrack{1}=atemp;
            end
            index2 = index1 + nParameters - 1;
            model.m(index1:index2) = modelInput.SunVCrack{i_sunv}.start;
            model.step(index1:index2) = modelInput.SunVCrack{i_sunv}.step;
            model.lower(index1:index2) = modelInput.SunVCrack{i_sunv}.lower;
            model.upper(index1:index2) = modelInput.SunVCrack{i_sunv}.upper;
            model.gaussPrior(index1:index2) = false(nParameters,1);
            model.modelName(index1:index2)={['SUNV',num2str(i_sunv)]};
            model.parName(index1:index2) = {'SUNV X'; 'SUNV Y'; 'SUNV Depth'; 'SUNV Radius'; 'SUNV DV'};
        case 'CERV'
            i_cerv=i_cerv+1;
            nParameters = 8;
            if isstruct(modelInput.cerv) % in case no numbers assigned in input file (old format)
                atemp=modelInput.cerv;
                modelInput.cerv=[];
                modelInput.cerv{1}=atemp;
            end
            index2 = index1 + nParameters - 1;
            model.m(index1:index2) = modelInput.cerv{i_cerv}.start;
            model.step(index1:index2) = modelInput.cerv{i_cerv}.step;
            model.lower(index1:index2) = modelInput.cerv{i_cerv}.lower;
            model.upper(index1:index2) = modelInput.cerv{i_cerv}.upper;
            model.gaussPrior(index1:index2) = false(nParameters,1);
            model.modelName(index1:index2)={['CERV',num2str(i_cerv)]};
            model.parName(index1:index2) = {'VertD'; 'HorzD'; 'Plunge'; 'Trend'; 'CERV X'; ...
                'CERV Y'; 'CERV Depth'; 'dV'};
        case 'CERP'
            i_cerp=i_cerp+1;
            nParameters = 8;
            if isstruct(modelInput.cerp) % in case no numbers assigned in input file (old format)
                atemp=modelInput.cerp;
                modelInput.cerp=[];
                modelInput.cerp{1}=atemp;
            end
            index2 = index1 + nParameters - 1;
            model.m(index1:index2) = modelInput.cerp{i_cerp}.start;
            model.step(index1:index2) = modelInput.cerp{i_cerp}.step;
            model.lower(index1:index2) = modelInput.cerp{i_cerp}.lower;
            model.upper(index1:index2) = modelInput.cerp{i_cerp}.upper;
            model.gaussPrior(index1:index2) = false(nParameters,1);
            model.modelName(index1:index2)={['CERP',num2str(i_cerp)]};
            model.parName(index1:index2) = {'VertD'; 'HorzD'; 'Plunge'; 'Trend'; 'CERP X'; ...
                'CERP Y'; 'CERP Depth'; 'dP/mu'};
        case 'CDMN'
            i_cdmn=i_cdmn+1;
            nParameters = 10;
            if isstruct(modelInput.cdmn) % in case no numbers assigned in input file (old format)
                atemp=modelInput.cdmn;
                modelInput.cdmn=[];
                modelInput.cdmn{1}=atemp;
            end
            index2 = index1 + nParameters - 1;
            model.m(index1:index2) = modelInput.cdmn{i_cdmn}.start;
            model.step(index1:index2) = modelInput.cdmn{i_cdmn}.step;
            model.lower(index1:index2) = modelInput.cdmn{i_cdmn}.lower;
            model.upper(index1:index2) = modelInput.cdmn{i_cdmn}.upper;
            model.gaussPrior(index1:index2) = false(nParameters,1);
            model.modelName(index1:index2)={['CDMN',num2str(i_cdmn)]};
            model.parName(index1:index2) = {'CDM X'; 'CDM Y'; 'CDM Depth'; 'OmegX'; 'OmegY'; ...
                'OmegZ'; 'LenX'; 'LenY'; 'LenZ'; 'Opening'};
        case 'CDMB'
            i_cdmb=i_cdmb+1;
            nParameters = 5;
            if isstruct(modelInput.cdmb) % in case no numbers assigned in input file (old format)
                atemp=modelInput.cdmb;
                modelInput.cdmb=[];
                modelInput.cdmb{1}=atemp;
            end
            index2 = index1 + nParameters - 1;
            model.m(index1:index2) = modelInput.cdmb{i_cdmb}.start;
            model.step(index1:index2) = modelInput.cdmb{i_cdmb}.step;
            model.lower(index1:index2) = modelInput.cdmb{i_cdmb}.lower;
            model.upper(index1:index2) = modelInput.cdmb{i_cdmb}.upper;
            model.gaussPrior(index1:index2) = false(nParameters,1);
            model.modelName(index1:index2)={['CDMB',num2str(i_cdmb)]};
            model.parName(index1:index2) = {'CDM X'; 'CDM Y'; 'CDM Depth'; 'CDM Radius'; 'CDM dV'};
        case 'CDMG'
            i_cdmg = i_cdmg + 1;
            nParameters = 7;
            if isstruct(modelInput.cdmg)
                atemp = modelInput.cdmg;
                modelInput.cdmg = [];
                modelInput.cdmg{1} = atemp;
            end
            index2 = index1 + nParameters - 1;
            model.m(index1:index2) = modelInput.cdmg{i_cdmg}.start;
            model.step(index1:index2) = modelInput.cdmg{i_cdmg}.step;
            model.lower(index1:index2) = modelInput.cdmg{i_cdmg}.lower;
            model.upper(index1:index2) = modelInput.cdmg{i_cdmg}.upper;
            model.gaussPrior(index1:index2) = false(nParameters, 1);
            model.modelName(index1:index2) = {['CDMG', num2str(i_cdmg)]};
            model.parName(index1:index2) = {'CDM X'; 'CDM Y'; 'CDM Depth'; 'Radius'; 'Trend'; 'Plunge'; 'dV'};
        case 'CDMI'
            i_cdmi = i_cdmi + 1;
            nParameters = 5;
            if isstruct(modelInput.cdmi)
                atemp = modelInput.cdmi;
                modelInput.cdmi = [];
                modelInput.cdmi{1} = atemp;
            end
            index2 = index1 + nParameters - 1;
            model.m(index1:index2) = modelInput.cdmi{i_cdmi}.start;
            model.step(index1:index2) = modelInput.cdmi{i_cdmi}.step;
            model.lower(index1:index2) = modelInput.cdmi{i_cdmi}.lower;
            model.upper(index1:index2) = modelInput.cdmi{i_cdmi}.upper;
            model.gaussPrior(index1:index2) = false(nParameters, 1);
            model.modelName(index1:index2) = {['CDMI', num2str(i_cdmi)]};
            model.parName(index1:index2) = {'CDM X'; 'CDM Y'; 'CDM Depth'; 'Radius'; 'dV'};
        case 'CDMJ'
            i_cdmj = i_cdmj + 1;
            nParameters = 7;
            if isstruct(modelInput.cdmj)
                atemp = modelInput.cdmj;
                modelInput.cdmj = [];
                modelInput.cdmj{1} = atemp;
            end
            index2 = index1 + nParameters - 1;
            model.m(index1:index2) = modelInput.cdmj{i_cdmj}.start;
            model.step(index1:index2) = modelInput.cdmj{i_cdmj}.step;
            model.lower(index1:index2) = modelInput.cdmj{i_cdmj}.lower;
            model.upper(index1:index2) = modelInput.cdmj{i_cdmj}.upper;
            model.gaussPrior(index1:index2) = false(nParameters, 1);
            model.modelName(index1:index2) = {['CDMJ', num2str(i_cdmj)]};
            model.parName(index1:index2) = {'CDM X'; 'CDM Y'; 'CDM Depth'; 'Rx'; 'Ry'; 'Strike'; 'dV'};
        case 'CDMK'
            i_cdmk = i_cdmk + 1;
            nParameters = 7;
            if isstruct(modelInput.cdmk)
                atemp = modelInput.cdmk;
                modelInput.cdmk = [];
                modelInput.cdmk{1} = atemp;
            end
            index2 = index1 + nParameters - 1;
            model.m(index1:index2) = modelInput.cdmk{i_cdmk}.start;
            model.step(index1:index2) = modelInput.cdmk{i_cdmk}.step;
            model.lower(index1:index2) = modelInput.cdmk{i_cdmk}.lower;
            model.upper(index1:index2) = modelInput.cdmk{i_cdmk}.upper;
            model.gaussPrior(index1:index2) = false(nParameters, 1);
            model.modelName(index1:index2) = {['CDMK', num2str(i_cdmk)]};
            model.parName(index1:index2) = {'CDM X'; 'CDM Y'; 'CDM Depth'; 'Length'; 'Width'; 'Strike'; 'dV'};
        case 'CDML'
            i_cdml = i_cdml + 1;
            nParameters = 8;
            if isstruct(modelInput.cdml)
                atemp = modelInput.cdml;
                modelInput.cdml = [];
                modelInput.cdml{1} = atemp;
            end
            index2 = index1 + nParameters - 1;
            model.m(index1:index2) = modelInput.cdml{i_cdml}.start;
            model.step(index1:index2) = modelInput.cdml{i_cdml}.step;
            model.lower(index1:index2) = modelInput.cdml{i_cdml}.lower;
            model.upper(index1:index2) = modelInput.cdml{i_cdml}.upper;
            model.gaussPrior(index1:index2) = false(nParameters, 1);
            model.modelName(index1:index2) = {['CDML', num2str(i_cdml)]};
            model.parName(index1:index2) = {'CDM X'; 'CDM Y'; 'CDM Depth'; 'Z radius'; 'AspRatio'; ...
                'Trend'; 'Plunge'; 'dV'};
        case 'CDMO'
            i_cdmo = i_cdmo + 1;
            nParameters = 8;
            if isstruct(modelInput.cdmo)
                atemp = modelInput.cdmo;
                modelInput.cdmo = [];
                modelInput.cdmo{1} = atemp;
            end
            index2 = index1 + nParameters - 1;
            model.m(index1:index2) = modelInput.cdmo{i_cdmo}.start;
            model.step(index1:index2) = modelInput.cdmo{i_cdmo}.step;
            model.lower(index1:index2) = modelInput.cdmo{i_cdmo}.lower;
            model.upper(index1:index2) = modelInput.cdmo{i_cdmo}.upper;
            model.gaussPrior(index1:index2) = false(nParameters, 1);
            model.modelName(index1:index2) = {['CDMO', num2str(i_cdmo)]};
            model.parName(index1:index2) = {'CDM X'; 'CDM Y'; 'CDM Depth'; 'X/Y radius'; 'AspRatio'; ...
                'Trend'; 'Plunge'; 'dV'};
                
        otherwise
            error('Invalid model')
    end
    mIx(i+1) = mIx(i) + nParameters;
  end

% if strcmpi(restartFlag,'y') % use saved values from previous run
%     oldModel=load([outputDir,'/',saveName],'invResults');
%     model.m(1:index2)=oldModel.invResults.model.m(1:index2);
% end

% Add other parameters to invert for (e.g., InSAR constant offset, ramp,
% etc.)
clear index1
index1 = index2+1;
clear index2

% Define custom bounds for each optional from input file (Added Ben Ireland, July 2025)
nParameters = 0;
insarParName = {};
modelStep = [];
modelLower = [];
modelUpper = [];

for i = 1:length(insar)
    
    if insar{i}.constOffset == 'y'
        nParameters = nParameters + 1;  % Constant offset
        insarParName = [insarParName, 'Constant'];
        modelStep = [modelStep; modelInput.Const.step];
        modelLower = [modelLower; modelInput.Const.lower];
        modelUpper = [modelUpper; modelInput.Const.upper];
    end
    
    if insar{i}.rampFlag == 'y'
        nParameters = nParameters + 2;  % X and Y ramp
        insarParName = [insarParName, 'X-ramp', 'Y-ramp'];
        modelStep = [modelStep; modelInput.Ramp.step; modelInput.Ramp.step];
        modelLower = [modelLower; modelInput.Ramp.lower; modelInput.Ramp.lower];
        modelUpper = [modelUpper; modelInput.Ramp.upper; modelInput.Ramp.upper];
    end
end

index2 = index1 + nParameters;

% Assign values to model structure
model.m(index1:index2)       = zeros(nParameters+1,1);           % +1 for hyperparameter
model.step(index1:index2-1)  = modelStep;                        % exclude hyperparameter
model.lower(index1:index2-1) = modelLower;
model.upper(index1:index2-1) = modelUpper;

% Hyperparameter bounds (optional: keep same or adjust separately)
model.step(index2)  = 1e-3;
model.lower(index2) = -5e-1;
model.upper(index2) =  5e-1;

if ~isempty(insar)
    model.modelName(index1:index2-1) = {'InSAR'};
    model.parName(index1:index2-1)   = insarParName;
end

% Clear unused values
model.m = model.m(1:index2);
model.step = model.step(1:index2);
model.lower = model.lower(1:index2);
model.upper = model.upper(1:index2);

model.mIx = mIx;
