function [FullTable, filepath] = Step10_CreateCatalogue(FullTable,Options)
    if ~exist([pwd,'/Deformation_Catalogues'],'dir')
        mkdir(pwd,'Deformation_Catalogues')
        addpath([pwd,'/Deformation_Catalogues'])
    end
    disp('Saving bulk deformation catalogue')

    % Round numeric values in Full Table to 5sf
    if Options.TableRoundValues>0
        excludeCols = {'DispRateM', 'RMSE'};
        FullTable2 = varfun(@(x) round(x, Options.TableRoundValues, "significant"), FullTable, 'InputVariables', @isnumeric);
        areNumeric = varfun(@isnumeric, FullTable, 'OutputFormat', 'uniform');
        colsToRound = areNumeric & ~ismember(FullTable.Properties.VariableNames, excludeCols);
        FullTable(:, colsToRound) = varfun(@(x) round(x, Options.TableRoundValues, "significant"), FullTable, 'InputVariables', find(colsToRound));
    end

    filepath = [pwd,'/Deformation_Catalogues/',Options.BulkRunID,'_',Options.RunID,'New.csv'];

    if Options.TableOverwrite==1
        writetable(FullTable,[pwd,'/Deformation_Catalogues/',Options.BulkRunID,'_',Options.RunID,'New.csv']);
    elseif Options.TableOverwrite==0
        n=1;
        newfilepath = filepath;
        newfilepath2 = [pwd,'/Deformation_Catalogues/',Options.BulkRunID,'_',Options.RunID,'New',num2str(n),'.csv'];

        while exist(newfilepath) ==2 || exist(newfilepath2) ==2
            n=n+1;
            newfilepath = [pwd,'/Deformation_Catalogues/',Options.BulkRunID,'_',Options.RunID,'New',num2str(n),'.csv'];
            newfilepath2 = newfilepath;
        end
        writetable(FullTable,[pwd,'/Deformation_Catalogues/',Options.BulkRunID,'_',Options.RunID,'New',num2str(n),'.csv']);
        filepath = [pwd,'/Deformation_Catalogues/',Options.BulkRunID,'_',Options.RunID,'New',num2str(n),'.csv'];
    end
        
end