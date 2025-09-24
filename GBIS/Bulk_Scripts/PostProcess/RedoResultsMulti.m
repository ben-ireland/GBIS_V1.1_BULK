% Load inv results file and options
clear all; close all;

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/fentale_079D_08094_131313FullTest_Last_DYKE/invert_1_D/invert_1_D/invert_1_D.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/0412Fent_Last_DYKE_FullTest_Last_DYKE_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/erta_ale_014A_07688_131313_079D_07694_131313PreErupt_DykeManual5/invert_1_2_D/invert_1_2_D/invert_1_2_D.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/0403Erta_Last_PreErupt_DykeManual3_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/erta_ale_014A_07688_131313_079D_07694_131313PostErupt_Manual/invert_1_2_M/invert_1_2_M_1/invert_1_2_M_1.mat'...
%    ,'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/erta_ale_014A_07688_131313_079D_07694_131313PostErupt_Manual/invert_1_2_S/invert_1_2_S/invert_1_2_S.mat'...
%    ,'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/erta_ale_014A_07688_131313_079D_07694_131313PostErupt_Manual/invert_1_2_E/invert_1_2_E_1/invert_1_2_E_1.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/0403Erta_Last_PostErupt_Manual_Options.mat');

% OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/erta_ale_014A_07688_131313_079D_07694_131313CoEruptV4/invert_1_2_D_D_D/invert_1_2_D_D_D/invert_1_2_D_D_D.mat'};
% load('/home/jl20461/GBIS_V1.1_BULK/Options/Erta_2802_CoEruptV2_Options.mat');

% OutputFilepaths = {'/local-scratch/Ben/GBIS_V1.1_BULK/Inversion_Results/dabbahu_hararo_079D_07694_131313Dabbahu_CDMsV3/invert_1_B_B_B_B_J/invert_1_B_B_B_B_J/invert_1_B_B_B_B_J.mat'};
% load('/local-scratch/Ben/GBIS_V1.1_BULK/Options/1009_Dabbahu_CDMsV3_Options.mat');

% OutputFilepaths = {'/local-scratch/Ben/GBIS_V1.1_BULK/Inversion_Results/nabro_006D_07728_131313_014A_07688_131313Nabr_CDMs/invert_1_2_M/invert_1_2_M/invert_1_2_M.mat',...
%     '/local-scratch/Ben/GBIS_V1.1_BULK/Inversion_Results/nabro_006D_07728_131313_014A_07688_131313Nabr_CDMs/invert_1_2_O/invert_1_2_O/invert_1_2_O.mat',...
%     '/local-scratch/Ben/GBIS_V1.1_BULK/Inversion_Results/nabro_006D_07728_131313_014A_07688_131313Nabr_CDMs/invert_1_2_L/invert_1_2_L/invert_1_2_L.mat',...
%     '/local-scratch/Ben/GBIS_V1.1_BULK/Inversion_Results/nabro_006D_07728_131313_014A_07688_131313Nabr_CDMs/invert_1_2_K/invert_1_2_K/invert_1_2_K.mat',...
%     '/local-scratch/Ben/GBIS_V1.1_BULK/Inversion_Results/nabro_006D_07728_131313_014A_07688_131313Nabr_CDMs/invert_1_2_J/invert_1_2_J/invert_1_2_J.mat',...
%     '/local-scratch/Ben/GBIS_V1.1_BULK/Inversion_Results/nabro_006D_07728_131313_014A_07688_131313Nabr_CDMs/invert_1_2_I/invert_1_2_I/invert_1_2_I.mat',...
%     '/local-scratch/Ben/GBIS_V1.1_BULK/Inversion_Results/nabro_006D_07728_131313_014A_07688_131313Nabr_CDMs/invert_1_2_B/invert_1_2_B/invert_1_2_B.mat'};
% load('/local-scratch/Ben/GBIS_V1.1_BULK/Options/0909_Nabr_CDMs_Options.mat');

