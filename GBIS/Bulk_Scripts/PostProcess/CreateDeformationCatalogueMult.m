function FullTable = CreateDeformationCatalogueMult(OutputFilePath,VolcName, NumFrames, SignalLocationGBIS ,Options,DeltaAIC,BestModel,AspectRatio)
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

% Load inversion results and source parameters
invResFiles = dir(OutputFilePath);
Filepath = char(strcat(invResFiles.folder,'/',invResFiles.name));
load(Filepath);

for m = 1:length(invpar.model)
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
                Spatial.LL = SignalLocationGBIS.LatLon(m,:);
                Spatial.OffsetDistanceKm = SignalLocationGBIS.offsetKm(m);
                Spatial.OffsetBearing = SignalLocationGBIS.bearingDeg(m);
                Spatial.Area = SignalLocationGBIS.AreaKm2;
                Spatial.AspectRatio = AspectRatio(m);
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

        % SourceParameters (create table)
        [LowPercent, UpPercent, OptimalResults, Mean, Median] = extractPercentiles(OutputFilePath,Burnin);

        % Add NaNs for extra parameters
        Fields = fieldnames(modelInput);
        
        for i = 2:length(Fields);
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
        keyboard
        numParas = max(numParas(:));
        ExtraFields = 0;
        numDisc = 0;
        if contains(invpar.model(m),'SILL') || contains(invpar.model(m),'DIKE')
            numDisc = numDisc + 1;
            IdxStrike = find(contains(model.parName,'Strike'));
            % Convert strike to be within 0 and 180 degrees (if Sill)
            if contains(invpar.model(m),'SILL')
                if OptimalResults(IdxStrike(numDisc)) >180
                    OptimalResults(IdxStrike(numDisc)) = OptimalResults(IdxStrike(numDisc))-180;
                    Mean(IdxStrike(numDisc)) = Mean(IdxStrike(numDisc))-180;
                    Median(IdxStrike(numDisc)) = Median(IdxStrike(numDisc))-180;
                    LowPercent(IdxStrike(numDisc)) = LowPercent(IdxStrike(numDisc))-180;
                    UpPercent(IdxStrike(numDisc)) = UpPercent(IdxStrike(numDisc))-180;
                end
            end

            if Options.ModifyStrike(m) ==1
                if OptimalResults(IdxStrike(numDisc)) + 90 <=180 & OptimalResults(IdxStrike(numDisc)) + 90 >=0
                    OptimalResults(IdxStrike(numDisc)) = OptimalResults(IdxStrike(numDisc))+90;
                    Mean(IdxStrike(numDisc)) = Mean(IdxStrike(numDisc))+90;
                    Median(IdxStrike(numDisc)) = Median(IdxStrike(numDisc))+90;
                    LowPercent(IdxStrike(numDisc)) = LowPercent(IdxStrike(numDisc))+90;
                    UpPercent(IdxStrike(numDisc)) = UpPercent(IdxStrike(numDisc))+90;
                else
                    OptimalResults(IdxStrike(numDisc)) = OptimalResults(IdxStrike(numDisc))-90;
                    Mean(IdxStrike(numDisc)) = Mean(IdxStrike(numDisc))-90;
                    Median(IdxStrike(numDisc)) = Median(IdxStrike(numDisc))-90;
                    LowPercent(IdxStrike(numDisc)) = LowPercent(IdxStrike(numDisc))-90;
                    UpPercent(IdxStrike(numDisc)) = UpPercent(IdxStrike(numDisc))-90;
                end
            end
            % Add on volume column 
            pIdxL = find(contains(model.parName,'Length'));
            pIdxW = find(contains(model.parName,'Width'));
            pIdxO = find(contains(model.parName,'Opening'));
            %newIdx = find(isnan(OptimalResults),1,'first');
            % Substitute in new Volume values
            newIdx = pIdxO(numDisc);
            StartIdx(numDisc) = newIdx+1;
            OptimalResults = [OptimalResults(1:newIdx),OptimalResults(pIdxL(numDisc))*OptimalResults(pIdxW(numDisc))*OptimalResults(pIdxO(numDisc)),OptimalResults(newIdx+1:end)];
            Mean = [Mean(1:newIdx),Mean(pIdxL(numDisc))*Mean(pIdxW(numDisc))*Mean(pIdxO(numDisc)),Mean(newIdx+1:end)];
            Median = [Median(1:newIdx),Median(pIdxL(numDisc))*Median(pIdxW(numDisc))*Median(pIdxO(numDisc)),Median(newIdx+1:end)];
            LowPercent = [LowPercent(1:newIdx),LowPercent(pIdxL(numDisc))*LowPercent(pIdxW(numDisc))*LowPercent(pIdxO(numDisc)),LowPercent(newIdx+1:end)];
            UpPercent = [UpPercent(1:newIdx),UpPercent(pIdxL(numDisc))*UpPercent(pIdxW(numDisc))*UpPercent(pIdxO(numDisc)),UpPercent(newIdx+1:end)];
            % Split individual models
            if numDisc==1
                OptimalResults = OptimalResults(1:StartIdx(numDisc));
                Mean = Mean(1:StartIdx(numDisc));
                Median = Median(1:StartIdx(numDisc));
                LowPercent = LowPercent(1:StartIdx(numDisc));
                UpPercent = UpPercent(1:StartIdx(numDisc));
            else
                OptimalResults = OptimalResults(StartIdx(numDisc-1)+ExtraFields:StartIdx(numDisc));
                Mean = Mean(StartIdx(numDisc-1)+ExtraFields:StartIdx(numDisc));
                Median = Median(StartIdx(numDisc-1)+ExtraFields:StartIdx(numDisc));
                LowPercent = LowPercent(StartIdx(numDisc-1)+ExtraFields:StartIdx(numDisc));
                UpPercent = UpPercent(StartIdx(numDisc-1)+ExtraFields:StartIdx(numDisc));
            end
            ExtraFields = ExtraFields + 1;
        else
            OptimalResults = OptimalResults(model.mIx(m)+ExtraFields:(model.mIx(m+1)-1)+ExtraFields);
            Mean = Mean(model.mIx(m)+ExtraFields:(model.mIx(m+1)-1)+ExtraFields);
            Median = Median(model.mIx(m)+ExtraFields:(model.mIx(m+1)-1)+ExtraFields);
            UpPercent = UpPercent(model.mIx(m)+ExtraFields:(model.mIx(m+1)-1)+ExtraFields);
            LowPercent = LowPercent(model.mIx(m)+ExtraFields:(model.mIx(m+1)-1)+ExtraFields);
        end
        
        OptimalResults = [OptimalResults, NaN(1,(numParas - length(OptimalResults)))];
        Mean = [Mean, NaN(1,(numParas - length(Mean)))];
        Median = [Median, NaN(1,(numParas - length(Median)))];
        LowPercent = [LowPercent, NaN(1,(numParas - length(LowPercent)))];
        UpPercent = [UpPercent, NaN(1,(numParas - length(UpPercent)))];

        ModelName = invpar.model(m);
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
        Table{m} = FullTable;
    else
        FullTable = SourceParameters;
    end
    % Changing data types so tables can be concatenated
    FullTable.TComments = {FullTable.TComments};
    FullTable.SComments = {FullTable.SComments};
    FullTable.TComments = cellfun(@char, FullTable.TComments, 'UniformOutput', false);
    FullTable.SComments = cellfun(@char, FullTable.SComments, 'UniformOutput', false);
    
    % Combine table rows
    if m>1
        if m==2
            FullTable = vertcat(Table{m},Table{m-1});
        else
            FullTable = vertcat(FullTable,Table{m});
        end
    end
end
