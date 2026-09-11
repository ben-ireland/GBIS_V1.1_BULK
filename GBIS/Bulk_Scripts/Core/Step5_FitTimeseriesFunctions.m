function Model = Step5_FitTimeseriesFunctions(LOS, days, FileInfo, SignalLocation, Name, Options)
% Ben Ireland, November 2023, University of Bristol
%
% Function to fit either a linear or sigmoidal fit to a timeseries, compare
% the fit using Akaike's Information Criterion (AIC) and RSS, and output
% temporal characteristics of the signals. 
%
% Based on Albino et al. 2022, Remote Sensing 14(22).
%
%%%%%%%%%%%%%%%%%%%%%%%%%% INPUT VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  LOS: x by y by n array timeseries of LOS displacements
%
%  days: n element vector of relative time (in days) of each timeseries
%  step
%
%  FileInfo: details of the .nc timeseries file containing information
%  about units and start date of the timeseries
%
%  SignalLocation: 2 element vector of indexes of signal position [lon lat]
%
%  Name: Unique identifier for the outputs
%
%%%%%%%%%%%%%%%%%%%%%%%%%% OUTPUT VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  Model: Data structure containing characteristics of the fitted function
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot the timeseries against days (Need method to pick signal pixel?)
Model.Name = Name;
TS = double(squeeze(LOS(SignalLocation(1),SignalLocation(2),:))); % Lat, Lon
figure()
plot(days,TS,LineStyle="none",Marker=".");
nObs = length(days);

% Convert days to datetime format
if isfield(FileInfo,'Attributes')
    TimeUnits = FileInfo.Attributes(2).Value;
    StartDate = extractAfter(TimeUnits,'days since ');
    StartDate = datetime(StartDate,'InputFormat','yyyy-MM-dd');
    Dates = StartDate + days;
else
    Dates = FileInfo.Dates;
    StartDate = FileInfo.StartDate;
end
LastStep = squeeze(LOS(:,:,end));
LastStep(LastStep==0)=NaN;
subplot(1,3,1)
h = imagesc(squeeze(LOS(:,:,end)))
set(h, 'AlphaData', ~isnan(LastStep))
title(['Signal Location (x,y): (',num2str(SignalLocation(2)),', ',num2str(SignalLocation(1)),')'])
axis image
colormap jet
C = colorbar("Location","westoutside")
C.Label.String = 'LOS Displacement (m)'
caxis([-0.1 0.1]);
set(gca,'YTick',[],'XTick',[])
hold on
plot(SignalLocation(2),SignalLocation(1), 'ko','MarkerSize',10)
hold off

%% Fit a linear trendline and compute the RSS: (f(x) = ax)
LinearFit = fitlm(days,TS,'Intercept',true);
subplot(1,3,2)
p = plot(LinearFit);
title('Linear Fit')
subtitle(['RSS = ',num2str(LinearFit.SSE)]);
axis square
xlabel('Timeseries length (Days)');
ylabel('LOS displacement (m)');

LinRSS = LinearFit.SSE;
LinParams = 2; % Number of linear parameters

%% Fit sigmoidal function and compute the RSS (f(x) = a/1+e^(-(x-c)/b))
sigmoidalFit = @(params, t) params(1) ./ (1 + exp(-(t - params(2)) / params(3)));

% Initial guess for parameters
initialGuess = [range(TS), mean(days), (max(days) - min(days)) / 8]; % Guessing Umax, tc, and tau

% Define bounds
max_tau = days(end); % maximum allowable value for params(3)
lb = [-Inf, -Inf, 0]; % Lower bounds: Umax >= 0, tc unrestricted, tau >= 0
ub = [Inf, Inf, max_tau]; % Upper bounds: Umax unrestricted, tc unrestricted, tau <= max_tau

% Fit the sigmoidal function using lsqcurvefit
fitParams = lsqcurvefit(sigmoidalFit, initialGuess, days, TS, lb, ub);

