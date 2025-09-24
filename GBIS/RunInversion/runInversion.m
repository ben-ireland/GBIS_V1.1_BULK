function results = runInversion(geo, gps, insar, invpar, model, modelInput, obs, nObs)

% Function that runs the MCMC Bayesian inversion
%
% Usage: results = runInversion(geo, gps, insar, invpar, model, modelInput, obs, nObs)
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

global outputDir  % Set global variables

%% Set starting model parameters
nu = modelInput.nu; % Poisson's ratio

model.trial = model.m; % First trial using starting parameters

model.range = model.upper - model.lower; % Calculate range of m parameters

% Check that starting model is within bounds
if sum(model.m > model.upper)>0 || sum(model.m < model.lower)>0
    disp('      Parameter#  Lower_Bound  Sart_Model  Upper_Bound')
    ix = find(model.m > model.upper | model.m < model.lower);
    fprintf('%d %f6 %f6 %f6', ix, model.lower(ix), model.m(ix), model.upper(ix))
    error('Starting model is out of bounds')
end

nModel = length(model.m);    % Number of model parameters to invert for
probTarget = 0.5^(1/nModel); % Target probability used in sensitivity test
probSens = zeros(nModel,1);  % Initialise vector for sensitivity test

iKeep = 0; % Initialiase kept iterations counter
iReject = 0;    % Initialise rejected iterations counter
iKeepSave = iKeep;  % Initialise saving schedule for kept iterations
iRejectSave = iReject; % Initialise saving schedule for rejected iterations

mKeep= zeros(nModel,invpar.nSave,'single');   % Initialise matrix of model parameters to keep
PKeep= zeros(1,invpar.nSave,'single');   % Initialise probability vector

POpt = -1e99; % Set initial optimal probability
T = invpar.TSchedule(1); % Set first temperature
iTemp = 0;  % Initialise temperature schedule index (for initial Simulated Annealing)
nTemp = length(invpar.TSchedule); % Number of temperature steps (for initial Simulated Annealing)

%% Start core of inversion

sensitivityTest = 0; % Switch off sensitivity test at first iteration

