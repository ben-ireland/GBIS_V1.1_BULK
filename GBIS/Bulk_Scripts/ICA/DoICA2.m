function [FullReconstructed, ICA_Reconstructed, ICAs_Reconstructed] = DoICA2(TS_File, LastStep, Location, Options)

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

UseReports =0;
if UseReports ==1
    % Extract signal point C
    ReportFilepath = char(strcat(ReportFile.folder,'/',ReportFile.name));

    Report = fopen(ReportFilepath, 'r');
    textLine = fgetl(Report); 

    while ischar(textLine)
        textLine = fgetl(Report);
        if ischar(textLine) & contains(textLine,'Signal point C:')
            numbers = regexp(textLine, '\((\d+)\)', 'tokens');
        end
    end

    fclose(Report);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% show the data using ncdisp(;
filename            = strcat(TS_File.folder,'/',TS_File.name);
DATA                = permute(ncread(filename,'DATA'),[2 1 3])*1000;
Lon_alb             = ncread(filename,'lon');
Lat_alb             = ncread(filename,'lat');
Time                = ncread(filename,'time');
Dates               = datenum('2015-01-10','yyyy-mm-dd') + Time;

FinalStep3 = DATA(:,:,end-1) - DATA(:,:,2);
FinalStep2 = FinalStep3 .* LastStep;

NaNMask = repmat(LastStep,1,1,size(DATA,3));

DATA = DATA .* NaNMask;
%DATA(DATA==0) = NaN;

%% Clip SAR image
Clip = 0;
if Clip ==1
    dimx_space          =   [160:320];
    dimy_space          =   [160:320];
    time_range          =   [1:95];
else
    dimx_space          =   [1:size(DATA,1)];
    dimy_space          =   [1:size(DATA,2)];
    time_range          =   [1:size(DATA,3)];
end

TS                  =   DATA(dimy_space,dimx_space,time_range);
[nx,ny,nifgm]       =   size(TS);   % Number of observations

%% Pixels to plot timeseries
if UseReports ==1
    pix_x               = str2num(cell2mat(numbers{1}));              % pixel location (x)
    pix_y               = str2num(cell2mat(numbers{2}));
    pixel               = permute(TS(pix_y,pix_x,:),[3 1 2]);
end               % pixel location (y) 

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

ncomp = [5 5 5 10 10 10 20 20];
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
    FullReconstructedFinal = FullReconstructed(:,:,end-1) - FullReconstructed(:,:,2);

    % Search for max region of image using sliding window (for timeseries plots) (avoid edges of images)
    if Options.SlidingWindow ==1
        ICAs_LastStep = squeeze(ICA_Reconstructed(end-1,:,:)) - squeeze(ICA_Reconstructed(2,:,:));
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
        ICAs_LastStep = squeeze(ICA_Reconstructed(end-1,:,:)) - squeeze(ICA_Reconstructed(2,:,:));
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

    %MaxICAs = max_mean;
    %MaxICAs = squeeze(max(abs(ICA_Reconstructed(end,:,:))));
    %MaxFullRe = max(reshape(FullReconstructedFinal,[],1));

    %f = figure()
    %subplot(1,2,1)
    %imagesc(sum(img,3,'omitnan'))
    %axis image
    %colorbar
    %subplot(1,2,2)
    %imagesc(FullReconstructedFinal)
    %axis image
    %colorbar
    %saveas(f,'ICATest.png')  
    %hold off

    %MaxFullRe = FullReconstructedFinal(pix_y,pix_x);
    MaxFullReAb = sum(sum(abs(FullReconstructedFinal(bestRows,bestCols)),'omitnan'));
    MaxFullRe = sum(sum(FullReconstructedFinal(bestRows,bestCols),'omitnan'));
    %Full_scores = FullReconstructedFinal(bestRows,bestCols);
    Full_scores = FinalStep3(bestRows,bestCols);
    Full_scores(Full_scores==0) = NaN;
    MaxICA = 0;
    b = 0;
    Closeness = 0;

    % Reconstruct ICs which contain largest magnitude in the estimated signal area, until the magnitude reaches 95% of the original data
    while ~all(Closeness > 0.95)
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
    end
    ClosenessAll(a) = min(Closeness(:));

    if ClosenessAll(a) <= 0.95
        disp('Closeness of >0.95 not reached, trying ICA with more ICs')
        continue
    else
        disp('Closeness of >0.95 reached')
        disp(['Taking ',num2str(b),' ICA Component(s)'])
        break
    end
end

if max(ClosenessAll) <= 0.95
    disp('All ncomp values exhausted - revert to using original deformation data')
    Options.ICA = 0;
    Outcome = '>5% residual signal ';
else
    Options.ICA = 1;
    Outcome = '<5% residual signal';
end


% Calculate RMS of original image vs reconstructed image with ICs 1-b
OverallFig = figure();
FinalStepICA = ICAs_Reconstructed(:, :, end) - ICAs_Reconstructed(:, :, 2);
NumPix = size(DATA,1).*size(DATA,2);
FinalStepRMS = sqrt((sum(FinalStep2.^2,"all"))/NumPix);
ICAs_ReconstructedRMS = sqrt((sum(FinalStepICA.^2,"all"))/NumPix);

subplot(numel(Spatial_pos)+1, 3,1)
imagesc(FullReconstructed(:,:,nifgm)./1000,'AlphaData',Mask); axis image; colorbar; hold on; 
caxis([-max(reshape(DATA(:,:,nifgm),[],1)./1000), max(reshape(DATA(:,:,nifgm),[],1))./1000])
%caxis([-max(FullReconstructed(:))./1000, max(FullReconstructed(:))./1000])
plot(pix_x,pix_y,'ko','MarkerFaceColor','none','MarkerSize',10)
colormap(gcf, flipud(cbrewer2('RdYlBu', 256))); 
set(gca,'YTick',[],'XTick',[])
title('Fully Reconstructed')
yline(0,'--'); 

subplot(numel(Spatial_pos)+1, 3, [2:3]);
plot(Dates, permute(FullReconstructed(pix_y,pix_x,:),[3 1 2])./1000,'ko','LineWidth',1,'MarkerFaceColor','k','MarkerSize',4); hold on; 
xlim([Dates(1) Dates(numel(Dates))])
datetick('x','mm/yy','keeplimits')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Individual ICs %
for k   = 1:length(Spatial_pos)

    if k<length(Spatial_pos)
        subplot(numel(Spatial_pos)+2, 3, Spatial_pos(k)+3);
        FullReconstructed    = permute(reshape(ICA_Reconstructed(:,:,k),nifgm,nx,ny),[2 3 1]);
    
        % Spatial Plot
        imagesc(FullReconstructed(:,:,nifgm)./1000,'AlphaData',Mask); axis image; colorbar; hold on; 
        plot(pix_x,pix_y,'ko','MarkerFaceColor','none','MarkerSize',10)
        %caxis([-max(reshape(DATA(:,:,nifgm),[],1))./1000, max(reshape(DATA(:,:,nifgm),[],1))./1000])
        caxis([-max(FullReconstructed(:))./1000, max(FullReconstructed(:))./1000])

        colormap(gcf, flipud(cbrewer2('RdYlBu', 256)));
        title(sprintf('Independent Comp. %0.0f',k))
        set(gca,'YTick',[],'XTick',[])
        yline(0,'--'); 
    
        % Time Course
        subplot(numel(Spatial_pos)+2, 3, Timecourse_pos(k,:)+3);
        plot(Dates, permute(FullReconstructed(pix_y,pix_x,:),[3 1 2])./1000,'ko','LineWidth',1,'MarkerFaceColor','k','MarkerSize',4); hold on; 
        xlim([Dates(1) Dates(numel(Dates))])
        datetick('x','mm/yy','keeplimits')
    else
        % Plot original signal %
        % Spatial
        subplot(numel(Spatial_pos)+2, 3, Spatial_pos(k)+3);
        imagesc(DATA(:,:,nifgm)./1000,'AlphaData',Mask); axis image; colorbar; hold on; 
        plot(pix_x,pix_y,'ko','MarkerFaceColor','none','MarkerSize',10)
        caxis([-max(reshape(DATA(:,:,nifgm),[],1))./1000, max(reshape(DATA(:,:,nifgm),[],1))./1000])
        %caxis([-max(FullReconstructed(:))./1000, max(FullReconstructed(:))./1000])
        colormap(gcf, flipud(cbrewer2('RdYlBu', 256)));
        title('Original data')
        set(gca,'YTick',[],'XTick',[])
        yline(0,'--'); 

        % Temporal
        % Time Course
        subplot(numel(Spatial_pos)+2, 3, Timecourse_pos(k,:)+3);
        plot(Dates, squeeze(DATA(pix_y,pix_x,:))./1000,'ko','LineWidth',1,'MarkerFaceColor','k','MarkerSize',4); hold on; 
        xlim([Dates(1) Dates(numel(Dates))])
        datetick('x','mm/yy','keeplimits')
        xlabel('Month/Year')
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(ICA_Synth, 'color', 'w');
fontsize(ICA_Synth, 12, 'pixels');
sgtitle(ICA_Synth,[TS_File.name(1:end-3), '| ', num2str(b), ' largest IC(s) taken',' | RMS of original data: ', num2str(round(FinalStepRMS,2)), ' mm',...
    ' | RMS of taken ICs: ', num2str(round(ICAs_ReconstructedRMS,2)), ' mm | ',Outcome],'Interpreter','none')

saveas(OverallFig,[pwd,'/ICA/ICA_',TS_File.name(1:end-3),'_numICs_',num2str(ncomp(a)),'_.png']);
saveas(OverallFig,[pwd,'/ICA/ICA_',TS_File.name(1:end-3),'.png']);

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
colormap jet
caxis([-max(abs(FinalStep2(:)))./1000 max(abs(FinalStep2(:)))./1000])
colorbar
set(gca,'YTick',[],'XTick',[])
title('Original data')
subtitle(' ')

subplot(1,3,2)
h2 = imagesc(FinalStepICA./1000)
axis image
set(h2, 'AlphaData', ~isnan(LastStep2))
colormap jet
colorbar;
caxis([-max(abs(FinalStep2(:)))./1000 max(abs(FinalStep2(:)))./1000])
hold on
plot(pix_x,pix_y,'ko','MarkerFaceColor','none','MarkerSize',10)
set(gca,'YTick',[],'XTick',[])
title('Taken ICs')
Maxidx = sprintf('%d, ', Maxidx);
Maxidx = Maxidx(1:end-2);
subtitle(['ICs ', Maxidx])

subplot(1,3,3)
h3 = imagesc((FinalStep3 - FinalStepICA)./1000)
axis image
set(h3, 'AlphaData',  ~isnan(LastStep2))
colormap jet
caxis([-0.05 0.05])
c = colorbar
c.Label.String = 'LOS Displacement (m)'
set(gca,'YTick',[],'XTick',[])
title(['Residual: ', Outcome])
subtitle(' ')


saveas(CompFig,[pwd,'/ICA/ICA_',TS_File.name(1:end-3),'Comparison_numICs_',num2str(ncomp(a)),'_.png']);
saveas(CompFig,[pwd,'/ICA/ICA_',TS_File.name(1:end-3),'Comparison.png']);
end
