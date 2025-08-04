function InpFilePath = ProcessSeedingRun(InpFilePath,SeedFilepath,Options)
    % Ben Ireland, July 2025, updating GBIS input bounds following seeding run at reduced nRuns
    
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
    startStr = vectorToSemicolonString(modelInput.(ModelName{:}).start);
    startBoundStr = vectorToSemicolonString(Optimal_Results);

    % Use median/mean bounds if optimum bounds are outside upper or lower bounds
    if any(Optimal_Results > Per_975_Results) | any(Optimal_Results < Per_25_Results)
        startBoundStr = vectorToSemicolonString(Mean_Results);
    end

    % Adjust upper of lower bounds to include mean value if this still persists
    if any(Mean_Results > Per_975_Results) | any(Mean_Results < Per_25_Results)
        if any(Mean_Results > Per_975_Results)
            Result = any(Mean_Results > Per_975_Results);
            Idxs = find(Result ==1);
            Per_975_Results(Idxs) = Optimal_Results(Idxs);
        end

        if any(Mean_Results < Per_25_Results)
            Result = any(Mean_Results < Per_25_Results);
            Idxs = find(Result ==1);
            Per_25_Results(Idxs) = Mean_Results(Idxs);
        end
    end

    % Create lower and upper bounds
    lowStr = vectorToSemicolonString(modelInput.(ModelName{:}).lower);
    lowerBoundStr = vectorToSemicolonString(Per_25_Results);
    upperStr = vectorToSemicolonString(modelInput.(ModelName{:}).upper);
    upperBoundStr = vectorToSemicolonString(Per_975_Results);

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