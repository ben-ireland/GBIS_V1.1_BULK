function [FullReconstructed, ICA_Reconstructed, ICAs_Reconstructed] = DoICA(TS_File, LastStep, Options)

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

FinalStep2 = DATA(:,:,end-1) - DATA(:,:,2);
FinalStep2 = FinalStep2 .* LastStep;

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
nlastEig_space      = 8;                % index of the last (smallest) eigenvalue to be retained (PCA)
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
if ICA_method == "Whitened";
    [whitesig, WM ,DWM]         = fastica(mixedsig_sICA,'only','white','lastEig',nlastEig_space);
    [ica, mixing, unmixing]         = fastica(mixedsig_sICA,'whiteSig',whitesig,'whiteMat', WM,'dewhiteMat', DWM,'numOfIC',ncomp);
end

% Directly ICA
if ICA_method == "Direct"; 
    [ica, mixing, unmixing]         = fastica(mixedsig_sICA,'numOfIC',ncomp,'lastEig',nlastEig_space); 
    %[ica, mixing, unmixing]         = fastica(mixedsig_sICA,'numOfIC',8); 
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
WindowSize = 8;
h = fspecial('average',WindowSize);
img = reshape(squeeze(ICA_Reconstructed(end,:,:)),sqrt(size(ICA_Reconstructed,2)),[],size(ICA_Reconstructed,3)); 
img(img==0) = NaN;

X_range = round(0.2.*size(img,1)) : round(0.8.*size(img,1));
Y_range = round(0.2.*size(img,2)) : round(0.8.*size(img,2)); % Avoid edges

%filter = ones(WindowSize, WindowSize);
OverallMax = 0;

for k = 1:size(img,3)
    %block_sum = imfilter(img(:,:,k), filter, "replicate");
    block_sum = nanconv(img(:,:,k),h,'edge');


    % Normalize by the number of elements in each block (e.g. 4x4 = 16)
    block_mean = block_sum / WindowSize^2;
    OutMask = true(size(img(:,:,k)));
    OutMask(X_range,Y_range) = false;
    block_mean(OutMask) = NaN;

    f = figure();
    imagesc(block_mean);
    saveas(f,[pwd,'/ICA/Filtered_',TS_File.name(1:end-3),'.png']);

    % Find the maximum mean value and the maximum position within this block
    [max_mean(k), linear_idx] = max(abs(block_mean(:)));
    [row, col] = ind2sub(size(block_mean), linear_idx);
    %row = round(row + WindowSize/2);
    %col = round(col + WindowSize/2);

    OverallMax = max(max_mean);
    if max_mean(k)==OverallMax
        MaxMax = 0;
        row_orig = row;
        col_orig = col;

%        MaxMax2 = sum(sum(FullReconstructedFinal((row-round(WindowSize/2)):(row+round(WindowSize/2)),(col-round(WindowSize/2)):(col+round(WindowSize/2)))));
%        if abs(MaxMax2) > abs(MaxMax)
%            MaxMax = MaxMax2;
%            rowRange = (row-round(WindowSize/2)):(row+round(WindowSize/2));
%            colRange = (col-round(WindowSize/2)):(col+round(WindowSize/2));
%            pix_y = row_orig;
%            pix_x = col_orig;
%        end

        for i = 1:WindowSize
            for j = 1:WindowSize
                MaxMax2 = FullReconstructedFinal(row,col);
                %MaxMax2 = sum(sum(FullReconstructedFinal((row-round(WindowSize/2)):(row+round(WindowSize/2)),(col-round(WindowSize/2)):(col+round(WindowSize/2)))));
                if abs(MaxMax2) > abs(MaxMax)
                    MaxMax = MaxMax2;
                    pix_y = row;
                    pix_x = col;
                end
                col = col_orig + j;
            end
            row = row_orig + i;
        end
    end
end

for k = 1:size(img,3)
    MaxICAs(k) = img(pix_y,pix_x,k); 
    %MaxICAs(k) = sum(sum(img(rowRange,colRange,k))); 
end

%MaxICAs = max_mean;
%MaxICAs = squeeze(max(abs(ICA_Reconstructed(end,:,:))));
%MaxFullRe = max(reshape(FullReconstructedFinal,[],1));

