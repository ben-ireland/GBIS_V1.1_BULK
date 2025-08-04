function [Per_25_Results, Per_975_Results, Optimal_Results, Mean_Results, Median_Results] = extractPercentiles(filename,burning)
% Ben Ireland, February 2025
% Script to extract percentiles from GBIS results

load (filename)

if invpar.nRuns < 10000 %Remove blank cells added by GBIS natively in the output files
    blankCells = 999; 
else
    blankCells = 9999;
end

nParam = length(model.parName);

for i = 1:nParam
    Optimal_Results(i) = invResults.model.optimal(i);
    Median_Results(i) = median(invResults.mKeep(i,burning:end-blankCells));
    Mean_Results(i) = mean(invResults.mKeep(i,burning:end-blankCells));
    Per_25_Results(i) = prctile((invResults.mKeep(i,burning:end-blankCells)),2.5);
    Per_975_Results(i) = prctile((invResults.mKeep(i,burning:end-blankCells)),97.5); 
end