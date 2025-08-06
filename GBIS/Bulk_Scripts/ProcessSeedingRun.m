function InpFilePath = ProcessSeedingRun(InpFilePath,SeedFilepath,Options)
    % Ben Ireland, July 2025, updating GBIS input bounds following seeding run at reduced nRuns
    % Note: only works with a single model
    % TODO: Update to work with multiple models
    
    % Extract percentiles of seeding run
    SeedFilepath = [pwd,SeedFilepath];
    [Per_25_Results, Per_975_Results, Optimal_Results, Mean_Results, ~] = extractPercentiles(SeedFilepath,Options.SeedingBurnin);

    % Load results and determine which source is being used
    load(SeedFilepath);
    ModelNames = fieldnames(modelInput);
    matches = contains(ModelNames,invpar.model,'IgnoreCase',true);
    ModelName = ModelNames(matches);

    % Load input file
    inputFileID = fopen(InpFilePath, 'r');
    textLine = fgetl(inputFileID); 
    
    while ischar(textLine)
        eval(textLine)
        textLine = fgetl(inputFileID);
    end
    
    fclose(inputFileID);
    outputFileName = InpFilePath;

    % load old and new bounds
    numParas = length(modelInput.(ModelName{:}).start); % Removes any offsets
    startStr = vectorToSemicolonString(modelInput.(ModelName{:}).start);
    startBoundStr = vectorToSemicolonString(Optimal_Results(1:numParas));

    % Use median/mean bounds for start boounds if optimum bounds are outside upper or lower bounds
    if any(Optimal_Results(1:numParas) > Per_975_Results(1:numParas)) | any(Optimal_Results(1:numParas) < Per_25_Results(1:numParas))
        startBoundStr = vectorToSemicolonString(Mean_Results(1:numParas));

        % Adjust upper and lower bounds to include mean value if it is outside of lower/upper bounds
        if any(Mean_Results(1:numParas) > Per_975_Results(1:numParas)) | any(Mean_Results(1:numParas) < Per_25_Results(1:numParas))
            if any(Mean_Results(1:numParas) > Per_975_Results(1:numParas))
                Result = any(Mean_Results(1:numParas) > Per_975_Results(1:numParas));
                Idxs = find(Result ==1);
                Per_975_Results(Idxs) = Optimal_Results(Idxs);
            end

            if any(Mean_Results(1:numParas) < Per_25_Results(1:numParas))
                Result = any(Mean_Results(1:numParas) < Per_25_Results(1:numParas));
                Idxs = find(Result ==1);
                Per_25_Results(Idxs) = Mean_Results(Idxs);
            end
        end
    end

    % Create lower and upper bounds
    lowStr = vectorToSemicolonString(modelInput.(ModelName{:}).lower);
    lowerBoundStr = vectorToSemicolonString(Per_25_Results(1:numParas));
    upperStr = vectorToSemicolonString(modelInput.(ModelName{:}).upper);
    upperBoundStr = vectorToSemicolonString(Per_975_Results(1:numParas));

    % Update bounds in input file
    InpFilePath = modifyInpFile2( ...
    InpFilePath, ...
    outputFileName, ...
    ['modelInput.',ModelName{:},'.start'], ...
    startStr, ...
    startBoundStr, ...
    'y', 1);

    InpFilePath = modifyInpFile2( ...
    InpFilePath, ...
    outputFileName, ...
    ['modelInput.',ModelName{:},'.lower'], ...
    lowStr, ...
    lowerBoundStr, ...
    'y', 1);

    InpFilePath = modifyInpFile2( ...
    InpFilePath, ...
    outputFileName, ...
    ['modelInput.',ModelName{:},'.upper'], ...
    upperStr, ...
    upperBoundStr, ...
    'y', 1);

end