% Extract the fitted parameters
Umax_fit = fitParams(1);
tc_fit = fitParams(2);
tau_fit = fitParams(3);

% Generate the fitted curve for plotting
U_fit = sigmoidalFit(fitParams, days); % Using the obtained parameters to generate curve values at x coords from 'days'
SigResidual = U_fit-TS;
SigRSS = sum(SigResidual.^2);
SigTSS = sum((TS-mean(TS)).^2);
SigR2 = 1 - (SigRSS/SigTSS);
SigParams = 3; % Number of sigmoidal parameters

subplot(1,3,3)
plot(days, TS, 'bx', days, U_fit, 'r-');
legend('Original Data', 'Fitted Function');
xlabel('Timeseries length (Days)');
ylabel('LOS displacement (m)');
title('Sigmoidal Fit');
subtitle(['RSS = ',num2str(SigRSS)]);
axis square
set(gcf, 'Position', get(0, 'Screensize'));

%% Initialise model characteristics structure
Model.Type = '';
Model.AIC = [];
Model.R2 = [];
Model.UnrestDays = [];
Model.CentreTime = [];
Model.MaxDisp = [];
Model.UnrestStart = [];
Model.UnrestEnd = [];
Model.UnrestDuration = [];
Model.StartDate = [];
Model.EndDate = [];
Model.StartDateIdx = [];
Model.EndDateIdx = [];
Model.StartIdx = [];
Model.EndIdx = [];
Model.DispRateM = [];
Model.DispRateCM = [];
Model.Notes = 'None';
Model.Flag = 0;
Model.Figure = [];
Model.SigRSS = SigRSS;
Model.LinRSS = LinRSS;
Model.SigP = SigParams;
Model.LinP = LinParams;
Model.Data = TS;
Model.nObs = nObs;
Model.Linear = LinearFit;
Model.Sigmoid = U_fit;
Model.DefData = LastStep;
Model.Days = days;
Model.Dates = Dates;
Model.SigParas = fitParams;

%% Check R2 values
LinAdjR2 = LinearFit.Rsquared.Adjusted;
SigAdjR2 = 1 - ((1-SigR2)*(nObs-1)/(nObs-SigParams-1));
if LinAdjR2<Options.Temp_R2_Thresh && SigAdjR2>Options.Temp_R2_Thresh % If Linear R2 is <0.5
    Model.Notes = strcat('Linear R2 <',num2str(Options.Temp_R2_Thresh));
elseif LinAdjR2>Options.Temp_R2_Thresh && SigAdjR2<Options.Temp_R2_Thresh % If Sigmoid R2 is <0.5
    Model.Notes = strcat('Sigmoidal R2 <',num2str(Options.Temp_R2_Thresh));
end

%% Fit a hybrid trendline and compute the RSS (?) - how to identify a seasonal component?
if LinAdjR2<Options.Temp_R2_Thresh && SigAdjR2<Options.Temp_R2_Thresh
    % Try to remove a seasonal component?
    Model.Type = 'Other';
    Model.Notes = strcat('R2 <',Options.Temp_R2_Thresh,'for linear and sigmoid');
    Model.Flag = 1;
    Model.AIC = NaN;
    Model.R2 = 0;

    Model.StartIdx = 1;
    Model.EndIdx = length(days);
    Model.StartDate = Dates(1);
    Model.EndDate = Dates(end);
else

%% Compute the delta AIC to work out the preferred model if needed
% Negative, sigmoid preferred; positive, linear preferred
    if matches(Options.Temp_Metric,'BIC')
        % Keeping variable name as AIC for consistency with later scripts
        Model.AIC = nObs * log(SigRSS / LinRSS) + ((SigParams - LinParams)*log(nObs));
    elseif matches(Options.Temp_Metric,'AIC')
        Model.AIC = nObs*(log(SigRSS/LinRSS)) + (2*SigParams - 2*LinParams);
    else
        error('Value for Options.Temp_Metric wrong - should be ''AIC'' or ''BIC''')
    end
end

