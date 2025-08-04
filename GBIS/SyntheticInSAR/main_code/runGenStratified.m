% This code is for generate 'wrapped' stratified atmospheric delay

% clear all

SAVEWRAP = 0;
inputRoot = '/Users/jl20461/Documents/BristolPhD/SyntheticInSAR/GACOS/Suswa_Binary/20230201T232858VorTdEbPf/';
outputRoot = '/Users/jl20461/Documents/BristolPhD/SyntheticInSAR/Synthetic_InSAR_image-main-mod/';

if SAVEWRAP == 1
    mkdir([outputRoot, 'set1/wrap/stratified/']);
    mkdir([outputRoot, 'set2/wrap/stratified/']);
end

% areas of volcano
% volcanoList = dir(inputRoot);
% volcanoList(1:2) = [];

% parameters
% totalSamples = 10000; % total sample to generate
imageSize = 500;      % resolution in pixels
incidence=39.5879;
xref  = 36.51;
yref  = -0.98;
dxref = 10;
dyref = dxref;
wavelength = 0.055465;
m2rad = 4.*pi./wavelength;
rad2m = (wavelength./(4.*pi));
zen2los = 1./cos(incidence./180.*pi);
halfcrop = floor(500/2); % as input of Alexnet is 227x227 pixels

gaptime = 1681; % days
count = 0;
addind = 1;
filename1 ='/Users/jl20461/Documents/BristolPhD/SyntheticInSAR/GACOS/Suswa_Binary/20230201T232858VorTdEbPf/20150518';
filename2 = '/Users/jl20461/Documents/BristolPhD/SyntheticInSAR/GACOS/Suswa_Binary/20230201T232858VorTdEbPf/20191223';

[~,~,atmo1] = read_GACOS(filename1);
[~,~,atmo2] = read_GACOS(filename2);

atmo = (atmo2-atmo1).*zen2los*.m2rad;
atmo = imresize(atmo, [imageSize imageSize]);
mask = imerode(atmo~=0,strel('disk',3));
mask = mask(end:-1:1,:);
figure(1)
imagesc(atmo1)
figure(2)
imagesc(atmo2)
figure(3)
imagesc(atmo)

if SAVEWRAP == 1
    atmo = wrapTo2Pi(atmo)-pi;
    atmo = (atmo-min(atmo(:)))/range(atmo(:)).*mask;
    imwrite(atmo, [outputDirWrap, 'S', sprintf('%05d',count + addind), '.png']);
end

k=1; %added

if SAVEWRAP == 1
%         outputDirWrap = [outputRoot, 'set', num2str(2-rem(k,2)),'/wrap/stratified'];
        outputDirWrap = [outputRoot, 'Suswa', '/wrap/stratified/'];
    end
    outputDirUnwrap = [outputRoot, 'Suswa', '/unwrap/stratified/'];
    mkdir(outputDirUnwrap);
    mkdir(outputDirWrap);
%     inputDir = [inputRoot, volcanoList(k).name,'/'];
    inputDir = inputRoot; %Edited
    % get dates
    dateNames = dir([inputDir, '*.ztd']);
    % get stratified atmosphere with 12 days interval
    for n = 1:length(dateNames) %-gaptime
        master = dateNames(1).name(1:end-4);
        slave  = dateNames(2).name(1:end-4); %+gaptime
        
        [~,~,atmo1] = read_GACOS([inputDir,master]);
        [~,~,atmo2] = read_GACOS([inputDir,slave]);
        
        atmo = (atmo2-atmo1).*zen2los.*m2rad;
        atmo = imresize(atmo, [imageSize imageSize]);
        mask = imerode(atmo~=0,strel('disk',3));
%         atmo = atmo(round(size(atmo,1)/2) + (-halfcrop:halfcrop),round(size(atmo,2)/2) + (-halfcrop:halfcrop));
%         mask = mask(round(size(atmo,1)/2) + (-halfcrop:halfcrop),round(size(atmo,2)/2) + (-halfcrop:halfcrop));
        mask = mask(end:-1:1,:);
