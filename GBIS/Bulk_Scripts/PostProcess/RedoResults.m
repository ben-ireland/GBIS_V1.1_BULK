clear all;close all

% Load inv results file and options
%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/olkaria_130A_09032_111110_152D_09114_131313Yang_Test_Last/invert_1_2_Y/invert_1_2_Y_1/invert_1_2_Y_1.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/1402_Olka__Yang_Test_Last_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/dallol_014A_07524_101303_079D_07502_111213Yang_Test_LastV3/invert_1_2_Y/invert_1_2_Y/invert_1_2_Y.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/1202Dall__Yang_Test_LastV3_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/gada_ale_014A_07688_131313_079D_07502_111213Yang_Test_LastV2/invert_1_2_Y/invert_1_2_Y_1/invert_1_2_Y_1.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/1302_Gada__Yang_Test_LastV2_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/suswa_130A_09212_131313_152D_09114_131313Yang_Test_Last/invert_1_2_Y/invert_1_2_Y_1/invert_1_2_Y_1.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/1402_Susw_Yang_Test_Last_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/nabro_006D_07728_131313_014A_07688_131313SillTest_Uplift/invert_1_2_M/invert_1_2_M/invert_1_2_M.mat',...
%    '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/nabro_006D_07728_131313_014A_07688_131313SillTest_Uplift/invert_1_2_S/invert_1_2_S/invert_1_2_S.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/2901_Nabr_Sill_Uplift_SillTest_Uplift_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/nabro_006D_07728_131313_014A_07688_131313SillTest_Flows/invert_1_2_M/invert_1_2_M/invert_1_2_M.mat',...
%    '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/nabro_006D_07728_131313_014A_07688_131313SillTest_Flows/invert_1_2_S/invert_1_2_S/invert_1_2_S.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/2901_Nabr_Sill_Flows_SillTest_Flows_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/tullu_moje_079D_08094_131313Sill_Test_LastV2/invert_1_M/invert_1_M/invert_1_M.mat',...
%    '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/tullu_moje_079D_08094_131313Sill_Test_LastV2/invert_1_S/invert_1_S/invert_1_S.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/2901_Tullu_Sill_Test_LastV2_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/suswa_130A_09212_131313_152D_09114_131313Sill_Test_Last/invert_1_2_M/invert_1_2_M/invert_1_2_M.mat',...
%    '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/suswa_130A_09212_131313_152D_09114_131313Sill_Test_Last/invert_1_2_S/invert_1_2_S/invert_1_2_S.mat',...
%    '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/suswa_130A_09212_131313_152D_09114_131313Sill_Test_Last/invert_1_2_V/invert_1_2_V/invert_1_2_V.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/2901_Susw_Sill_Test_Sill_Test_Last_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/silali_152D_08915_131313Sill_Test_LastV2/invert_1_M/invert_1_M/invert_1_M.mat',...
%    '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/silali_152D_08915_131313Sill_Test_LastV2/invert_1_S/invert_1_S/invert_1_S.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/2901_Sila_Sill_Test_Sill_Test_LastV2_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/paka_152D_08915_131313Sill_Test_LastV2/invert_1_M/invert_1_M/invert_1_M.mat',...
%    '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/paka_152D_08915_131313Sill_Test_LastV2/invert_1_S/invert_1_S/invert_1_S.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/2901_Paka_Sill_Test_Sill_Test_LastV2_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/olkaria_130A_09032_111110_152D_09114_131313Sill_Test_Last/invert_1_2_M/invert_1_2_M/invert_1_2_M.mat',...
%    '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/olkaria_130A_09032_111110_152D_09114_131313Sill_Test_Last/invert_1_2_S/invert_1_2_S/invert_1_2_S.mat',...
%    '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/olkaria_130A_09032_111110_152D_09114_131313Sill_Test_Last/invert_1_2_V/invert_1_2_V/invert_1_2_V.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/2901_Olka_Sill_Test_Last_Sill_Test_Last_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/kone_079D_08094_131313Sill_Test/invert_1_M/invert_1_M_2/invert_1_M_2.mat',...
%    '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/kone_079D_08094_131313Sill_Test/invert_1_S/invert_1_S/invert_1_S.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/2901Kone_Sill_Test_Sill_Test_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/hertali_079D_08094_131313Sill_Test_Last/invert_1_M/invert_1_M_2/invert_1_M_2.mat',...
%    '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/hertali_079D_08094_131313Sill_Test_Last/invert_1_S/invert_1_S/invert_1_S.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/2901_Hert_Sill_Test_Sill_Test_Last_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/gada_ale_014A_07688_131313_079D_07502_111213Sill_Test_V2/invert_1_2_M/invert_1_2_M/invert_1_2_M.mat',...
%    '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/gada_ale_014A_07688_131313_079D_07502_111213Sill_Test_V2/invert_1_2_S/invert_1_2_S/invert_1_2_S.mat'...,
%    '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/gada_ale_014A_07688_131313_079D_07502_111213Sill_Test_V2/invert_1_2_V/invert_1_2_V/invert_1_2_V.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/2901_Gada__Sill_Test_V2_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/fentale_079D_08094_131313Sill_Test_LastV3/invert_1_M/invert_1_M/invert_1_M.mat',...
%    '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/fentale_079D_08094_131313Sill_Test_LastV3/invert_1_S/invert_1_S/invert_1_S.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/2901_Fent_Sill_LastV3_Sill_Test_LastV3_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/dallol_014A_07524_101303_079D_07502_111213Sill_Test_Last/invert_1_2_M/invert_1_2_M/invert_1_2_M.mat',...
%    '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/dallol_014A_07524_101303_079D_07502_111213Sill_Test_Last/invert_1_2_S/invert_1_2_S/invert_1_2_S.mat',...
%    '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/dallol_014A_07524_101303_079D_07502_111213Sill_Test_Last/invert_1_2_V/invert_1_2_V/invert_1_2_V.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/2901Dall_Sill_Last_Sill_Test_Last_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/dallol_014A_07524_101303_079D_07502_111213Sill_Test_Last/invert_1_2_S/invert_1_2_S/invert_1_2_S.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/2901Dall_Sill_Last_Sill_Test_Last_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/erta_ale_014A_07688_131313_079D_07694_131313Sill_Test_Last/invert_1_2_M/invert_1_2_M/invert_1_2_M.mat',...
%    '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/erta_ale_014A_07688_131313_079D_07694_131313Sill_Test_Last/invert_1_2_S/invert_1_2_S/invert_1_2_S.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/2901Erta_Sill_Last_Sill_Test_Last_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/dabbahu_hararo_079D_07694_131313Sill_Last/invert_1_M/invert_1_M_2/invert_1_M_2.mat',...
%    '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/dabbahu_hararo_079D_07694_131313Sill_Last/invert_1_S/invert_1_S/invert_1_S.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/2901Dabb_Last_Sill_Last_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/corbetti_079D_08294_131313SillTest_Last/invert_1_M/invert_1_M_2/invert_1_M_2.mat',...
%    '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/corbetti_079D_08294_131313SillTest_Last/invert_1_S/invert_1_S/invert_1_S.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/2901Corb_Sill_Last_SillTest_Last_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/alutu_079D_08294_131313SillTest_Last/invert_1_M/invert_1_M_3/invert_1_M_3.mat',...
%                '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/alutu_079D_08294_131313SillTest_Last/invert_1_S/invert_1_S_1/invert_1_S_1.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/2901Alutu_Sill_Last_SillTest_Last_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/olkaria_130A_09032_111110_152D_09114_131313Sill_Test_Last/invert_1_2_M/invert_1_2_M/invert_1_2_M.mat',...
%    '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/olkaria_130A_09032_111110_152D_09114_131313Sill_Test_Last/invert_1_2_S/invert_1_2_S/invert_1_2_S.mat',...
%    '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/olkaria_130A_09032_111110_152D_09114_131313Sill_Test_Last/invert_1_2_V/invert_1_2_V/invert_1_2_V.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/2901_Olka_Sill_Test_Last_Sill_Test_Last_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/suswa_130A_09212_131313_152D_09114_131313Sill_Test_Last/invert_1_2_M/invert_1_2_M/invert_1_2_M.mat',...
%                '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/suswa_130A_09212_131313_152D_09114_131313Sill_Test_Last/invert_1_2_S/invert_1_2_S/invert_1_2_S.mat',...
%                '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/suswa_130A_09212_131313_152D_09114_131313Sill_Test_Last/invert_1_2_V/invert_1_2_V/invert_1_2_V.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/0412Susw_Last_FullTest_Last_Options.mat');