%% Collate and output characteristics of the signals, including start and
% end time steps for sigmoidal trending signals
% Initialise model structure

if Model.AIC <-Options.Temp_AIC_Thresh % Sigmoid preferred
    % Derive unrest time period, start time, centre time (Tc), max displacement
    Model.Type = 'Sigmoid';
    Model.R2 = SigAdjR2;
    Model.UnrestDays = fitParams(3);
    Model.CentreTime = fitParams(2);
    Model.MaxDisp = fitParams(1);
    Model.UnrestStart = Model.CentreTime - (2*Model.UnrestDays);
    Model.UnrestEnd = Model.CentreTime + (2*Model.UnrestDays);
    Model.UnrestDuration = Model.UnrestEnd - Model.UnrestStart;
    Model.StartDate = daysadd(StartDate,floor(Model.UnrestStart));
    Model.EndDate = daysadd(StartDate,ceil(Model.UnrestEnd));

    % Find time index corresponding to start and end time
    % Minimum negative distance from the start and minimum positive
    % distance from the end (to pad the timeseries)
    Model.StartIdx = days - Model.UnrestStart;
    Model.EndIdx = days - Model.UnrestEnd;
    if Model.UnrestStart<0
        Model.StartIdx =1;
    else
        Model.StartIdx(Model.StartIdx>0) = NaN;
        [~, Model.StartIdx] = min(abs(Model.StartIdx));
    end
    if Model.UnrestEnd>days(end)
        Model.EndIdx = length(days);
    else
        Model.EndIdx(Model.EndIdx<0) = NaN;
        [~, Model.EndIdx] = min(abs(Model.EndIdx));
    end
    Model.StartDateIdx = Dates(Model.StartIdx);
    Model.EndDateIdx = Dates(Model.EndIdx);

elseif Model.AIC >=-Options.Temp_AIC_Thresh % Linear preferred
    Model.Type = 'Linear';

    if Model.AIC >-Options.Temp_AIC_Thresh && Model.AIC <Options.Temp_AIC_Thresh % Add a flag if the model fits were close to equal AIC
        Model.Notes = '|AIC| <10';
    end
    % Derive average displacement rate and b (uncertainty decay rate)
    Model.DispRateM = LinearFit.Coefficients.Estimate(2); % In m/day
    Model.DispRateM = Model.DispRateM*365.25; % Convert to m/year
    Model.DispRateCM = Model.DispRateM*100; % Convert to cm/year
    Model.R2 = LinAdjR2;

    Model.StartIdx = 1;
    Model.EndIdx = length(days);
    Model.StartDate = Dates(1);
    Model.EndDate = Dates(end);

end

% Save figure and create folder if it doesn't exist
if ~exist([pwd,'/Temporal_Parameters'],'dir')
    mkdir(pwd,'/Temporal_Parameters')
    addpath([pwd,'/Temporal_Parameters'])
end

if Model.Flag ==0
sgtitle(sprintf([Name,'\n','Preferred model: ', Model.Type,...
        '\n','AIC: ', num2str(round(Model.AIC,3))...
        '\n','Result not flagged for manual review']),'interpreter','none');
elseif Model.Flag==1
    sgtitle(sprintf([Name,'\n','Preferred model: ', Model.Type,...
        '\n','Result flagged for manual review']),'interpreter','none');
end

if Model.Flag ==0
    TempFilename = strcat(pwd,'/Temporal_Parameters/','TS_Fit_',Name,'.png');
    saveas(gcf,TempFilename);
    TempFilename2 = strcat(pwd,'/Temporal_Parameters/','TempPara_',Name,'.mat');
    save(TempFilename2,'Model','-mat');
elseif Model.Flag ==1
    TempFilename = strcat(pwd,'/Temporal_Parameters/','TS_Fit_',Name,'.png');
    saveas(gcf,TempFilename);
    TempFilename2 = strcat(pwd,'/Temporal_Parameters/','TempPara_',Name,'.mat');
    save(TempFilename2,'Model','-mat');
end
Model.Figure = gcf;
end