% OutputFilepaths = {'/local-scratch/Ben/GBIS_V1.1_BULK/Inversion_Results/nabro_006D_07728_131313_014A_07688_131313Nabr_CDMs_Spheroid/invert_1_2_M/invert_1_2_M/invert_1_2_M.mat',...
%     '/local-scratch/Ben/GBIS_V1.1_BULK/Inversion_Results/nabro_006D_07728_131313_014A_07688_131313Nabr_CDMs_Spheroid/invert_1_2_L/invert_1_2_L/invert_1_2_L.mat',...
%     '/local-scratch/Ben/GBIS_V1.1_BULK/Inversion_Results/nabro_006D_07728_131313_014A_07688_131313Nabr_CDMs_Spheroid/invert_1_2_O/invert_1_2_O/invert_1_2_O.mat'};
% load('/local-scratch/Ben/GBIS_V1.1_BULK/Options/1209_Nabr_CDMs_Spheroid_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/alu-dalafilla_014A_07688_131313_079D_07694_131313YangTest_LastV5/invert_1_2_Y_Y/invert_1_2_Y_Y/invert_1_2_Y_Y.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/1402Alu_Last_Two_Yang_YangTest_LastV5_Options.mat');

% OutputFilepaths = {'/local-scratch/Ben/GBIS_V1.1_BULK/Inversion_Results/dabbahu_hararo_079D_07694_131313Dabbahu_CDMs/invert_1_M/invert_1_M/invert_1_M.mat',...
%     '/local-scratch/Ben/GBIS_V1.1_BULK/Inversion_Results/dabbahu_hararo_079D_07694_131313Dabbahu_CDMsV6/invert_1_B_B_B_B_J/invert_1_B_B_B_B_J/invert_1_B_B_B_B_J.mat'};
% load('/local-scratch/Ben/GBIS_V1.1_BULK/Options/1209_Dabbahu_CDMsV6_Options.mat');

% OutputFilepaths = {'/local-scratch/Ben/GBIS_V1.1_BULK/Inversion_Results/erta_ale_014A_07688_131313_079D_07694_131313Erta_Co_CDM_Moore/invert_1_2_K_K_K/invert_1_2_K_K_K_1/invert_1_2_K_K_K_1.mat'};
% load('/local-scratch/Ben/GBIS_V1.1_BULK/Options/1009_Erta_Co_CDM_Moore_Options.mat');

% OutputFilepaths = {'/local-scratch/Ben/GBIS_V1.1_BULK/Inversion_Results/erta_ale_014A_07688_131313_079D_07694_131313Erta_Pre_CDM_Manual/invert_1_2_K/invert_1_2_K_1/invert_1_2_K_1.mat'};
% load('/local-scratch/Ben/GBIS_V1.1_BULK/Options/0909_Erta_Pre_CDM_Manual_Options.mat');

OutputFilepaths = {'/local-scratch/Ben/GBIS_V1.1_BULK/Inversion_Results/erta_ale_014A_07688_131313_079D_07694_131313Erta_Post_CDM_Spheroid/invert_1_2_M/invert_1_2_M/invert_1_2_M.mat',...
    '/local-scratch/Ben/GBIS_V1.1_BULK/Inversion_Results/erta_ale_014A_07688_131313_079D_07694_131313Erta_Post_CDM_Spheroid/invert_1_2_L/invert_1_2_L/invert_1_2_L.mat',...
    '/local-scratch/Ben/GBIS_V1.1_BULK/Inversion_Results/erta_ale_014A_07688_131313_079D_07694_131313Erta_Post_CDM_Spheroid/invert_1_2_O/invert_1_2_O/invert_1_2_O.mat'};
