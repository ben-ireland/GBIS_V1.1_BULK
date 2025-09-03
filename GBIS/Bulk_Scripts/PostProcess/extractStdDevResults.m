function [LowerResults, UpperResults, Optimal_Results, Mean_Results, Median_Results] = extractStdDevResults(filename,burning,N)
% Ben Ireland, February 2025
% Script to extract standard deviations from GBIS results

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
    StdDev(i) = std(invResults.mKeep(i,burning:end-blankCells));
end

LowerResults = Optimal_Results - (N.*StdDev);
UpperResults = Optimal_Results + (N.*StdDev);