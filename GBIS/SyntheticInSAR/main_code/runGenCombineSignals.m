clear all

rootDir = '/Users/jl20461/Documents/BristolPhD/SyntheticInSAR/Synthetic_InSAR_image-main-mod/';

% % parameters
% samplesPerClass = 1;
% 
% % run for each set
% for setnum = 1
%     % input directories
    patchDirWrap = [rootDir, 'Suswa','/wrap/'];
    patchDirUnwrap = [rootDir, 'Suswa','/unwrap/'];
    deformList    = dir([patchDirUnwrap,'deform/*.mat']);
    turbulentList = dir([patchDirUnwrap,'turbulent/*.mat']);
    stratifiedList = dir([patchDirUnwrap,'stratified/*.mat']);
%     % get shuffled index for combination
%     indDeform = randperm(length(deformList),samplesPerClass);
%     indTurbulent = randperm(length(turbulentList),samplesPerClass);
%     indStratified = randperm(length(stratifiedList),samplesPerClass);
%     % output directorie
    outputDirWrap = [rootDir, 'Suswa', '/wrap/','combine/'];
    outputDirUnwrap = [rootDir, 'Suswa', '/unwrap/','combine/'];
    mkdir(outputDirWrap);
    mkdir(outputDirUnwrap);
%     % marging process
%     for k = 1:samplesPerClass
        % get deformation
        load([patchDirUnwrap, 'deform/', deformList(1).name]);
        load([patchDirUnwrap, 'turbulent/', turbulentList(1).name]);
        load([patchDirUnwrap, 'stratified/', stratifiedList(1).name]);
%         load([patchDirUnwrap, 'deform/', deformList(indDeform(k)).name(1:end-3),'mat']);
%         load([patchDirUnwrap, 'turbulent/', turbulentList(indTurbulent(k)).name(1:end-3),'mat']);
%         load([patchDirUnwrap, 'stratified/', stratifiedList(indStratified(k)).name(1:end-3),'mat']);
%         if range(los_grid(:))<=15
%             los_grid = los_grid*18/range(los_grid(:));
%             save([patchDirUnwrap, 'deform/', deformList(indDeform(k)).name(1:end-3),'mat'],'los_grid');
%         elseif range(los_grid(:))>=50
% los_grid = los_grid*40/range(los_grid(:));
%             save([patchDirUnwrap, 'deform/', deformList(indDeform(k)).name(1:end-3),'mat'],'los_grid');
%         end

wavelength = 0.055465;
m2rad = 4.*pi./wavelength;
rad2m = (wavelength./(4.*pi));

        insarImg = los_grid + (rad2m.*curTur) + (atmo/100);
%         insarImg = los_grid + curTur; %added
        mask = imerode(atmo~=0,strel('disk',3));
        insarWrap = (wrapTo2Pi(insarImg)-pi);
       
        
%         insarWrap = (insarWrap-min(insarWrap(:)))/range(insarWrap(:)).*mask;
        insarWrap = (insarWrap-min(insarWrap(:)))/range(insarWrap(:)); %added
        imwrite(insarWrap, [outputDirWrap, 'Combine_','_all_','.png']); %added
%         imwrite(insarWrap, [outputDirWrap, outputName, '.png']);
subplot(2,2,1)
imagesc(los_grid)
title 'LOS Grid'
colorbar
subplot(2,2,2)
imagesc(rad2m.*curTur)
title 'Turbulent'
colorbar
subplot(2,2,3)
imagesc(atmo/100)
title 'Stratified'
colorbar
subplot(2,2,4)
imagesc(insarImg)
title 'Combined'
colorbar