load('/local-scratch/Ben/GBIS_V1.1_BULK/Options/1209_Erta_Post_CDM_Spheroid_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/nabro_006D_07728_131313_014A_07688_131313YangTest_Uplift/invert_1_2_M/invert_1_2_M/invert_1_2_M.mat'...
%    '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/nabro_006D_07728_131313_014A_07688_131313YangTest_Uplift/invert_1_2_S/invert_1_2_S/invert_1_2_S.mat'...,
%    '/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/nabro_006D_07728_131313_014A_07688_131313YangTest_Uplift/invert_1_2_Y/invert_1_2_Y/invert_1_2_Y.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/1402_Nabr__YangTest_Uplift_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/alu-dalafilla_014A_07688_131313_079D_07694_131313YangTest_Last/invert_1_2_Y_Y/invert_1_2_Y_Y/invert_1_2_Y_Y.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/1402Alu_Last_Two_Yang_YangTest_Last_Options.mat');

%OutputFilepaths={'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/dabbahu_hararo_079D_07694_1313134Mogi_Sill/invert_1_M_M_M_M_S/invert_1_M_M_M_M_S_1/invert_1_M_M_M_M_S_1.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/0502Dabb__4Mogi_Sill_Options.mat');

%OutputFilepaths={'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/alu-dalafilla_014A_07688_131313_079D_07694_131313SillTest_Last/invert_1_2_S_S/invert_1_2_S_S/invert_1_2_S_S.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/2901Alu_Last_Two_SillTest_SillTest_Last_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/fentale_079D_08094_131313FullTest_Last_DYKE/invert_1_D/invert_1_D/invert_1_D.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/0412Fent_Last_DYKE_FullTest_Last_DYKE_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/alu-dalafilla_014A_07688_131313_079D_07694_131313FullTest_Last_TWO_M_Variogram_V2/invert_1_2_M_M/invert_1_2_M_M/invert_1_2_M_M.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/0412Alu_LastV2_Two_FullTest_LastV2_Two_Options.mat');

%OutputFilepaths = {'/home/jl20461/GBIS_V1.1_BULK/Inversion_Results/erta_ale_014A_07688_131313_079D_07694_131313FullTest_Last_Dyke/invert_1_2_M_D/invert_1_2_M_D/invert_1_2_M_D.mat'};
%load('/home/jl20461/GBIS_V1.1_BULK/Options/0412Erta_Last_Dyke_FullTest_Last_Dyke_Options.mat');

% Set other parameters
%VolcNames = {'nabro_006D_07728_131313','nabro_014A_07688_131313'}; % Multiple if a joint inversion?
%VolcName = {'nabro_006D_07728_131313_014A_07688_131313'};
%VolcName = {'dabbahu_hararo_079D_07694_131313'};
%VolcNames = {'dabbahu_hararo_079D_07694_131313'};
VolcNames = {'erta_ale_014A_07688_131313','erta_ale_079D_07694_131313'};
VolcName = {'erta_ale_014A_07688_131313_079D_07694_131313'};
%VolcNames = {'alu-dalafilla_014A_07688_131313','alu-dalafilla_079D_07694_131313'}; % Multiple if a joint inversion?
%VolcName = {'alu-dalafilla_014A_07688_131313_079D_07694_131313'};
%VolcName = {'fentale_079D_08094_131313'};
%VolcNames = {'fentale_079D_08094_131313'};
%VolcName = {'fentale_079D_08094_131313'};
%VolcNames = {'fentale_079D_08094_131313'};


if matches(VolcName{1},VolcNames{1})
    NumFrames = 1;
else
    NumFrames = 2;
end
FullTable = [];
FullTable = Step9_GenerateReportsTableV2Mult(FullTable,OutputFilepaths,NumFrames,VolcNames,VolcName,Options);
[FullTable, filepath] = Step10_CreateCatalogue(FullTable,Options);
disp(['Table saved to: ',filepath])
%FullTable = Step9_GenerateReportsTable(FullTable,OutputFilepaths,NumFrames,VolcNames,VolcName,Options);
%FullTable = Step9_GenerateReportsTable_MultipleSources(FullTable,OutputFilepaths,NumFrames,VolcNames,VolcName,Options);