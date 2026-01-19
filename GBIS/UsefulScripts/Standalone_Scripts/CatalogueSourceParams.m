function FullTable = CatalogueSourceParams(OutputFilePath,Burnin)
    % Ben Ireland, University of Bristol, Dec 2023
    % - Script to create a deformation catalogue from spatial, temporal and source parameters extracted from GBIS-BULK
    %% Load parameters

    disp('Creating results table')

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
        OptMod = OptimalResultsR(ModIdxRange);
        MeanMod = MeanR(ModIdxRange);
        MedianMod = MedianR(ModIdxRange);
        LowPCMod = LowPercentR(ModIdxRange);
        UpPCMod = UpPercentR(ModIdxRange);
        
        % Calculate volume of sill or dyke
        [LowVol, UpVol, OptVol, MeanVol, MedianVol] = ExtractDislocVolume(OutputFilePath,Burnin,ModIdxRange);
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
    SourceParameters = table(ModelName,nRuns,OptimalResults,Mean,Median,LowPercent,UpPercent,WeightedRSS,RMSE);

    FullTable = SourceParameters;
end