%OutputFilepaths = {'/scratch/Ben/GBIS_BULK/Inversion_Results/suswa_130A_09212_131313_152D_09114_131313CDM_Test/invert_1_2_M/invert_1_2_M/invert_1_2_M.mat',...
%'/scratch/Ben/GBIS_BULK/Inversion_Results/suswa_130A_09212_131313_152D_09114_131313CDM_Test/invert_1_2_A/invert_1_2_A_1/invert_1_2_A_1.mat'};
%load('/scratch/Ben/GBIS_BULK/Options/1006_CDM_Test_Options.mat');

% OutputFilepaths = {'/scratch/Ben/GBIS_BULK/Inversion_Results/dallol_014A_07524_101303_079D_07502_111213CDMsTest_DallolLastOffset/invert_1_2_M/invert_1_2_M/invert_1_2_M.mat',...
%     '/scratch/Ben/GBIS_BULK/Inversion_Results/dallol_014A_07524_101303_079D_07502_111213CDMsTest_DallolLastOffset/invert_1_2_B/invert_1_2_B/invert_1_2_B.mat',...
%     '/scratch/Ben/GBIS_BULK/Inversion_Results/dallol_014A_07524_101303_079D_07502_111213CDMsTest_DallolLastOffset/invert_1_2_I/invert_1_2_I/invert_1_2_I.mat',....
%     '/scratch/Ben/GBIS_BULK/Inversion_Results/dallol_014A_07524_101303_079D_07502_111213CDMsTest_DallolLastOffset/invert_1_2_J/invert_1_2_J/invert_1_2_J.mat',...
%     '/scratch/Ben/GBIS_BULK/Inversion_Results/dallol_014A_07524_101303_079D_07502_111213CDMsTest_DallolLastOffset/invert_1_2_K/invert_1_2_K/invert_1_2_K.mat',...
%     '/scratch/Ben/GBIS_BULK/Inversion_Results/dallol_014A_07524_101303_079D_07502_111213CDMsTest_DallolLastOffset/invert_1_2_L/invert_1_2_L/invert_1_2_L.mat',...
%     '/scratch/Ben/GBIS_BULK/Inversion_Results/dallol_014A_07524_101303_079D_07502_111213CDMsTest_DallolLastOffset/invert_1_2_O/invert_1_2_O/invert_1_2_O.mat'};
% load('/scratch/Ben/GBIS_BULK/Options/2207_CDMsTest_DallolLastOffset_Options.mat');

