function [Phase] = Manual_ICA(TS_File, LastStep, Location, Options, MANUAL_Options)

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

    FinalStep3 = DATA(:,:,end);
elseif endsWith(TS_File.name,'.h5')
    filename            = strcat(TS_File.folder,'/',TS_File.name);
    ImDates             = h5read(filename,'/imdates');
    Dates               = datetime(ImDates,'ConvertFrom','yyyymmdd');
    DATA                = h5read(filename,'/cum');
    DATA                = DATA./1000; 

    DATA(isnan(DATA)) = 0;
    FinalStep3 = DATA(:,:,end-1) - DATA(:,:,2);
end
FinalStep2 = FinalStep3 .* LastStep;

NaNMask = repmat(LastStep,1,1,size(DATA,3));

DATA = DATA .* NaNMask;
%DATA(DATA==0) = NaN;

% Specify timeseries location to look at based on location
pix_x = Location.pix(1);
pix_y = Location.pix(2);

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
[nx,ny,nifgm]       =   size(TS);   % Number of observations

%% ICA Inputs
if MANUAL_Options.ICA_White == 0
    ICA_method          = "Direct";         % Whitened or Direct
elseif MANUAL_Options.ICA_White == 1
    ICA_method          = "Whitened";         % Whitened or Direct
end
%nlastEig_space      = 4;                % index of the last (smallest) eigenvalue to be retained (PCA)
%ncomp               = nifgm-1;          % Number of independent components to be estimated

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

ncomp = MANUAL_Options.ICA_nComp;
nlastEig_space = ncomp;

disp(['Running ICA with ',num2str(ncomp),' components'])
if ICA_method == "Whitened";
    %[E, D]         = fastica(mixedsig_sICA,'only','pca');
    [whitesig, WM ,DWM]         = fastica(mixedsig_sICA,'only','white','lastEig',nlastEig_space);
    %[whitesig, WM ,DWM]         = fastica(mixedsig_sICA,'only','white'); % Don't do PCA on the signal
    [ica, mixing, unmixing]         = fastica(mixedsig_sICA,'whiteSig',whitesig,'whiteMat', WM,'dewhiteMat', DWM,'numOfIC',ncomp);
    %[ica, mixing, unmixing]         = fastica(mixedsig_sICA,'whiteSig',whitesig,'whiteMat', WM,'dewhiteMat', DWM,'numOfIC',ncomp,'g','tanh');
end

% Directly ICA
if ICA_method == "Direct"; 
    [ica, mixing, unmixing]         = fastica(mixedsig_sICA,'numOfIC',ncomp,'lastEig',nlastEig_space); 
    %[ica, mixing, unmixing]         = fastica(mixedsig_sICA,'numOfIC',nlastEig_space); 
    %[ica, mixing, unmixing]         = fastica(mixedsig_sICA,'numOfIC',3,'g','tanh'); 
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Reconstruct ICA
for k = 1:size(ica,1)
    All_ICs(:,:,k)    = mixing(:,k) * ica(k,:);
end

x = 0;
if strcmp(MANUAL_Options.ICA_AllComps,'no')
    for k = 1:size(ica,1)
        if ismember(k,MANUAL_Options.ICA_ChosenComps)
            x = x +1;
            ICA_Reconstructed(:,:,x)    = mixing(:,k) * ica(k,:);
        end
    end
    ICA_ReconstructedFull = sum(ICA_Reconstructed,3);
    ICA_ReconstructedFull = permute(reshape(ICA_ReconstructedFull,nifgm,nx,ny),[2 3 1]);
elseif strcmp(MANUAL_Options.ICA_AllComps,'yes')
    ICA_ReconstructedFull = permute(reshape(mixing * ica,nifgm,nx,ny),[2 3 1]);
end
ICA_ReconstructedFinal = ICA_ReconstructedFull(:,:,end);

% Reshape reconstructed ICs [TS = (x,y,timestep)]
%ICA_Reconstructed = permute(reshape(ICA_Reconstructed,nifgm,nx,ny),[2 3 1]);
%ICA_ReconstructedFinal = ICA_Reconstructed(:,:,end);

%% Creates mask
Mask            = TS(:,:,nifgm);
Mask(Mask~=0)=1;

%% Visualising reconstructed IC
% Setup figure
ICA_Synth       = figure(); clf(); ICA_Synth.Position = [33 81 981 896];
Spatial_pos     = (1:(size(All_ICs,3)+1))*3-2;
Timecourse_pos  = [(1:(size(All_ICs,3)+1))*3-1;(1:(size(All_ICs,3)+1))*3]';

FullReconstructed   = permute(reshape(mixing * ica,nifgm,nx,ny),[2 3 1]);
FullReconstructedFinal = FullReconstructed(:,:,end);

% Calculate RMS of original image vs reconstructed image with ICs 1-b
OverallFig = figure();
FinalStepICA = ICA_ReconstructedFinal;
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
        FullReconstructed    = permute(reshape(All_ICs(:,:,k),nifgm,nx,ny),[2 3 1]);
    
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
sgtitle(ICA_Synth,[TS_File.name(1:end-3), '| RMS of original data: ', num2str(round(FinalStepRMS,2)), ' mm',...
    ' | RMS of taken ICs: ', num2str(round(ICAs_ReconstructedRMS,2)), ' mm'],'Interpreter','none')

saveas(OverallFig,[pwd,'/ICA/ICA_',TS_File.name(1:end-3),'_numICs_',num2str(ncomp),'_.png']);
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
subtitle(['ICs ', num2str(MANUAL_Options.ICA_ChosenComps)])

subplot(1,3,3)
h3 = imagesc((FinalStep3 - FinalStepICA)./1000)
axis image
set(h3, 'AlphaData',  ~isnan(LastStep2))
colormap jet
caxis([-0.05 0.05])
c = colorbar
c.Label.String = 'LOS Displacement (m)'
set(gca,'YTick',[],'XTick',[])
title('Residual')
subtitle(' ')

saveas(CompFig,[pwd,'/ICA/ICA_',TS_File.name(1:end-3),'Comparison_numICs_',num2str(ncomp),'_.png']);
saveas(CompFig,[pwd,'/ICA/ICA_',TS_File.name(1:end-3),'Comparison.png']);

if Options.ICA ==1
    % Convert ICA results into correct format
    LastStepICA = ICA_ReconstructedFinal;
    LastStepICA = LastStepICA./1000;
    Phase = double(((4*pi)*LastStepICA)/Options.WavelengthM);
    Phase = -1*Phase;
elseif Options.ICA ==0
    % Retain original data if ICA fails
    Phase = [];
end
