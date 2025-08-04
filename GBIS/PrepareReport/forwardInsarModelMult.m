function [ULos,ULosT] = forwardInsarModelMult(insar,xy,invpar,invResults,modelInput,geo,Heading,Inc,constOffset,xRamp,yRamp)

% Function to generate forward model for InSAR displacements using optimal
% source parameters
%
% Usage: ULos = forwardInSARModel(insar,xy,invpar,invResults,modelInput,geo,Heading,Inc,constOffset,xRamp,yRamp)
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
%%
nu = modelInput.nu;
xy = [xy(:,2:3)'; zeros(1,length(xy(:,1)))];
UTot = zeros(3,length(xy(1,:)));   % Initialise matrix of modeled displacements (3 x number of observation points)
ULos = [];
for i = 1:invpar.nModels % For each source model...
    index1 = invResults.model.mIx(i);
    switch invpar.model{i}
        case 'MOGI'
            mFunc{i} = invResults.model.optimal(index1:index1+3); % Parameters to invert for.
            U = mogi(mFunc{i},xy,nu);
        case 'MCTG'
            mFunc{i} = invResults.model.optimal(index1:index1+4);
            U = mctigueSource(mFunc{i},xy(1:2,:),nu);
        case 'YANG'
            mFunc{i} = invResults.model.optimal(index1:index1+7);
            U = yangSource(mFunc{i},xy,nu);
        case 'PENN'
            mFunc{i}= invResults.model.optimal(index1:index1+4);
            U = pennySource(mFunc{i},xy,nu);
        case 'SILL'
            mFunc{i}=[invResults.model.optimal(index1:index1+2);0; ...
                invResults.model.optimal(index1+3:index1+5);0;0; ...
                invResults.model.optimal(index1+6)]; 
            U = disloc(mFunc{i},xy(1:2,:),nu); 
        case 'DIKE'
            mFunc{i}=[invResults.model.optimal(index1:index1+6);0;0;...
                invResults.model.optimal(index1+7)]; 
            U = disloc(mFunc{i},xy(1:2,:),nu); 
        case 'FAUL'
            mFunc{i}=[invResults.model.optimal(index1:index1+8);0]; 
            U = disloc(mFunc{i},xy(1:2,:),nu); 
        case 'HING'
            mFunc{i}=invResults.model.optimal(index1:index1+10);
            U = hingedDikes(mFunc{i},xy(1:2,:),nu);
        case 'SUNC'
            mFunc{i}=invResults.model.optimal(index1:index1+4); 
            U = Sun1969Source(mFunc{i},xy(1:2,:),nu); 
        case 'SUNV'
            mFunc{i}=invResults.model.optimal(index1:index1+4); 
            U = Sun1969VolSource(mFunc{i},xy(1:2,:),nu); 
        case 'CERV'
            mFunc{i}=invResults.model.optimal(index1:index1+7);
            U = CervelliYangVolume(mFunc{i},xy,nu);  
        case 'CERP'
            mFunc{i}=invResults.model.optimal(index1:index1+7);
            U = CervelliYangPressure(mFunc{i},xy,nu);  
    end
    UTot = UTot + U; % Calculate total displacement from sum of displacement from each source
    insarParIx = invResults.model.mIx(end); % Identify first model parameter not related to source model (e.g., offset, ramp, etc.)

    UEast = -cosd(Heading).* sind(Inc); % East unit vector
    UNorth = sind(Heading).* sind(Inc); % North unit vector
    UVert = cosd(Inc); % Vertical unit vector

    ULos(i,:,:) = UEast'.* U(1,:) + ...
        UNorth'.* U(2,:) + ... % Convert to line of sight displacement
        UVert'.* U(3,:);

    if insar.constOffset == 'y'
        ULos(i,:,:) = ULos(i,:,:) + invResults.model.optimal(constOffset);  % Add constant offset
    end
    
    if insar.rampFlag == 'y'
        ULos(i,:,:) = ULos(i,:,:) + invResults.model.optimal(xRamp)*xy(1,:) + ...
            invResults.model.optimal(yRamp)*xy(2,:); % Add ramp
    end
end

ULosT = UEast'.* UTot(1,:) + ...
    UNorth'.* UTot(2,:) + ... % Convert to line of sight displacement
    UVert'.* UTot(3,:);

if insar.constOffset == 'y'
    ULosT = ULosT + invResults.model.optimal(constOffset);  % Add constant offset
end

if insar.rampFlag == 'y'
    ULosT = ULosT + invResults.model.optimal(xRamp)*xy(1,:) + ...
        invResults.model.optimal(yRamp)*xy(2,:); % Add ramp
end

end