while iKeep < invpar.nRuns  % While number of iterations is < than number of runs...
    if iKeep/invpar.TRuns == round(iKeep/invpar.TRuns) & iTemp < nTemp % Follow temperature schedule
        iTemp = iTemp + 1;
        T = invpar.TSchedule(iTemp);    % Assign temperature from T schedule
        if iKeep > 0
            model.trial = model.optimal;
        end
        if T ==1                        % Set Hyperparameter when T reaches 1 (Hyperparameter is currently not is use!!!)
            setHyperParameter = 1;
        else
            setHyperParameter = 0;
        end
    end
    
    
    if sum(iKeep == invpar.sensitivitySchedule)>0   % Check if it's time for sensitivity test based on schedule
        sensitivityTest = 1; % Switch on sensitivity test
    end
    
    %% Calculate 3D displacements from model
    
    UTot = zeros(3,nObs);   % Initialise matrix of modeled displacements (3 x number of observation points)
    for i = 1:invpar.nModels % For each source model...
        index1 = model.mIx(i);
        switch invpar.model{i}
            case 'MOGI'
                mFunc{i} = model.trial(index1:index1+3);    % Select source model parameters from all
                U = mogi(mFunc{i},obs,nu);               % Calculate 3D displacements
            case 'MCTG'
                mFunc{i} = model.trial(index1:index1+4);    % Select source model parameters from all
                U = mctigueSource(mFunc{i},obs(1:2,:),nu);        % Calculate 3D displacements
            case 'YANG'
                mFunc{i} = model.trial(index1:index1+7);    % Select source model parameters from all
                U = yangSource(mFunc{i},obs,nu);            % Calculate 3D displacements
            case 'PENN'
                mFunc{i}=model.trial(index1:index1+4);      % Select source model parameters from all
                U = pennySource(mFunc{i},obs,nu);           % Calculate 3D displacements
            case 'SILL'
                mFunc{i}=[model.trial(index1:index1+2); 0; model.trial(index1+3:index1+5); 0; 0; model.trial(index1+6)]; % Select source model parameters from all; Dip set to 0; Slip set to 0;
                U = disloc(mFunc{i},obs(1:2,:),nu); 
            case 'DIKE'
                mFunc{i}=[model.trial(index1:index1+6); 0; 0; model.trial(index1+7)]; % Select source model parameters from all; Slip set to 0;
                U = disloc(mFunc{i},obs(1:2,:),nu); 
            case 'FAUL'
                mFunc{i}=[model.trial(index1:index1+8);0]; % Select source model parameters from all; Opening set to 0;
                U = disloc(mFunc{i},obs(1:2,:),nu); 
            case 'HING'
                mFunc{i}=model.trial(index1:index1+10);     % Select source model parameters from all
                U = hingedDikes(mFunc{i},obs(1:2,:),nu);    % Calculate 3D displacements
            case 'SUNC'
                if iKeep ==1
                    warning('Depth H must be greater than 2*A (radius) to obtain valid results.')
                    warning('Depth H must be greater than 5*A (radius) or possible 2-3% error on the solution.')
                end
                mFunc{i}=model.trial(index1:index1+4);      % Select source model parameters from all
                U = Sun1969Source(mFunc{i},obs,nu);           % Calculate 3D displacements
            case 'SUNV'
                if iKeep ==1
                    warning('Depth H must be greater than 2*A (radius) to obtain valid results.')
                    warning('Depth H must be greater than 5*A (radius) or possible 2-3% error on the solution.')
                end
                mFunc{i}=model.trial(index1:index1+4);      % Select source model parameters from all
                U = Sun1969VolSource(mFunc{i},obs,nu);           % Calculate 3D displacements
            case 'CERV'
                mFunc{i}=model.trial(index1:index1+7);
                U = CervelliYangVolume(mFunc{i},obs,nu);  
            case 'CERP'
                mFunc{i}=model.trial(index1:index1+7);
                U = CervelliYangPressure(mFunc{i},obs,nu);
            case 'CDMN'  
                if iKeep ==1
                    disp('If CDM radius/depth>0.4, the model will not contribute towards the deformation')
                end 
                mFunc{i}=model.trial(index1:index1+9);
                U = PrepCDM(mFunc{i},obs,nu);
            case 'CDMB'  
                if iKeep ==1
                    disp('If CDM radius/depth>0.4, the model will not contribute towards the deformation')
                end  
                mFunc{i}=model.trial(index1:index1+4);
                U = CDM_SymmetricSimple(mFunc{i},obs,nu);
            case 'CDMG'   
                if iKeep ==1
                    disp('If CDM radius/depth>0.4, the model will not contribute towards the deformation')
                end 
                mFunc{i}=model.trial(index1:index1+6);
                U = CDM_Symmetric(mFunc{i},obs,nu);
            case 'CDMI'  
                if iKeep ==1
                    disp('If CDM radius/depth>0.4, the model will not contribute towards the deformation')
                end  
                mFunc{i}=model.trial(index1:index1+4);
                U = CDM_Sill_Symmetric(mFunc{i},obs,nu);
            case 'CDMJ'   
                if iKeep ==1
                    disp('If CDM radius/depth>0.4, the model will not contribute towards the deformation')
                end 
                mFunc{i}=model.trial(index1:index1+6);
                U = CDM_Sill(mFunc{i},obs,nu);       
            case 'CDMK' 
                if iKeep ==1
                    disp('If dyke length/opening/width reaches unrealistic values, the model will not contribute towards the deformation')
                end 
                mFunc{i}=model.trial(index1:index1+6);
                U = CDM_Dyke(mFunc{i},obs,nu);      
            case 'CDML'  
                if iKeep ==1
                    disp('If CDM radius/depth>0.4, the model will not contribute towards the deformation')
                end    
                mFunc{i}=model.trial(index1:index1+7);
                U = CDM_Prolate_Spheroid(mFunc{i},obs,nu);          
            case 'CDMO'  
                if iKeep ==1
                    disp('If CDM radius/depth>0.4, the model will not contribute towards the deformation')
                end    
                mFunc{i}=model.trial(index1:index1+7);
                U = CDM_Oblate_Spheroid(mFunc{i},obs,nu);                                   
        end
        UTot = UTot + U; % Calculate total displacement from sum of displacement from each source
    end
    
    insarParIx = model.mIx(end); % Identify first model parameter not related to source model (e.g., InSAR offset, ramp, etc.)
    
    U = UTot; % Reassign U to Utot for simplicity
    
    %% Convert 3D displacement to LOS displacement and calculate residuals
    resExp = 0; % Initialise (Gm - d) * InvCov * (Gm - d)'
    resRSS = 0;
    FullResInSAR = [];
    nObsInSAR = 0;
    if ~isempty(insar)
        
        ULos = []; % Initialise line-of-sight Gm vector
        
        for j = 1 : length(insar)
            
            UEast = -cosd(insar{j}.dHeading).* sind(insar{j}.dIncidence); % Added
            UNorth = sind(insar{j}.dHeading).* sind(insar{j}.dIncidence); % Added
            UVert = cosd(insar{j}.dIncidence); % Added
            
            ULos{j} = UEast.* U(1,insar{j}.ix) + ...
                UNorth.* U(2,insar{j}.ix) + ...             % Convert to line of sight displacement
                UVert.* U(3,insar{j}.ix);
            
            if insar{j}.constOffset == 'y'
                ULos{j} = ULos{j} + model.trial(insarParIx);  % Add constant offset
                
                insarParIx = insarParIx + 1; % Change model parameter index for next step
            end
            
            if insar{j}.rampFlag == 'y'
                %ULos{j} = ULos{j} + model.trial(insarParIx)*insar{j}.obs(:,1)' + ...
                    %model.trial(insarParIx+1)*insar{j}.obs(:,2)'; % Add linear ramp

                ULos{j} = ULos{j} + model.trial(insarParIx)*insar{j}.obs(1,:) + ...
                    model.trial(insarParIx+1)*insar{j}.obs(2,:); % Add linear ramp
                
                insarParIx = insarParIx + 2; % Change model parameter index for next step if necessary
            end
            
            resInsar{j} = (ULos{j} - insar{j}.dLos); % Calculate (Gm - d), residuals
            resExp = resExp + resInsar{j}* insar{j}.invCov* resInsar{j}'; % (Gm - d) * InvCov * (Gm - d)'
            resRSS = resRSS + sum(resInsar{j}.^2);
            FullResInSAR = [FullResInSAR, resInsar{j}];
            nObsInSAR = nObsInSAR + length(insar{j}.dLos);
            %Added, Ben Ireland, September 2023
            % Weighted RSS of the LOS
            WeightedRSSLOS(j) = insar{j}.dLos* insar{j}.invCov* insar{j}.dLos';
            RMSEInd(j) = sqrt(sum(resInsar{j}.^2)/length(insar{j}.dLos));

        end
    end
    
    
    %% Calculate GPS residuals
    
    if ~isempty(gps)
        rGps = U(1:3,gps.ix) - gps.displacements(1:3,:); % Residual GPS displacement
        resExp = resExp + rGps(:)' * gps.invCov * rGps(:) * gps.weight; % (Gm - d) * InvCov * (Gm - d)'
    end
    
    %% Continue inversion ...
    
    if setHyperParameter == 1
        %hyperPrev = resExp/nObs; % set hyperparameter on first reaching T=1;
        hyperPrev = 1; % set hyperparameter to 1;
        model.trial(end) = log10(hyperPrev);
        setHyperParameter = 0; % Switch setHyperParameter off
    end
    
    if isempty(insar)
        hyperParam = 1;
    else
        hyperParam = 1;
        %hyperParam = 10^model.trial(end);
    end
    
    % !! Currently hyperparameter is set to 1
    P = -resExp/(2*hyperParam); % Probability is exp of P
    
    if iKeep>0
        PRatio = (hyperPrev/hyperParam)^(nObs/2)*exp((P-PPrev)/T);  % Probability ratio
    else
        PRatio=1; % Set to 1 for first iteration (always keep first iteration)
    end
    
    %% Perform sensitivity test if necessary and change step size
    
    if sensitivityTest > 1
        probSens(sensitivityTest-1) = PRatio; % Assign probability to current model parameter
        if sensitivityTest > nModel % Check if sensitivity test has finished
            if iKeepSave > 0
                rejectionRatio = (iReject - iRejectSave)/(iKeep - iKeepSave); % Calculate rejection rate
                probTarget = probTarget * rejectionRatio * 1/0.77; % Adjust target probability to reach 77% rejection rate
                probTarget(probTarget<1e-06) = 1e-06; % Prevent from reaching zero.
            end
            sensitivityTest = 0;    % Swtich off sensitivity test
            probSens(probSens > 1) = 1./probSens(probSens > 1);
            PDiff = probTarget - probSens;
            indexP = PDiff > 0; % Select model parameters for which to adjust model step
            model.step(indexP) = model.step(indexP).*exp(-PDiff(indexP)/probTarget*2);  % assign new model step
            indexP = PDiff < 0; % Select remaining model parameters
            model.step(indexP) = model.step(indexP).*exp(-PDiff(indexP)/(1-probTarget)*2); % assign new model step
            model.step(model.step > model.range) = model.range(model.step > model.range); % Check if step is within range
            iKeepSave = iKeep;
            iRejectSave = iReject;
        end
        
    else
        iKeep = iKeep + 1;
        if PRatio >= rand(1,1)  % If condions are met, keep model trial
            model.m = model.trial; % Substitute m with model trial
            mKeep(:,iKeep) = model.m;   % Keep model trial
            PKeep(:,iKeep) = P;         % P of current model

            % Calculate residual sum of squares (RSS) (weighted and unweighted) and root-mean sqaure
            % error (RMSE) ADDED BEN IRELAND, SEPTEMBER 2023
            model.RSS(iKeep) = resRSS;
            model.weightedRSS(iKeep) = resExp;
            model.RMSEInd{iKeep} = RMSEInd;
            model.WeightedRSSLOS{iKeep} = WeightedRSSLOS;
            model.RMSE(iKeep) = sqrt(sum(FullResInSAR.^2)/nObsInSAR);

            PPrev = P;  % Assign current P to PPrev for next trial
            hyperPrev = hyperParam; % Assign current Hyperparameter for next trial
            
            if -resExp > POpt   % Update current optimal model if likelihood is higher
                model.optimal = model.m;
                model.funcOpt = mFunc;
                POpt = -resExp;

                model.OptWeightedRSSLOS = model.WeightedRSSLOS{iKeep};
                model.OptRSS = model.RSS(iKeep);
                model.OptweightedRSS = model.weightedRSS(iKeep);
                model.OptRMSE = model.RMSE(iKeep);
                model.OptRMSEInd = model.RMSEInd{iKeep};
            end
        else                    % Reject model trial and keep previous model
            iReject = iReject + 1;
            mKeep(:,iKeep) = mKeep(:,iKeep-1);
            PKeep(:,iKeep) = PKeep(:,iKeep-1);
        end
        
        if iKeep/invpar.nSave == round(iKeep/invpar.nSave) % display and save results at regular intervals (1000 or 10000 iterations)
            if iKeep >= 20000           % Increase time step for saving/displaying after 20000 iterations
                invpar.nSave = 10000;
            end
            
            % Print current status of inversion to screen
            disp('=========================================================')
            disp(['Model: ',invpar.model{:}])
            disp([num2str(iKeep),' model trials. Optimal Prob = exp(',num2str(POpt),')'])
            disp(['Hyperparameter=',num2str(hyperParam)])
            disp([num2str(iReject),' models rejected:', num2str((iReject/iKeep)*100),'% of model trials.'])
            
            % allocate space for next blocks to keep
            mKeep(:,iKeep + invpar.nSave) = 0;
            PKeep(:,iKeep + invpar.nSave) = 0;
            
            % Save results to temporary file for insepction during
            % inversion
            save([pwd,'/Inversion_Results/',outputDir,'/temporary.mat'], 'geo', 'mKeep', 'PKeep', 'model', 'gps', 'insar', 'invpar', 'geo', 'modelInput');
            
            % Display current optimal model parameters on screen
            for i=1:length(invpar.model)
                if invpar.model{i} == 'MOGI'
                    fprintf('MOGI center X: %f\n',(model.funcOpt{i}(1,:)));
                    fprintf('MOGI center Y: %f\n',(model.funcOpt{i}(2,:)));
                    fprintf('MOGI depth: %f\n',(model.funcOpt{i}(3,:)));
                    fprintf('MOGI volume change: %f\n',(model.funcOpt{i}(4,:)));
                elseif invpar.model{i} == 'YANG'
                    fprintf('YANG centroid X: %f\n',(model.funcOpt{i}(1,:)));
                    fprintf('YANG centroid Y: %f\n',(model.funcOpt{i}(2,:)));
                    fprintf('YANG centroid depth: %f\n',(model.funcOpt{i}(3,:)));
                    fprintf('YANG major axis: %f\n',(model.funcOpt{i}(4,:)));
                    fprintf('YANG minor axis: %f\n',(model.funcOpt{i}(5,:)));
                    fprintf('YANG majax strike: %f\n',(model.funcOpt{i}(6,:)));
                    fprintf('YANG majax plunge: %f\n',(model.funcOpt{i}(7,:)));
                    fprintf('YANG DP/mu: %f\n',(model.funcOpt{i}(8,:)));
                elseif invpar.model{i} == 'MCTG'
                    fprintf('MCTG center X: %f\n',(model.funcOpt{i}(1,:)));
                    fprintf('MCTG center Y: %f\n',(model.funcOpt{i}(2,:)));
                    fprintf('MCTG center depth: %f\n',(model.funcOpt{i}(3,:)));
                    fprintf('MCTG radius: %f\n',(model.funcOpt{i}(4,:)));
                    fprintf('MCTG DP/mu: %f\n',(model.funcOpt{i}(5,:)));
                elseif invpar.model{i} == 'PENN'
                    fprintf('PENNY center X: %f\n',(model.funcOpt{i}(1,:)));
                    fprintf('PENNY center Y: %f\n',(model.funcOpt{i}(2,:)));
                    fprintf('PENNY center depth: %f\n',(model.funcOpt{i}(3,:)));
                    fprintf('PENNY radius: %f\n',(model.funcOpt{i}(4,:)));
                    fprintf('PENNY DP/mu: %f\n',(model.funcOpt{i}(5,:)));
                elseif invpar.model{i} == 'SILL'
                    fprintf('SILL length: %f\n',(model.funcOpt{i}(1,:)));
                    fprintf('SILL width: %f\n',(model.funcOpt{i}(2,:)));
                    fprintf('SILL depth: %f\n',(model.funcOpt{i}(3,:)));
                    fprintf('SILL strike: %f\n',(model.funcOpt{i}(5,:)));
                    fprintf('SILL edge center X: %f\n',(model.funcOpt{i}(6,:)));
                    fprintf('SILL edge center Y: %f\n',(model.funcOpt{i}(7,:)));
                    fprintf('SILL opening: %f\n',(model.funcOpt{i}(10,:)));
                elseif invpar.model{i} == 'DIKE'
                    fprintf('DIKE length: %f\n',(model.funcOpt{i}(1,:))); %Edited for typo
                    fprintf('DIKE width: %f\n',(model.funcOpt{i}(2,:)));
                    fprintf('DIKE depth: %f\n',(model.funcOpt{i}(3,:)));
                    fprintf('DIKE dip: %f\n',(model.funcOpt{i}(4,:)));
                    fprintf('DIKE strike: %f\n',(model.funcOpt{i}(5,:)));
                    fprintf('DIKE edge center X: %f\n',(model.funcOpt{i}(6,:)));
                    fprintf('DIKE edge center Y: %f\n',(model.funcOpt{i}(7,:)));
                    fprintf('DIKE opening: %f\n',(model.funcOpt{i}(10,:)));
                elseif invpar.model{i} == 'FAUL'
                    fprintf('FAULT length: %f\n',(model.funcOpt{i}(1,:)));
                    fprintf('FAULT width: %f\n',(model.funcOpt{i}(2,:)));
                    fprintf('FAULT depth: %f\n',(model.funcOpt{i}(3,:)));
                    fprintf('FAULT dip: %f\n',(model.funcOpt{i}(4,:)));
                    fprintf('FAULT strike: %f\n',(model.funcOpt{i}(5,:)));
                    fprintf('FAULT edge center X: %f\n',(model.funcOpt{i}(6,:)));
                    fprintf('FAULT edge center Y: %f\n',(model.funcOpt{i}(7,:)));
                    fprintf('FAULT strike-slip component: %f\n',(model.funcOpt{i}(8,:)));
                    fprintf('FAULT dip-slip component: %f\n',(model.funcOpt{i}(9,:)));
                elseif invpar.model{i} == 'HING'
                    fprintf('DIKE1 edge center X: %f\n',(model.funcOpt{i}(1,:)));
                    fprintf('DIKE1 edge center Y: %f\n',(model.funcOpt{i}(2,:)));
                    fprintf('DIKE1 length: %f\n',(model.funcOpt{i}(3,:)));
                    fprintf('DIKE1 width: %f\n',(model.funcOpt{i}(4,:)));
                    fprintf('DIKE1 depth: %f\n',(model.funcOpt{i}(5,:)));
                    fprintf('DIKE1 dip: %f\n',(model.funcOpt{i}(6,:)));
                    fprintf('DIKE1 opening: %f\n',(model.funcOpt{i}(7,:)));
                    fprintf('DIKE2 width: %f\n',(model.funcOpt{i}(8,:)));
                    fprintf('DIKE2 dip: %f\n',(model.funcOpt{i}(9,:)));
                    fprintf('DIKE2 opening: %f\n',(model.funcOpt{i}(10,:)));
                    fprintf('Strike: %f\n',(model.funcOpt{i}(11,:)));
                elseif invpar.model{i} == 'SUNC'
                    fprintf('SUN_Crack center X: %f\n',(model.funcOpt{i}(1,:)));
                    fprintf('SUN_Crack center Y: %f\n',(model.funcOpt{i}(2,:)));
                    fprintf('SUN_Crack center depth: %f\n',(model.funcOpt{i}(3,:)));
                    fprintf('SUN_Crack radius: %f\n',(model.funcOpt{i}(4,:)));
                    fprintf('SUN_Crack DP/mu: %f\n',(model.funcOpt{i}(5,:)));
                elseif invpar.model{i} == 'SUNV'
                    fprintf('SUN_Crack center X: %f\n',(model.funcOpt{i}(1,:)));
                    fprintf('SUN_Crack center Y: %f\n',(model.funcOpt{i}(2,:)));
                    fprintf('SUN_Crack center depth: %f\n',(model.funcOpt{i}(3,:)));
                    fprintf('SUN_Crack radius: %f\n',(model.funcOpt{i}(4,:)));
                    fprintf('SUN_Crack volume change: %f\n',(model.funcOpt{i}(5,:)));
                elseif invpar.model{i} == 'CERV'
                    fprintf('Cervelli Yang Vertical Diameter: %f\n',(model.funcOpt{i}(1,:)));
                    fprintf('Cervelli Yang Horizontal Diameter: %f\n',(model.funcOpt{i}(2,:)));
                    fprintf('Cervelli Yang Plunge: %f\n',(model.funcOpt{i}(3,:)));
                    fprintf('Cervelli Yang Trend: %f\n',(model.funcOpt{i}(4,:)));
                    fprintf('Cervelli Yang X: %f\n',(model.funcOpt{i}(5,:)));
                    fprintf('Cervelli Yang Y: %f\n',(model.funcOpt{i}(6,:)));
                    fprintf('Cervelli Yang Z: %f\n',(model.funcOpt{i}(7,:)));
                    fprintf('Cervelli Yang dV: %f\n',(model.funcOpt{i}(8,:)));
                elseif invpar.model{i} == 'CERP'
                    fprintf('Cervelli Yang Vertical Diameter: %f\n',(model.funcOpt{i}(1,:)));
                    fprintf('Cervelli Yang Horizontal Diameter: %f\n',(model.funcOpt{i}(2,:)));
                    fprintf('Cervelli Yang Plunge: %f\n',(model.funcOpt{i}(3,:)));
                    fprintf('Cervelli Yang Trend: %f\n',(model.funcOpt{i}(4,:)));
                    fprintf('Cervelli Yang X: %f\n',(model.funcOpt{i}(5,:)));
                    fprintf('Cervelli Yang Y: %f\n',(model.funcOpt{i}(6,:)));
                    fprintf('Cervelli Yang Z: %f\n',(model.funcOpt{i}(7,:)));
                    fprintf('Cervelli Yang DP/mu: %f\n',(model.funcOpt{i}(8,:)));
                elseif invpar.model{i} == 'CDMN'
                    fprintf('CDM X location: %f\n',(model.funcOpt{i}(1,:)));
                    fprintf('CDM Y Location: %f\n',(model.funcOpt{i}(2,:)));
                    fprintf('CDM centre depth: %f\n',(model.funcOpt{i}(3,:)));
                    fprintf('CDM Omega X: %f\n',(model.funcOpt{i}(4,:)));
                    fprintf('CDM Omega Y: %f\n',(model.funcOpt{i}(5,:)));
                    fprintf('CDM Omega Z: %f\n',(model.funcOpt{i}(6,:)));
                    fprintf('CDM X axis length: %f\n',(model.funcOpt{i}(7,:)));
                    fprintf('CDM Y axis length: %f\n',(model.funcOpt{i}(8,:)));
                    fprintf('CDM Z axis length: %f\n',(model.funcOpt{i}(9,:)));
                    fprintf('CDM Opening: %f\n',(model.funcOpt{i}(10,:)));
                elseif invpar.model{i} == 'CDMB'
                    fprintf('CDM sphere X location: %f\n',(model.funcOpt{i}(1,:)));
                    fprintf('CDM sphere Y Location: %f\n',(model.funcOpt{i}(2,:)));
                    fprintf('CDM sphere centre depth: %f\n',(model.funcOpt{i}(3,:)));
                    fprintf('CDM sphere radius: %f\n',(model.funcOpt{i}(4,:)));
                    fprintf('CDM sphere dV: %f\n',(model.funcOpt{i}(5,:)));
                elseif invpar.model{i} == 'CDMG'
                    fprintf('CDM sphere X location: %f\n',(model.funcOpt{i}(1,:)));
                    fprintf('CDM sphere Y Location: %f\n',(model.funcOpt{i}(2,:)));
                    fprintf('CDM sphere centre depth: %f\n',(model.funcOpt{i}(3,:)));
                    fprintf('CDM sphere radius: %f\n',(model.funcOpt{i}(4,:)));
                    fprintf('CDM sphere trend: %f\n',(model.funcOpt{i}(5,:)));
                    fprintf('CDM sphere plunge: %f\n',(model.funcOpt{i}(6,:)));
                    fprintf('CDM sphere dV: %f\n',(model.funcOpt{i}(7,:)));
                elseif invpar.model{i} == 'CDMI'
                    fprintf('CDM sill X location: %f\n',(model.funcOpt{i}(1,:)));
                    fprintf('CDM sill Y Location: %f\n',(model.funcOpt{i}(2,:)));
                    fprintf('CDM sill centre depth: %f\n',(model.funcOpt{i}(3,:)));
                    fprintf('CDM sill radius: %f\n',(model.funcOpt{i}(4,:)));
                    fprintf('CDM sphere dV: %f\n',(model.funcOpt{i}(5,:)));
                elseif invpar.model{i} == 'CDMJ'
                    fprintf('CDM sill X location: %f\n',(model.funcOpt{i}(1,:)));
                    fprintf('CDM sill Y Location: %f\n',(model.funcOpt{i}(2,:)));
                    fprintf('CDM sill centre depth: %f\n',(model.funcOpt{i}(3,:)));
                    fprintf('CDM sill X radius: %f\n',(model.funcOpt{i}(4,:)));
                    fprintf('CDM sill Y radius: %f\n',(model.funcOpt{i}(5,:)));
                    fprintf('CDM sill strike: %f\n',(model.funcOpt{i}(6,:)));
                    fprintf('CDM sill dV: %f\n',(model.funcOpt{i}(7,:)));
                elseif invpar.model{i} == 'CDMK'
                    fprintf('CDM dyke X location: %f\n',(model.funcOpt{i}(1,:)));
                    fprintf('CDM dyke Y Location: %f\n',(model.funcOpt{i}(2,:)));
                    fprintf('CDM dyke centre depth: %f\n',(model.funcOpt{i}(3,:)));
                    fprintf('CDM dyke length: %f\n',(model.funcOpt{i}(4,:)));
                    fprintf('CDM dyke width: %f\n',(model.funcOpt{i}(5,:)));
                    fprintf('CDM dyke strike: %f\n',(model.funcOpt{i}(6,:)));
                    fprintf('CDM dyke dV: %f\n',(model.funcOpt{i}(7,:)));
                elseif invpar.model{i} == 'CDML'
                    fprintf('CDM Prolate Spheroid X location: %f\n',(model.funcOpt{i}(1,:)));
                    fprintf('CDM Prolate Spheroid Y Location: %f\n',(model.funcOpt{i}(2,:)));
                    fprintf('CDM Prolate Spheroid centre depth: %f\n',(model.funcOpt{i}(3,:)));
                    fprintf('CDM Prolate Spheroid Z length: %f\n',(model.funcOpt{i}(4,:)));
                    fprintf('CDM Prolate Spheroid Aspect ratio (X/Y = Z*AR): %f\n',(model.funcOpt{i}(5,:)));
                    fprintf('CDM Prolate Spheroid Plunge: %f\n',(model.funcOpt{i}(6,:)));
                    fprintf('CDM Prolate Spheroid Trend: %f\n',(model.funcOpt{i}(7,:)));
                    fprintf('CDM Prolate Spheroid dV: %f\n',(model.funcOpt{i}(8,:)));
                elseif invpar.model{i} == 'CDMO'
                    fprintf('CDM Oblate Spheroid X location: %f\n',(model.funcOpt{i}(1,:)));
                    fprintf('CDM Oblate Spheroid Y Location: %f\n',(model.funcOpt{i}(2,:)));
                    fprintf('CDM Oblate Spheroid centre depth: %f\n',(model.funcOpt{i}(3,:)));
                    fprintf('CDM Oblate Spheroid X length: %f\n',(model.funcOpt{i}(4,:)));
                    fprintf('CDM Oblate Spheroid Aspect ratio (Z = X*AR): %f\n',(model.funcOpt{i}(5,:)));
                    fprintf('CDM Oblate Spheroid Plunge: %f\n',(model.funcOpt{i}(6,:)));
                    fprintf('CDM Oblate Spheroid Trend: %f\n',(model.funcOpt{i}(7,:)));
                    fprintf('CDM Oblate Spheroid dV: %f\n',(model.funcOpt{i}(8,:)));                                                        
                end
            end
        end
    end
    
    
    
    if sensitivityTest > 0  % Perform sensitivity test (no models are kept during this phase!)
        randomStep = zeros(nModel,1);
        randomStep(sensitivityTest) = model.step(sensitivityTest) * sign(randn(1,1))/2; % Assign random step
        model.trial = model.m + randomStep; % New model trial
        % Check that new model trial is withing bounds
        if model.trial(sensitivityTest) > model.upper(sensitivityTest)
            model.trial(sensitivityTest) = model.trial(sensitivityTest) - model.step(sensitivityTest);
        end
        
        hyperParam = hyperPrev;
        sensitivityTest = sensitivityTest + 1; % Move index to that of next parameter until all parameters are done
    else
        randomStep = model.step.*(rand(nModel,1)-0.5)*2;     % Make random step
        model.trial = model.m + randomStep;                 % Assign new model trial to previous + random step
        % Check that new model trial is withing bounds
        model.trial(model.trial > model.upper) = 2 * model.upper(model.trial > model.upper) - ...
            model.trial(model.trial > model.upper);
        
        model.trial(model.trial < model.lower) = 2 * model.lower(model.trial < model.lower) - ...
            model.trial(model.trial < model.lower);
    end
end


%% Clean up and prepare results
mKeep(:, end - invpar.nSave) = []; % Remove unused preallocated memory
PKeep(:, end - invpar.nSave) = []; % Remove unused preallocated memory

results.mKeep = mKeep;
results.PKeep = PKeep;
results.model = model;
results.optimalmodel = model.funcOpt;