OutputFilepaths = {'/scratch/Ben/GBIS_BULK/Inversion_Results/alu-dalafilla_014A_07688_131313_079D_07694_131313ExtraMaskingTest/invert_1_2_M/invert_1_2_M_1/invert_1_2_M_1.mat'};
load('/scratch/Ben/GBIS_BULK/Options/2907_ExtraMaskingTest_Options.mat');


% Set other parameters
FullTable = [];
% SINGLE FRAME
%VolcNames = {'alutu_079D_08294_131313'};
%VolcName = {'alutu_079D_08294_131313'};
%VolcName = {'corbetti_079D_08294_131313'};
%VolcNames = {'corbetti_079D_08294_131313'};
%VolcName = {'dabbahu_hararo_079D_07694_131313'};
%VolcNames = {'dabbahu_hararo_079D_07694_131313'};
%VolcName = {'fentale_079D_08094_131313'};
%VolcNames = {'fentale_079D_08094_131313'};
%VolcName = {'hertali_079D_08094_131313'};
%VolcNames = {'hertali_079D_08094_131313'};
%VolcName = {'kone_079D_08094_131313'};
%VolcNames = {'kone_079D_08094_131313'};
%VolcName = {'paka_152D_08915_131313'};
%VolcNames = {'paka_152D_08915_131313'};
%VolcName = {'silali_152D_08915_131313'};
%VolcNames = {'silali_152D_08915_131313'};
%VolcName = {'tullu_moje_079D_08094_131313'};
%VolcNames = {'tullu_moje_079D_08094_131313'};

% TWO FRAMES
VolcNames = {'alu-dalafilla_014A_07688_131313','alu-dalafilla_079D_07694_131313'};
VolcName = {'alu-dalafilla_014A_07688_131313_079D_07694_131313'};
%VolcNames = {'nabro_006D_07728_131313','nabro_014A_07688_131313'}; % Multiple if a joint inversion?
%VolcName = {'nabro_006D_07728_131313_014A_07688_131313'};
%VolcNames = {'suswa_130A_09212_131313','suswa_152D_09114_131313'}; % Multiple if a joint inversion?
%VolcName = {'suswa_130A_09212_131313_152D_09114_131313'};
%VolcNames = {'olkaria_130A_09032_111110','olkaria_152D_09114_131313'}; % Multiple if a joint inversion?
%VolcName = {'olkaria_130A_09032_111110_152D_09114_131313'};
%VolcNames = {'gada_ale_014A_07688_131313','gada_ale_079D_07502_111213'}; % Multiple if a joint inversion?
%VolcName = {'gada_ale_014A_07688_131313_079D_07502_111213'};
%VolcNames = {'dallol_014A_07524_101303','dallol_079D_07502_111213'}; % Multiple if a joint inversion?
%VolcName = {'dallol_014A_07524_101303_079D_07502_111213'};
%VolcNames = {'erta_ale_014A_07688_131313','erta_ale_079D_07694_131313'};
%VolcName = {'erta_ale_014A_07688_131313_079D_07694_131313'};

if matches(VolcName{1},VolcNames{1})
    NumFrames = 1;
else
    NumFrames = 2;
end
%FullTable = Step9_GenerateReportsTable(FullTable,OutputFilepaths,NumFrames,VolcNames,VolcName,Options);
FullTable = Step9_GenerateReportsTableV2(FullTable,OutputFilepaths,NumFrames,VolcNames,VolcName,Options);
[FullTable, filepath] = Step10_CreateCatalogue(FullTable,Options);

disp('Table filepath:')
disp(filepath)
%FullTable = Step9_GenerateReportsTable_MultipleSources(FullTable,OutputFilepaths,NumFrames,VolcNames,VolcName,Options);