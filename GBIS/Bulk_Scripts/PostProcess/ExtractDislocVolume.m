function [LowVol, UpVol, OptVol, MeanVol, MedianVol] = ExtractDislocVolume(filename,burning,ModIdxRange)
% Ben Ireland, February 2025
% Script to extract sill volumes from GBIS results

load (filename)

if invpar.nRuns < 10000 %Remove blank cells added by GBIS natively in the output files
    blankCells = 999; 
else
    blankCells = 9999;
end

ParNames = model.parName(ModIdxRange);
pIdxL = find(contains(ParNames,'Length'));
pIdxW = find(contains(ParNames,'Width'));
pIdxO = find(contains(ParNames,'Opening'));

ModResults = invResults.mKeep(ModIdxRange,burning:end-blankCells);
OptModResults = invResults.model.optimal(ModIdxRange);

OptVol = OptModResults(pIdxL).*OptModResults(pIdxW).*OptModResults(pIdxO);
AllVolume = ModResults(pIdxL,:).*ModResults(pIdxW,:).*ModResults(pIdxO,:);
MeanVol = mean(AllVolume);
MedianVol = median(AllVolume);
LowVol = prctile(AllVolume,2.5);
UpVol = prctile(AllVolume,97.5);

end