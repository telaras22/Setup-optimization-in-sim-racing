%% --- Compare Ride-Height Difference Between Two Logs (Sample-by-Sample) ---
clear; clc; close all;

%% --- Load File 1 ---
[file1, path1] = uigetfile('*.mat', 'Select FIRST MoTeC .mat file');
if isequal(file1,0), error('No first file selected.'); end
data1 = load(fullfile(path1, file1));

%% --- Load File 2 ---
[file2, path2] = uigetfile('*.mat', 'Select SECOND MoTeC .mat file');
if isequal(file2,0), error('No second file selected.'); end
data2 = load(fullfile(path2, file2));

%% --- CHANGE THESE IF YOUR VARIABLE NAMES DIFFER ---
getSignals = @(D) struct( ...
    'latG', D.G_Force_Lat.Value(:), ...
    'FL',   D.Ride_Height_FL.Value(:), ...
    'FR',   D.Ride_Height_FR.Value(:), ...
    'RL',   D.Ride_Height_RL.Value(:), ...
    'RR',   D.Ride_Height_RR.Value(:) );

S1 = getSignals(data1);
S2 = getSignals(data2);

%% --- Parameters ---
latG_threshold = 1.0;   % Only samples where |latG| > 1g

%% --- Compute sample-by-sample differences ---
function [frontDiff, rearDiff] = calcDiff(S, latG_threshold)

    idx = find(abs(S.latG) > latG_threshold);  % indices of interest

    % Absolute L - R differences
    frontDiff = abs(S.FL(idx) - S.FR(idx));
    rearDiff  = abs(S.RL(idx) - S.RR(idx));
end

[F1, R1] = calcDiff(S1, latG_threshold);
[F2, R2] = calcDiff(S2, latG_threshold);

%% --- PLOTS ---

% FRONT RIDE HEIGHT DIFF
figure('Name','Front Ride Height Difference');
hold on; grid on;
plot(F1, 'b.-', 'LineWidth', 1.2, 'MarkerSize', 12);
plot(F2, 'r.-', 'LineWidth', 1.2, 'MarkerSize', 12);
xlabel('Sample Count (only |latG| > 1)'); 
ylabel('|FL - FR| (mm)');
title('Front Ride Height Difference (High Lateral G Samples)');
legend(file1, file2);

% REAR RIDE HEIGHT DIFF
figure('Name','Rear Ride Height Difference');
hold on; grid on;
plot(R1, 'b.-', 'LineWidth', 1.2, 'MarkerSize', 12);
plot(R2, 'r.-', 'LineWidth', 1.2, 'MarkerSize', 12);
xlabel('Sample Count (only |latG| > 1)');
ylabel('|RL - RR| (mm)');
title('Rear Ride Height Difference (High Lateral G Samples)');
legend(file1, file2);