MaxFullRe = FullReconstructedFinal(pix_y,pix_x);
%MaxFullRe = sum(sum(FullReconstructedFinal(rowRange,colRange)));
MaxICA = 0;
b = 0;
while (abs(sum(MaxICA))/abs(MaxFullRe)) <0.95
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
        %X_range = round(0.3.*size(ICAs_Reconstructed,1)) : round(0.7.*size(ICAs_Reconstructed,1));
        %Y_range = round(0.3.*size(ICAs_Reconstructed,2)) : round(0.7.*size(ICAs_Reconstructed,2));
        %FinalStep = ICAs_Reconstructed(:, :, end-1) - ICAs_Reconstructed(:, :, 2); % Remove first and last step to reduce noise
        %FinalMask = true(size(FinalStep));
        %FinalMask(X_range,Y_range) = false;
        %FinalStep(FinalMask) = 0;
        %[~, linear_idx] = max(abs(FinalStep(:)));
        %[rowi, coli] = ind2sub(size(FinalStep), linear_idx);
        %pix_y = rowi;
        %pix_x = coli;

    elseif b==5 || b==length(MaxICAs)
        ICAs_Reconstructed = FullReconstructed;
        break
    else 
        ICAs_Reconstructed = ICAs_Reconstructed + ICAs_ReconstructMax;
    end
end
disp(['Taking ',num2str(b),' ICA Component(s)'])

% Calculate RMS of original image vs reconstructed image with ICs 1-b
FinalStepICA = ICAs_Reconstructed(:, :, end) - ICAs_Reconstructed(:, :, 2);
NumPix = size(DATA,1).*size(DATA,2);
FinalStepRMS = sqrt((sum(FinalStep2.^2,"all"))/NumPix);
ICAs_ReconstructedRMS = sqrt((sum(FinalStepICA.^2,"all"))/NumPix);

subplot(numel(Spatial_pos)+1, 3,1)
imagesc(FullReconstructed(:,:,nifgm)./1000,'AlphaData',Mask); axis image; colorbar; hold on; 
caxis([-max(reshape(DATA(:,:,nifgm),[],1)./1000), max(reshape(DATA(:,:,nifgm),[],1))./1000])
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
        caxis([-max(reshape(DATA(:,:,nifgm),[],1))./1000, max(reshape(DATA(:,:,nifgm),[],1))./1000])
        %caxis([-max(FullReconstructed(:)) max(FullReconstructed(:))])

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
    ' | RMS of taken ICs: ', num2str(round(ICAs_ReconstructedRMS,2)), ' mm'],'Interpreter','none')

saveas(ICA_Synth,[pwd,'/ICA/ICA_',TS_File.name(1:end-3),'.png']);

if Options.MaskVolcs ==1
    LastStep2(LastStep2==0) = NaN;
else
    LastStep(LastStep==0) = NaN;
    LastStep2 = LastStep;
end

CompFig = figure()
subplot(1,2,1)
h = imagesc(FinalStep2./1000)
axis image
set(h, 'AlphaData',  ~isnan(LastStep2))
colormap jet
caxis([-max(abs(FinalStep2(:)))./1000 max(abs(FinalStep2(:)))./1000])
set(gca,'YTick',[],'XTick',[])
title('Original data')

subplot(1,2,2)
h2 = imagesc(FinalStepICA./1000)
axis image
set(h2, 'AlphaData', ~isnan(LastStep2))
colormap jet
c = colorbar;
c.Label.String = 'LOS Displacement (m)'
caxis([-max(abs(FinalStep2(:)))./1000 max(abs(FinalStep2(:)))./1000])
hold on
plot(pix_x,pix_y,'ko','MarkerFaceColor','none','MarkerSize',10)
set(gca,'YTick',[],'XTick',[])
title('Taken Reconstructed ICs')
Maxidx = sprintf('%d, ', Maxidx);
Maxidx = Maxidx(1:end-2);
subtitle(['Using ICs ', Maxidx])
saveas(CompFig,[pwd,'/ICA/ICA_',TS_File.name(1:end-3),'Comparison.png']);

end
