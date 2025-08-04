function [AspectRatio, Options] = ExtractSignalShape(invResFile,Options)
    
    load(invResFile);

    % Do volume and aspect ratio for sills
    for k = 1:length(invpar.model)
        if contains(invpar.model{k},'SILL') || contains(invpar.model{k},'DIKE') || contains(invpar.model{k},'FAUL')
            ModelParams = invResults.model.optimal(invResults.model.mIx(k):invResults.model.mIx(k+1)-1);
            Parameters = model.parName((invResults.model.mIx(k):invResults.model.mIx(k+1)-1));

            pIdxL = find(contains(Parameters,'Length'),1,'first');
            pIdxW = find(contains(Parameters,'Width'),1,'first');
            
            % Calculate aspect ratio
            AspectRatio(k) = max(ModelParams(pIdxL),ModelParams(pIdxW))./min(ModelParams(pIdxL),ModelParams(pIdxW));

            % Change strike if width>length
            if invResults.optimalmodel{k}(pIdxW)>invResults.optimalmodel{k}(pIdxL)
                Options.ModifyStrike(k)=1;
            else
                Options.ModifyStrike(k)=0;
            end
        else
            Options.ModifyStrike(k)=0;
            AspectRatio(k)=1;
        end
    end
