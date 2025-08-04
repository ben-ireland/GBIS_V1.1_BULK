function FullTable = CreateDeformationCatalogue(OutputFilePath,VolcName, NumFrames, SignalLocationGBIS ,Options,DeltaAIC,BestModel,AspectRatio)
% Ben Ireland, University of Bristol, Dec 2023
% - Script to create a deformation catalogue from spatial, temporal and source parameters extracted from GBIS-BULK
%% Load parameters

% To add, for multiple frames, compare R2 or number of acquisitions to decide which frame to use for spatial and temporal stats
% To add, round all numeric values

disp('Creating results table')
% Find and load temporal parameters
SpatialFlag = NaN(1,NumFrames);
TemporalFlag = SpatialFlag;
Burnin = Options.Burnin;

for k = 1:NumFrames

    if k>1 % Skip if multiple frames and the first frame wasn't flagged for spatial or temporal review
        if SpatialFlag(k-1) ==0 && TemporalFlag(k-1) ==0
            continue
        end
    end

    if k==1 || (k>1 && TemporalFlag(k-1) ==1)
        TempFile = dir([pwd,'/Temporal_Parameters/*',VolcName{k},'*.mat']);
        TComments = '';
        load(char(strcat(TempFile.folder,'/',TempFile.name)));
        %% Construct table for a single instance
        % Extract relevant columns from temporal, spatial and source parameter
        % files
        % Temporal
        fnT = fieldnames(Model);
        for a=1:numel(fnT)
            if isempty(Model.(fnT{a}))
                Model.(fnT{a}) = NaN;
            end
        end
        fields = {'Name','StartDateIdx','EndDateIdx','StartIdx','EndIdx','Figure'};
        Temporal = rmfield(Model,fields);
        Temporal.Notes = convertCharsToStrings(Temporal.Notes);
        TemporalTab = struct2table(Temporal,"AsArray",true);
        TemporalTab = renamevars(TemporalTab,'Flag','TempFlag');
        TComments = string(TComments);
        TemporalTab = addvars(TemporalTab,TComments);

        if TemporalTab.TempFlag ==1
            TComments = 'Temporal fits flagged';
            if NumFrames>1 && k<NumFrames
                TemporalTab = [];
            end
        end
    else
        %if isempty(TComments) && k==NumFrames
        %    TComments = append(TComments,['Temporal params from frame ',VolcName{k}]);
        %else
        %    TComments = strcat('Temporal params from frame ',VolcName{k});
        %end
    end

    % Find and load spatial parameters
    if k==1 || (k>1 && SpatialFlag(k-1) ==1)
        SpatialFile = dir([pwd,'/Spatial_Parameters/',VolcName{k},'*SignalLocation.mat']);
        SComments = '';
        load(char(strcat(SpatialFile(1).folder,'/',SpatialFile(1).name)));
        % Spatial
        fnS = fieldnames(SignalLocation);
        for a=1:numel(fnS)
            if isempty(SignalLocation.(fnS{a}))
                SignalLocation.(fnS{a}) = NaN;
            end
        end
        Spatial = SignalLocation;
        fields = {'CentPix','Pix'};
        Spatial = rmfield(Spatial,fields);
        Spatial.Comment = convertCharsToStrings(Spatial.Comment);
        Spatial.LL = SignalLocationGBIS.LatLon;
        Spatial.OffsetDistanceKm = SignalLocationGBIS.offsetKm;
        Spatial.OffsetBearing = SignalLocationGBIS.bearingDeg;
        Spatial.Area = SignalLocationGBIS.AreaKm2;
        Spatial.AspectRatio = AspectRatio;
        SpatialTab = struct2table(Spatial);
        SpatialTab = renamevars(SpatialTab,'Flag','SpaFlag_Otsu');
        SComments = string(SComments);
        SpatialTab = addvars(SpatialTab,SComments);

        if SpatialTab.SpaFlag_Otsu ==1
            SComments = 'Signal location flagged';
            if NumFrames>1 && k<NumFrames
                SpatialTab = [];
            end
        end
    else
        %if isempty(SComments) && k==NumFrames
        %    SComments = append(SComments,['Spatial params from frame ',VolcName{k}]);
        %else
        %    SComments =  strcat('Spatial params from frame ',VolcName{k});
        %end
    end

    if NumFrames>1
        if isempty(SpatialTab)
            SpatialFlag(k) = 1;
        else
            SpatialFlag(k) = 0;
        end

        if isempty(TemporalTab)
            TemporalFlag(k) = 1;
        else
            TemporalFlag(k) = 0;
        end

        if SpatialFlag(k) ==0 && TemporalFlag(k) ==0
            SComments = append(SComments,['Spatial params from frame ',VolcName{k}]);
            TComments = append(TComments,['Temporal params from frame ',VolcName{k}]);
        elseif SpatialFlag(k) ==1 && TemporalFlag(k) ==1
            if k == NumFrames
                SComments = append(SComments,[', Spatial params from frame ',VolcName{k}]);
                TComments = append(TComments,[', Temporal params from frame ',VolcName{k}]);
            else
                continue
            end
        end     
    end

    if length(SComments) ==1
        SComments = 'None';
    end

    if length(TComments) ==1
        TComments = 'None';
    end
    
    TemporalTab.TComments = TComments;
    SpatialTab.SComments = SComments;

    % Load inversion results and source parameters
    invResFiles = dir(OutputFilePath);
    Filepath = char(strcat(invResFiles.folder,'/',invResFiles.name));
    load(Filepath);

    % SourceParameters (create table)
    [LowPercentR, UpPercentR, OptimalResultsR, MeanR, MedianR] = extractPercentiles(OutputFilePath,Burnin);

    % Add NaNs for extra parameters
    Fields = fieldnames(modelInput);
    for i = 4:length(Fields);
        Struct = modelInput.(Fields{i});
        if isstruct(Struct)
            numParas(i-1) = mean(structfun(@numel,Struct));
        else
            for j = 1:length(Struct)
                Struct1 = Struct{j};
                numPara(j) = mean(structfun(@numel,Struct1));
                if j==length(Struct)
                    numParas(i-1) = max(numPara);
                end
            end
        end
    end
    numParas = max(numParas(:)); % Max n. parameters from any model (for table columns)
    ModIdxRange = invResults.model.mIx(1):invResults.model.mIx(2)-1;
    ParNames = model.parName(ModIdxRange);

    if contains(invpar.model,'SILL') || contains(invpar.model,'DIKE')
        % Add on volume column 
        IdxStrike = find(contains(ParNames,'Strike'));
        pIdxL = find(contains(ParNames,'Length'));
        pIdxW = find(contains(ParNames,'Width'));
        pIdxO = find(contains(ParNames,'Opening'));

        OptMod = OptimalResultsR(ModIdxRange);
        MeanMod = MeanR(ModIdxRange);
        MedianMod = MedianR(ModIdxRange);
        LowPCMod = LowPercentR(ModIdxRange);
        UpPCMod = UpPercentR(ModIdxRange);

        % Convert strike to be within 0 and 180 degrees (if Sill)
        if contains(invpar.model,'SILL')
            if OptMod(IdxStrike) >180
                OptMod(IdxStrike) = OptMod(IdxStrike)-180;
                MeanMod(IdxStrike) = MeanMod(IdxStrike)-180;
                MedianMod(IdxStrike) = MedianMod(IdxStrike)-180;
                LowPCMod(IdxStrike) = LowPCMod(IdxStrike)-180;
                UpPCMod(IdxStrike) = UpPCMod(IdxStrike)-180;
            end
        end
        if Options.ModifyStrike ==1
            if OptMod(IdxStrike) + 90 <=180 & OptMod(IdxStrike) + 90 >=0
                OptMod(IdxStrike) = OptMod(IdxStrike)+90;
                MeanMod(IdxStrike) = MeanMod(IdxStrike)+90;
                MedianMod(IdxStrike) = MedianMod(IdxStrike)+90;
                LowPCMod(IdxStrike) = LowPCMod(IdxStrike)+90;
                UpPCMod(IdxStrike) = UpPCMod(IdxStrike)+90;
            else
                OptMod(IdxStrike) = OptMod(IdxStrike)-90;
                MeanMod(IdxStrike) = MeanMod(IdxStrike)-90;
                MedianMod(IdxStrike) = MedianMod(IdxStrike)-90;
                LowPCMod(IdxStrike) = LowPCMod(IdxStrike)-90;
                UpPCMod(IdxStrike) = UpPCMod(IdxStrike)-90;
            end
        end

        % Calculate volume of sill or dyke
        [LowVol, UpVol, OptVol, MeanVol, MedianVol] = ExtractDislocVolume(OutputFilePath,Options.Burnin,ModIdxRange);
        OptMod(end+1) = OptVol;
        MeanMod(end+1) = MeanVol;
        MedianMod(end+1) = MedianVol;
        LowPCMod(end+1) = LowVol;
        UpPCMod(end+1) = UpVol;
    else
        OptMod = OptimalResultsR(ModIdxRange);
        MeanMod = MeanR(ModIdxRange);
        MedianMod = MedianR(ModIdxRange);
        LowPCMod = LowPercentR(ModIdxRange);
        UpPCMod = UpPercentR(ModIdxRange);
    end

    OptimalResults = [OptMod, NaN(1,(numParas - length(OptMod)))];
    Mean = [MeanMod, NaN(1,(numParas - length(MeanMod)))];
    Median = [MedianMod, NaN(1,(numParas - length(MedianMod)))];
    LowPercent = [LowPCMod, NaN(1,(numParas - length(LowPCMod)))];
    UpPercent = [UpPCMod, NaN(1,(numParas - length(UpPCMod)))];


    ModelName = invpar.model(1);
    nRuns = invpar.nRuns;
    WeightedRSS = invResults.model.OptweightedRSS;
    RMSE = invResults.model.OptRMSE;
    if NumFrames ==1
        VolcanoName = convertCharsToStrings(VolcName{k});
    else
        VolcanoName = join(convertCharsToStrings(VolcName),' & ');
    end
    BestModel = convertCharsToStrings(BestModel);
    SourceParameters = table(ModelName,nRuns,OptimalResults,Mean,Median,LowPercent,UpPercent,WeightedRSS,RMSE,DeltaAIC,BestModel);
    Name = table(VolcanoName);
end

% Combine tables of temporal, spatial and source parameters
if exist('Model')==1 && exist('SignalLocation')==1
    FullTable = horzcat(Name,TemporalTab,SpatialTab,SourceParameters);
else
    FullTable = SourceParameters;
end
% Changing data types so tables can be concatenated
FullTable.TComments = {FullTable.TComments};
FullTable.SComments = {FullTable.SComments};
FullTable.TComments = cellfun(@char, FullTable.TComments, 'UniformOutput', false);
FullTable.SComments = cellfun(@char, FullTable.SComments, 'UniformOutput', false);

end
