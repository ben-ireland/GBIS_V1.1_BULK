function [LogDist, MedStd, AvgStd] = EARPhaseSTD(NCnames)

% Ben Ireland, September 2023
% Script to find the spatial STD. of unwrapped phase for the EAR dataset
% interferograms

% Extract .nc names, use these for the UNW file variables for each volcano
% Load unw ifg and remove null values
wavelength = 0.056;
rad2m = (wavelength./(4.*pi));

f1 = figure();
Nfiles = 0;
for n = 1:length(NCnames)
    UnwFiles = dir([pwd,'/EAR_Data/',NCnames(n).name(1:end-3),'/unwrapped/*.geo.unw.tif']);
    if length(UnwFiles)==0
        continue
    else
        Nfiles = Nfiles + 1;
    end
    for k = 1:length(UnwFiles)
        UnwName = char(strcat(UnwFiles(k).folder,'/',UnwFiles(k).name));
        [A, ~] = readgeoraster(UnwName);
        A(A==0) = NaN;
        
        % Calculate STD
        U_Std(Nfiles,k) = std(A,[],"all",'omitnan');
    end
    U_Std(U_Std==0) = NaN;
    plot(U_Std(Nfiles,:))
    hold on
end
% Averages
AvgStd = mean(U_Std(:),'omitnan');
MedStd = median(U_Std(:),'omitnan');

U_StdL = log(U_Std);
Lmean = mean(U_StdL(:),'omitnan');
LMed = median(U_StdL(:),'omitnan');
LStd = std(U_StdL,[],"all",'omitnan');

% Reconverted mean and median
LC_mean = exp(Lmean);
LC_median = exp(LStd);

xlabel('IFG number')
ylabel('STD of LOS velocities (rad)')
legend(NCnames(:).name,'Mean','Median','Interpreter','none')
hold on
yline(AvgStd,'k-',[],'LineWidth',2.5)
hold on
yline(MedStd,'r-',[],'LineWidth',2.5)

f2 = figure();
hist(reshape(U_StdL,[],1)*rad2m,0:0.1:ceil(max(U_StdL(:))))
xlabel('log STD of LOS velocities (rad)')
ylabel('Probability denisty')
xlim([0, (ceil(max(log(U_Std(:)))))+1])
hold on
xline(Lmean,'r-','Mean')
hold on
% xline(LMed,'r-','Median')
% hold on
xline((Lmean+LStd),'r-','1 STD')
hold on
xline((Lmean-LStd),'r-','1 STD')
hold off

% Plot temporal decay of noise using these initial single IFG values
e = rad2m*LC_mean*1000; % Velocity uncertainty (Median STD) value from Morishita et al. 2020 for single non-GACOS corrected S1 LiCSAR IFG
T = (12/365):(12/365):5; % Timesteps from 1-5 years using a 12 day interval (decimal years)
N = length(T); % Number of epochs per timeseries

for k = 1:length(T)
    V(k) = (2*(sqrt(3))*e)/((k^0.5)*T(k)); % Formulation for noise decay following Morishita et al. 2020
end

% Albino et al. 2022 formulation (V = deltaT^-b (b = 3/2 for pure
% uncorrelated white noise)
T2 = T.^(-3/2);
T2 = e*T2;
% Plot decay
f3 = figure();
plot(T,V)
hold on
plot(T,T2)
xlabel 'Time (years)'
ylabel 'Velocity uncertainty (mm/yr)'
set(gca,'YScale','log')
lgd = legend({'Morishita et al. 2020','Albino et al. 2022'});
lgd.Title.String = ['Single IFG uncertainty (mm) = ',num2str(e)];

% Create pseudorandom normal distribution of mean Lmean and STD LStd
LogDist = LStd.*randn(10000,1) + Lmean;

IFG_Noise = reshape(U_Std*rad2m,[],1)*1000;
NoisePC_Vals = [prctile(IFG_Noise,5), prctile(IFG_Noise,25), prctile(IFG_Noise,50), prctile(IFG_Noise,75), prctile(IFG_Noise,95)];

keyboard

% Save outputs
if ~exist([pwd,'/EAR_Data/Noise'],'dir')
    mkdir(pwd,'EAR_Data/Noise')
    addpath([pwd,'/EAR_Data/Noise'])
end

saveas(f1, [pwd,'/EAR_Data/Noise/InvidualIFGNoise.png']);
saveas(f2, [pwd,'/EAR_Data/Noise/IFGNoiseHistogram.png']);
saveas(f3, [pwd,'/EAR_Data/Noise/TimeseriesNoiseDecay.png']);
save([pwd,'/EAR_Data/Noise/NoiseCharacteristics.mat'], "U_Std","U_StdL","LogDist");
end