%         if (~(((sum(mask(:)==0)/numel(mask)) <= 0.1) || ((sum(mask(:)==0)/numel(mask)) >= 0.5))) && ... % && (range(atmo(:))>pi/2)
%                 mask(halfcrop,halfcrop)>0
%             
            save([outputDirUnwrap, 'S', sprintf('%05d',count + addind), '.mat'], 'atmo');
            if SAVEWRAP == 1
                atmo = wrapTo2Pi(atmo)-pi;
                atmo = (atmo-min(atmo(:)))/range(atmo(:)).*mask;
                imwrite(atmo, [outputDirWrap, 'S', sprintf('%05d',count + addind), '.png']);
            end
%             count = count + 1;
%         else
%             break;
%         end
%         if count >= totalSamples
%             break;
%         end
     end
    
% % Automated (bulk)

% for k = 1:length(volcanoList)
%     disp([num2str(k),'/',num2str(length(volcanoList))])
%     % point to target output directorty
%     if SAVEWRAP == 1
%         outputDirWrap = [outputRoot, 'set', num2str(2-rem(k,2)),'/wrap/stratified/'];
%     end
%     outputDirUnwrap = [outputRoot, 'set', num2str(2-rem(k,2)),'/unwrap/stratified/'];
%     mkdir(outputDirUnwrap);
% %     inputDir = [inputRoot, volcanoList(k).name,'/'];
%     inputDir = inputRoot; %Edited
%     % get dates
%     dateNames = dir([inputDir, '*.ztd']);
%     % get stratified atmosphere with 12 days interval
%     for n = 1:length(dateNames)-gaptime
%         master = dateNames(n).name(1:end-4);
%         slave  = dateNames(n+gaptime).name(1:end-4);
%         
%         [~,~,atmo1] = read_GACOS([inputDir,master]);
%         [~,~,atmo2] = read_GACOS([inputDir,slave]);
%         
%         atmo = (atmo2-atmo1).*zen2los.*m2rad;
%         atmo = imresize(atmo, [imageSize imageSize]);
%         mask = imerode(atmo~=0,strel('disk',3));
%         atmo = atmo(round(size(atmo,1)/2) + (-halfcrop:halfcrop),round(size(atmo,2)/2) + (-halfcrop:halfcrop));
%         mask = mask(round(size(atmo,1)/2) + (-halfcrop:halfcrop),round(size(atmo,2)/2) + (-halfcrop:halfcrop));
%         mask = mask(end:-1:1,:);
%         if (~(((sum(mask(:)==0)/numel(mask)) <= 0.1) || ((sum(mask(:)==0)/numel(mask)) >= 0.5))) && ... % && (range(atmo(:))>pi/2)
%                 mask(halfcrop,halfcrop)>0
%             
%             save([outputDirUnwrap, 'S', sprintf('%05d',count + addind), '.mat'], 'atmo');
%             if SAVEWRAP == 1
%                 atmo = wrapTo2Pi(atmo)-pi;
%                 atmo = (atmo-min(atmo(:)))/range(atmo(:)).*mask;
%                 imwrite(atmo, [outputDirWrap, 'S', sprintf('%05d',count + addind), '.png']);
%             end
%             count = count + 1;
%         else
%             break;
%         end
%         if count >= totalSamples
%             break;
%         end
%     end
% end

%% check
% 
% checkDir = 'G:\VolcanicUnrest\Atmosphere\synthesised_patches\set2\wrap\stratified\';
% namefiles = dir([checkDir, '*.png']);
% 
% for k = 1:length(namefiles)
%     img = im2double(imread([checkDir, namefiles(k).name]));
%     if (sum(img(:)==0)/numel(img)) > 0.75
%         delete([checkDir, namefiles(k).name]);
%     end
% end
