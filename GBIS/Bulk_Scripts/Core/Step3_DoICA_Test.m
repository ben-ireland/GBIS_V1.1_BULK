function [Phase] = Step3_DoICA_Test(TS_File, LastStep, Location, Options)

% Ben Ireland, July 2024, University of Bristol - modified from Dr Edna Dualeh, University of Bristol
disp('Applying ICA to the signal')

if ~exist([pwd,'/ICA'],'dir')
    mkdir(pwd,'ICA')
    addpath([pwd,'/ICA'])
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Mask out data from other volcanoes in the image (optional)
if Options.MaskVolcs == 1;
    LastStep2 = LastStep;
    LastStep(~isnan(LastStep)) = 1;
    LastStep(isnan(LastStep)) = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% show the data using ncdisp(;
if endsWith(TS_File.name,'.nc')
    filename            = strcat(TS_File.folder,'/',TS_File.name);
    DATA                = permute(ncread(filename,'DATA'),[2 1 3])*1000;
    Lon_alb             = ncread(filename,'lon');
    Lat_alb             = ncread(filename,'lat');
    Time                = ncread(filename,'time');
    Dates               = datenum('2015-01-10','yyyy-mm-dd') + Time;

    %if Options.IgnoreLastStep ==1
    %    FinalStep3 = DATA(:,:,end-1) - DATA(:,:,2);
    %else
    %    FinalStep3 = DATA(:,:,end);
    %end
    FinalStep3 = DATA(:,:,end);
elseif endsWith(TS_File.name,'.h5')
    filename            = strcat(TS_File.folder,'/',TS_File.name);
    ImDates             = h5read(filename,'/imdates');
    Dates               = datetime(ImDates,'ConvertFrom','yyyymmdd');
    DATA                 = h5read(filename,'/cum');
    DATA                 = DATA./1000; 

    DATA(isnan(DATA)) = 0;
    % if Options.IgnoreLastStep ==1
    %     FinalStep3 = DATA(:,:,end-1) - DATA(:,:,2);
    % else
    %     FinalStep3 = DATA(:,:,end);
    % end
    FinalStep3 = DATA(:,:,end);
end
FinalStep2 = FinalStep3 .* LastStep;

NaNMask = repmat(LastStep,1,1,size(DATA,3));

DATA = DATA .* NaNMask;
%DATA(DATA==0) = NaN;

%% Clip SAR image
if Options.CropTS ==1 || Options.CropImg ==1
    if Options.CropImg ==1
        dimx_space          =   Options.CropImgX;
        dimy_space          =   Options.CropImgY;
    end

    if Options.CropTS ==1
        time_range          =   [Options.CropTS_start:Options.CropTS_end];
    end
else
    dimx_space          =   [1:size(DATA,1)];
    dimy_space          =   [1:size(DATA,2)];
    time_range          =   [1:size(DATA,3)];
end

TS                  =   DATA(dimy_space,dimx_space,time_range);

%if Options.IgnoreLastStep ==1
%    Dates = Dates(time_range(2):time_range(end-1));
%    TS = TS (:,:,time_range(2):time_range(end-1));
%    DATA = DATA(dimy_space,dimx_space,time_range(2):time_range(end-1));
%end

[nx,ny,nifgm]       =   size(TS);   % Number of observations

%% ICA Inputs
ICA_method          = "Whitened";         % Whitened or Direct
nlastEig_space      = 4;                % index of the last (smallest) eigenvalue to be retained (PCA)
ncomp               = nifgm-1;          % Number of independent components to be estimated

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Fast ICA (Explanation)
% Sets up the data so that each row is a interferogram and each column is an pixel timeseries (observation)
% ICA [icasig, A, W] based on reduction of dimension determined by eignvalues used
% Outputs:    icasig  =   Independent components
%             A       =   Corresponding mixing matrix
%             W       =   Separating matrix
% help fastica > to get more information about fastica

mixedsig_sICA           = reshape(TS,nx*ny,nifgm)';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ICA with whitened data

ncomp = Options.ICA_nCompRange;
nlastEig_space = ncomp;
for a = 1:length(ncomp)
    disp(['Run ',num2str(a)])
    disp(['Running ICA with ',num2str(ncomp(a)),' components'])
    if ICA_method == "Whitened";
        %[E, D]         = fastica(mixedsig_sICA,'only','pca');
        [whitesig, WM ,DWM]         = fastica(mixedsig_sICA,'only','white','lastEig',nlastEig_space(a));
        %[whitesig, WM ,DWM]         = fastica(mixedsig_sICA,'only','white'); % Don't do PCA on the signal
        [ica, mixing, unmixing]         = fastica(mixedsig_sICA,'whiteSig',whitesig,'whiteMat', WM,'dewhiteMat', DWM,'numOfIC',ncomp(a));
        %[ica, mixing, unmixing]         = fastica(mixedsig_sICA,'whiteSig',whitesig,'whiteMat', WM,'dewhiteMat', DWM,'numOfIC',ncomp,'g','tanh');
    end

    % Directly ICA
    if ICA_method == "Direct"; 
        %[ica, mixing, unmixing]         = fastica(mixedsig_sICA,'numOfIC',ncomp,'lastEig',nlastEig_space); 
        [ica, mixing, unmixing]         = fastica(mixedsig_sICA,'numOfIC',nlastEig_space); 
        %[ica, mixing, unmixing]         = fastica(mixedsig_sICA,'numOfIC',3,'g','tanh'); 
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% Reconstruct ICA

    for k = 1:size(ica,1)
        ICA_Reconstructed(:,:,k)    = mixing(:,k) * ica(k,:);
    end

    %% Creates mask
    Mask            = TS(:,:,nifgm);
    Mask(Mask~=0)=1;

    %% Visualising reconstructed IC
    % Setup figure
    ICA_Synth       = figure(); clf(); ICA_Synth.Position = [33 81 981 896];
    Spatial_pos     = (1:(size(ICA_Reconstructed,3)+1))*3-2;
    Timecourse_pos  = [(1:(size(ICA_Reconstructed,3)+1))*3-1;(1:(size(ICA_Reconstructed,3)+1))*3]';

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Fully reconstructed signal
    FullReconstructed   = permute(reshape(mixing * ica,nifgm,nx,ny),[2 3 1]);
    if Options.IgnoreLastStep ==1
        FullReconstructedFinal = FullReconstructed(:,:,end-1) - FullReconstructed(:,:,2);
    else
        FullReconstructedFinal = FullReconstructed(:,:,end);
    end

    % Search for max region of image using sliding window (for timeseries plots) (avoid edges of images)
    if Options.SlidingWindow ==1
        ICAs_LastStep = squeeze(ICA_Reconstructed(end,:,:));
        img = reshape(ICAs_LastStep,sqrt(size(ICA_Reconstructed,2)),[],size(ICA_Reconstructed,3)); % Creates n by m by p Matrix where 3rd Dimension has each IC, 1st and 2nd are displacement maps of last timeseries step for each IC
        img(img==0) = NaN;

        bestRows = Location.Limits(1,2):Location.Limits(2,2);
        bestCols = Location.Limits(1,1):Location.Limits(2,1);

        bestBlock = FinalStep3(bestRows,bestCols);
        [~, maxIdx] = max(abs(bestBlock(:)));
        [maxRow, maxCol] = ind2sub(size(bestBlock), maxIdx);
        % Convert local block coordinates to global image coordinates
        pix_y = Location.Limits(1,2) + maxRow - 1;
        pix_x = Location.Limits(1,1) + maxCol - 1;

        % Visualise locations and magnitudes of best blocks for each IC
        imgTest = FullReconstructedFinal;
        imgTest(imgTest==0) = NaN;
        f = figure();
        h = imagesc(imgTest);
        h.AlphaData = ~isnan(imgTest).*0.6;
        hold on
        plot(Location.pgon);
        ylim([0 size(img,1)]);
        xlim([0 size(img,2)]);
        axis equal
        saveas(f,[pwd,'/ICA/ICA_',TS_File.name(1:end-3),'_StrongestComponents_numICs_',num2str(ncomp(a)),'_Slide.png']);
    else
        WindowSize = 8;
        ICAs_LastStep = squeeze(ICA_Reconstructed(end,:,:));
        img = reshape(ICAs_LastStep,sqrt(size(ICA_Reconstructed,2)),[],size(ICA_Reconstructed,3)); % Creates n by m by p Matrix where 3rd Dimension has each IC, 1st and 2nd are displacement maps of last timeseries step for each IC
        img(img==0) = NaN;

        X_range = round(0.2.*size(img,1)) : round(0.8.*size(img,1));
        Y_range = round(0.2.*size(img,2)) : round(0.8.*size(img,2)); % Avoid edges

        %filter = ones(WindowSize, WindowSize);

        % Sliding window approach
        OverallMax = zeros(size(img,3),1);
        NaN_Threshold = 0.95;
        for k = 1:size(img,3)
            maxMeanValue = 0;
            imgTemp = img(:,:,k);
            OutMask = true(size(imgTemp));
            OutMask(X_range,Y_range) = false;
            imgTemp(OutMask) = NaN;

            for i = 1:(size(img,1)-WindowSize+1)
                for j = 1:(size(img,2)-WindowSize+1)
                    block = imgTemp(i:i+WindowSize-1, j:j+WindowSize-1);

                    % Calculate the mean of the absolute values, ignoring NaNs
                    if sum(sum(~isnan(block)))/numel(block) > NaN_Threshold
                        meanValue = abs(mean(block(~isnan(block)), 'all'));
                    else
                        meanValue = 0;
                    end
                    
                    % Update if this block has the largest mean absolute value
                    if meanValue > maxMeanValue
                        maxMeanValue = meanValue;
                        bestBlockRow(k) = i;
                        bestBlockCol(k) = j;
                    end
                end
            end

            OverallMax(k) = maxMeanValue;
            
            if maxMeanValue >= max(OverallMax)

                % Extract the best block
                bestBlock = img(bestBlockRow(k):bestBlockRow(k)+WindowSize-1, bestBlockCol(k):bestBlockCol(k)+WindowSize-1,k);
                bestRows = bestBlockRow(k):bestBlockRow(k)+WindowSize-1;
                bestCols = bestBlockCol(k):bestBlockCol(k)+WindowSize-1;

                % Find the pixel with the largest absolute value within the best block
                [~, maxIdx] = max(abs(bestBlock(:)));
                [maxRow, maxCol] = ind2sub(size(bestBlock), maxIdx);

                % Convert local block coordinates to global image coordinates
                maxPixelRow = bestBlockRow(k) + maxRow - 1;
                maxPixelCol = bestBlockCol(k) + maxCol - 1;
            end
        end
    

        % Visualise locations and magnitudes of best blocks for each IC
        imgTest = FullReconstructedFinal;
        imgTest(imgTest==0) = NaN;
        f = figure();
        h = imagesc(imgTest);
        h.AlphaData = ~isnan(imgTest).*0.6;
        hold on
        scatter(bestBlockCol,bestBlockRow,(OverallMax/max(OverallMax))*250,[0 0 0],'filled');
        ylim([0 size(img,1)]);
        xlim([0 size(img,2)]);
        axis equal
        saveas(f,[pwd,'/ICA/ICA_',TS_File.name(1:end-3),'_StrongestComponents_numICs_',num2str(ncomp(a)),'_.png']);

        pix_y = maxPixelRow;
        pix_x = maxPixelCol;
    end

    % Extract the max overall region (across all ICs) from each IC
    for k = 1:size(img,3)
        %MaxICAs(k) = img(pix_y,pix_x,k); 
        MaxICAsAb(k) = sum(sum(abs(img(bestRows,bestCols,k))),'omitnan'); 
        MaxICAs(k) = sum(sum(img(bestRows,bestCols,k)),'omitnan'); 
    end

    %MaxFullRe = FullReconstructedFinal(pix_y,pix_x);
    MaxFullReAb = sum(sum(abs(FullReconstructedFinal(bestRows,bestCols)),'omitnan'));
    MaxFullRe = sum(sum(FullReconstructedFinal(bestRows,bestCols),'omitnan'));
    %Full_scores = FullReconstructedFinal(bestRows,bestCols);
    Full_scores = FinalStep3(bestRows,bestCols);
    Full_scores(Full_scores==0) = NaN;
    MaxICA = 0;
    b = 0;
    Closeness = 0;
    MaxCloseness = 1 + ((1 - Options.ICA_ClosenessThresh)*2);
    ICA_Test = [];
    % Reconstruct ICs which contain largest magnitude in the estimated signal area, until the magnitude reaches 95% of the original data
    while ~all(Closeness > Options.ICA_ClosenessThresh)
        b = b + 1;
        if sign(MaxFullRe) ==1
            [MaxICA, Maxidx]= maxk(MaxICAs,b);
        elseif sign(MaxFullRe) ==-1
            [MaxICA, Maxidx]= mink(MaxICAs,b);
        else
            disp('Maximum displacement is zero?? Something has gone wrong')
            break
        end
        ICAs_ReconstructMax  = permute(reshape(ICA_Reconstructed(:,:,Maxidx(b)),nifgm,nx,ny),[2 3 1]);
        if b ==1
            ICAs_Reconstructed = ICAs_ReconstructMax;
        elseif b==length(MaxICAs)
            ICAs_Reconstructed = FullReconstructed;
            break
        else 
            ICAs_Reconstructed = ICAs_Reconstructed + ICAs_ReconstructMax;
        end
        ICA_scores = ICAs_Reconstructed(bestRows,bestCols,end-1) - ICAs_Reconstructed(bestRows,bestCols,2);
        ICA_scores(ICA_scores==0) = NaN;
        newMask = ~isnan(Full_scores) & ~isnan(ICA_scores);
        Closeness = ICA_scores(newMask)./Full_scores(newMask);

        ICA_Test(b,:) = [b, min(Closeness(:)),max(Closeness(:)),mean(Closeness(:)),median(Closeness(:)),Options.ICA_ClosenessThresh,MaxCloseness];
    end
    ICA_Tests{a} = ICA_Test;
    ClosenessAll(a) = min(Closeness(:));

    if ClosenessAll(a) <= Options.ICA_ClosenessThresh
        disp(['Closeness of >',num2str(Options.ICA_ClosenessThresh), ' not reached so the signal is weaker than originally, trying ICA with more ICs'])
        continue
%    elseif ClosenessAll(a) >= MaxCloseness
%        disp(['Max Closeness of >',num2str(MaxCloseness), ' exceeded so the signal is stronger than originally, trying ICA with more ICs'])
%        continue
    else
        disp(['Closeness of >',num2str(Options.ICA_ClosenessThresh),' reached'])
        disp(['Taking ',num2str(b),' ICA Component(s)'])
        break
    end
end

if max(ClosenessAll) <= Options.ICA_ClosenessThresh
    disp('All ncomp values exhausted - revert to using original deformation data')
    Options.ICA = 0;
    Outcome = '>1-Thresh% residual signal';
    Note = '1. Revert to Original data - threshold not met';
else
    Options.ICA = 1;
    Outcome = '<1-Thresh% residual signal';
    Note = '1. ICA Data used - threshold met';
end


% Calculate RMS of original image vs reconstructed image with ICs 1-b
OverallFig = figure();

if Options.IgnoreLastStep==0
    FinalStepICA = ICAs_Reconstructed(:, :, end);
else
    FinalStepICA = ICAs_Reconstructed(:,:,end-1) - ICAs_Reconstructed(:,:,2);
end

OrigRMS = rms(FinalStep3(:));
ICARMS = rms(FinalStepICA(:));
% Try taking second last step or last step if RMS is increased by doing ICA and threshold was met
RMS_Diff= OrigRMS-ICARMS;
if contains(Note,'ICA Data used')
    if sign(RMS_Diff)==-1 & Options.IgnoreLastStep ==1
        ICA_Test = ICAs_Reconstructed(:, :, end);
        RMS_Reduction_Test = OrigRMS-rms(ICA_Test(:));
        if sign(RMS_Reduction_Test)==1
            FinalStepICA = ICA_Test;
            RMS_Diff = RMS_Reduction_Test;
            ICARMS = rms(FinalStepICA(:));
            Note = strcat(Note,' 2. Last step of ICAs added back in to reduce ICA rms');
        else
            % Switch and don't use ICA (revert to original data)
            Note = strcat(Note,' 2. rms increased through ICA so revert to original data');
            Options.ICA = 0;
        end
    elseif sign(RMS_Diff)==-1 & Options.IgnoreLastStep ==0
        ICA_Test = ICAs_Reconstructed(:,:,end-1) - ICAs_Reconstructed(:,:,2);
        RMS_Reduction_Test = OrigRMS-rms(ICA_Test(:));
        if sign(RMS_Reduction_Test)==1
            FinalStepICA = ICA_Test;
            RMS_Diff = RMS_Reduction_Test;
            ICARMS = rms(FinalStepICA(:));
            Note = strcat(Note,' 2. Last step of ICAs taken away to reduce ICA rms');
        else
            % Switch and don't use ICA (revert to original data)
            Note = strcat(Note,' 2. rms increased through ICA so revert to original data');
            Options.ICA = 0;
        end
    end
end

FinalStepRMS = OrigRMS;
ICAs_ReconstructedRMS = ICARMS;
RMS_Reduction_ICA = (1-(ICAs_ReconstructedRMS./FinalStepRMS)).*100;

subplot(numel(Spatial_pos)+1, 3,1)
imagesc(FullReconstructed(:,:,nifgm)./1000,'AlphaData',Mask); axis image; hold on; 
%caxis([-max(reshape(DATA(:,:,nifgm),[],1)./1000), max(reshape(DATA(:,:,nifgm),[],1))./1000])
caxis([-0.05 0.05])
%caxis([-max(FullReconstructed(:))./1000, max(FullReconstructed(:))./1000])
plot(pix_x,pix_y,'ko','MarkerFaceColor','none','MarkerSize',2)
colormap(gcf, flipud(cbrewer2('RdBu', 256))); 
set(gca,'YTick',[],'XTick',[])
%title('Fully Reconstructed')
yline(0,'--'); 

subplot(numel(Spatial_pos)+1, 3, [2:3]);
plot(Dates, permute(FullReconstructed(pix_y,pix_x,:),[3 1 2])./1000,'ko','LineWidth',1,'MarkerFaceColor','k','MarkerSize',2); hold on; 
xlim([Dates(1) Dates(numel(Dates))])
set(gca,'XTick',[])
%datetick('x','mm/yy','keeplimits')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Individual ICs %
for k   = 1:length(Spatial_pos)

    if k<length(Spatial_pos)
        subplot(numel(Spatial_pos)+2, 3, Spatial_pos(k)+3);
        FullReconstructed    = permute(reshape(ICA_Reconstructed(:,:,k),nifgm,nx,ny),[2 3 1]);
    
        % Spatial Plot
        imagesc(FullReconstructed(:,:,nifgm)./1000,'AlphaData',Mask); axis image; hold on; 
        plot(pix_x,pix_y,'ko','MarkerFaceColor','none','MarkerSize',5)
        %caxis([-max(reshape(DATA(:,:,nifgm),[],1))./1000, max(reshape(DATA(:,:,nifgm),[],1))./1000])
        %caxis([-max(FullReconstructed(:))./1000, max(FullReconstructed(:))./1000])
        caxis([-0.05 0.05])

        LastStepEachIC(:,:,k) = FullReconstructed(:,:,nifgm);

        colormap(gcf, flipud(cbrewer2('RdBu', 256)));
        %title(sprintf('Independent Comp. %0.0f',k))
        set(gca,'YTick',[],'XTick',[])
        yline(0,'--'); 
    
        % Time Course
        subplot(numel(Spatial_pos)+2, 3, Timecourse_pos(k,:)+3);
        plot(Dates, permute(FullReconstructed(pix_y,pix_x,:),[3 1 2])./1000,'ko','LineWidth',1,'MarkerFaceColor','k','MarkerSize',2); hold on; 
        xlim([Dates(1) Dates(numel(Dates))])
        set(gca,'XTick',[])
        %datetick('x','mm/yy','keeplimits')
    else
        % Plot original signal %
        % Spatial
        subplot(numel(Spatial_pos)+2, 3, Spatial_pos(k)+3);
        imagesc(DATA(:,:,nifgm)./1000,'AlphaData',Mask); axis image; hold on; 
        plot(pix_x,pix_y,'ko','MarkerFaceColor','none','MarkerSize',5)
        %caxis([-max(reshape(DATA(:,:,nifgm),[],1))./1000, max(reshape(DATA(:,:,nifgm),[],1))./1000])
        %caxis([-max(FullReconstructed(:))./1000, max(FullReconstructed(:))./1000])
        caxis([-0.05 0.05])
        colormap(gcf, flipud(cbrewer2('RdBu', 256)));
        %title('Original data')
        set(gca,'YTick',[],'XTick',[])
        yline(0,'--'); 

        % Temporal
        % Time Course
        subplot(numel(Spatial_pos)+2, 3, Timecourse_pos(k,:)+3);
        plot(Dates, squeeze(DATA(pix_y,pix_x,:))./1000,'ko','LineWidth',1,'MarkerFaceColor','k','MarkerSize',2); hold on; 
        xlim([Dates(1) Dates(numel(Dates))])
        datetick('x','mm/yy','keeplimits')
        xlabel('Month/Year')
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(OverallFig, 'color', 'w');
fontsize(OverallFig, 7, 'points');
sgtitle(ICA_Synth,[TS_File.name(1:end-3), '| ', num2str(b), ' largest IC(s) taken',' | RMS of original data: ', num2str(round(FinalStepRMS,2)), ' mm',...
    ' | RMS of taken ICs: ', num2str(round(ICAs_ReconstructedRMS,2)), ' mm | ',Outcome],'Interpreter','none')

saveas(OverallFig,[pwd,'/ICA/ICA_',TS_File.name(1:end-3),'_numICs_',num2str(ncomp(a)),'_.png']);
saveas(OverallFig,[pwd,'/ICA/ICA_',TS_File.name(1:end-3),'.png']);
%saveas(OverallFig,[pwd,'/ICA/ICA_',TS_File.name(1:end-3),'.svg']);
exportgraphics(OverallFig,[pwd,'/ICA/ICA_',TS_File.name(1:end-3),'.pdf'],'Resolution',500)

LastStep4 = LastStep2;
if Options.MaskVolcs ==1
    LastStep2(LastStep2==0) = NaN;
else
    LastStep(LastStep==0) = NaN;
    LastStep2 = LastStep;
end

CompFig = figure()
subplot(1,3,1)
h = imagesc(FinalStep3./1000)
axis image
set(h, 'AlphaData',  ~isnan(LastStep2))
%colormap jet
colormap(gcf, flipud(cbrewer2('RdBu', 256)));
caxis([-max(abs(FinalStep2(:)))./1000 max(abs(FinalStep2(:)))./1000])
colorbar
set(gca,'YTick',[],'XTick',[])
title('Original data')
subtitle(' ')

subplot(1,3,2)
h2 = imagesc(FinalStepICA./1000)
axis image
set(h2, 'AlphaData', ~isnan(LastStep2))
%colormap jet
colormap(gcf, flipud(cbrewer2('RdBu', 256)));
colorbar;
caxis([-max(abs(FinalStep2(:)))./1000 max(abs(FinalStep2(:)))./1000])
hold on
plot(pix_x,pix_y,'ko','MarkerFaceColor','none','MarkerSize',10)
set(gca,'YTick',[],'XTick',[])
title('Taken ICs')
Maxidx = sprintf('%d, ', Maxidx);
Maxidx = Maxidx(1:end-2);
subtitle(['ICs ', Maxidx])

ResidualICA = FinalStep3 - FinalStepICA;
subplot(1,3,3)
h3 = imagesc(ResidualICA./1000)
axis image
set(h3, 'AlphaData',  ~isnan(LastStep2))
%colormap jet
colormap(gcf, flipud(cbrewer2('RdBu', 256)));
caxis([-0.05 0.05])
c = colorbar
c.Label.String = 'LOS Displacement (m)'
set(gca,'YTick',[],'XTick',[])
title(['Residual: ', Outcome])
subtitle(' ')

Original_Disp = FinalStep3;
ICA_Reconstructed_Disp = FinalStepICA;
OrigRMS = rms(FinalStep3);
ICARMS = rms(FinalStepICA);

save([pwd,'/ICA/ICA_',TS_File.name(1:end-3),'_',Options.RunID,'Comparison.mat'],'Original_Disp','LastStepEachIC','ICA_Reconstructed_Disp','ResidualICA','ICA_Tests','Note','FinalStepRMS','ICAs_ReconstructedRMS','RMS_Reduction_ICA');
saveas(CompFig,[pwd,'/ICA/ICA_',TS_File.name(1:end-3),'Comparison_numICs_',num2str(ncomp(a)),'_.png']);
saveas(CompFig,[pwd,'/ICA/ICA_',TS_File.name(1:end-3),'_',Options.RunID,'Comparison.png']);

if Options.ICA ==1
    % Convert ICA results into correct format and mask out NaNs and nearby volcanoes if needed
    LastStepICA = FinalStepICA;
    LastStepICA = LastStepICA./1000;
    Phase = double(((4*pi)*LastStepICA)/Options.WavelengthM);
    Phase = -1*Phase;
    %Phase2 = Phase; % Test
    Phase(LastStep4(:)==0) = 0;
    Phase(isnan(LastStep4(:))) = NaN;
elseif Options.ICA ==0
    % Retain original data if ICA fails
    Phase = [];
end
