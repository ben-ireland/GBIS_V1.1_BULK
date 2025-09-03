function FullTable = Step9_GenerateReportsTable_MultipleSources(FullTable,OutputFilepath,NumFrames,VolcNames,VolcName,Options)

    if Options.PennyComparison ==1 && NumFrames >1
        disp('Generating Mogi reports (~2 mins)')
        SignalLocationGBIS = SignalLocationFromResultsMult(OutputFilepath{1}, VolcName);
        keyboard
        Area = ExtractGBISSignalArea(OutputFilepath{1},Options.AreaCutoff);
        SignalLocationGBIS.AreaKm2 = Area;
        ReportFilePath = generateFinalReportPDF_Mult(OutputFilepath{1},Options.Burnin);
        Report = CreatePDF_Report(ReportFilePath,OutputFilepath{1},VolcNames,Options);

        disp('Generating Penny reports (~2 mins)')
        SignalLocationGBISPen = SignalLocationFromResultsMult(OutputFilepath{2}, VolcName);
        Area = ExtractGBISSignalArea(OutputFilepath{2},Options.AreaCutoff);
        SignalLocationGBISPen.AreaKm2 = Area;
        ReportFilePathPen = generateFinalReportPDF_Mult(OutputFilepath{2},Options.Burnin);
        ReportPen = CreatePDF_Report(ReportFilePathPen,OutputFilepath{2},VolcNames,Options);

        % Compare results using AIC between Penny and Mogi
        [DeltaAIC, BestModel] = CompareAICPennyMogi(OutputFilepath{1},OutputFilepath{2});
    else
        SignalLocationGBIS = SignalLocationFromResultsMult(OutputFilepath{1}, VolcNames);
        keyboard
        Area = ExtractGBISSignalArea(OutputFilepath{1},Options.AreaCutoff);
        SignalLocationGBIS.AreaKm2 = Area;
        ReportFilePath = generateFinalReportPDF_Mult(OutputFilepath{1},Options.Burnin);
        %Report = CreatePDF_Report(ReportFilePath,OutputFilepath{1},VolcNames,Options);

        DeltaAIC = NaN;
        BestModel = NaN;
    end

    if length(OutputFilepath) > 2
        for k = 3:length(OutputFilepath)
            SignalLocationGBIS = SignalLocationFromResultsMult(OutputFilepath{k}, VolcName);
            Area = ExtractGBISSignalArea(OutputFilepath{1},Options.AreaCutoff);
            SignalLocationGBIS.AreaKm2 = Area;
            ReportFilePath = generateFinalReportPDF_Mult(OutputFilepath{k},Options.Burnin);
            Report = CreatePDF_Report(ReportFilePath,OutputFilepath{k},VolcNames,Options);
    
            DeltaAIC = NaN;
            BestModel = NaN;
        end
    end

    keyboard
    if Options.CreateTable ==1
        % Create table of parameters for each run
        if Options.PennyComparison ==1 && NumFrames >1
            Table = CreateDeformationCatalogue(OutputFilepath{1},VolcNames,NumFrames,SignalLocationGBIS,Options.Burnin,DeltaAIC,BestModel);
            TablePen = CreateDeformationCatalogue(OutputFilepath{2},VolcNames,NumFrames,SignalLocationGBISPen,Options.Burnin,DeltaAIC,BestModel);
            
            Table = outerjoin(Table, TablePen, 'MergeKeys', true, 'Type', 'full', 'LeftVariables', Table.Properties.VariableNames, 'RightVariables', TablePen.Properties.VariableNames);
        else
            Table = CreateDeformationCatalogue(OutputFilepath{1},VolcNames,NumFrames,SignalLocationGBIS,Options.Burnin,DeltaAIC,BestModel);
        end
        disp('Merging new table with previous table')

        if istable(FullTable)
            if width(Table) ~= width(FullTable) || ~all(ismember(Table.Properties.VariableNames, FullTable.Properties.VariableNames))
                %FullTable = outerjoin(FullTable,Table,'MergeKeys',true);
                % Perform an outer join to align the tables and add missing columns
                FullTable = outerjoin(FullTable, Table, 'MergeKeys', true, 'Type', 'full', 'LeftVariables', FullTable.Properties.VariableNames, 'RightVariables', Table.Properties.VariableNames);
                
                % Ensure that the columns of FullTable follow the column order of Table
                FullTable = [FullTable(:, FullTable.Properties.VariableNames(1:width(FullTable) - width(Table))), ...
                FullTable(:, Table.Properties.VariableNames)];
            else
                FullTable = vertcat([FullTable; Table]);
            end
        else
            FullTable = vertcat([FullTable; Table]);
        end
    end

end