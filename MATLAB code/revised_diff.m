%% --- Compare Apex Speeds Between Two MoTeC Logs ---
clear; clc; close all;

%% --- LOAD FIRST LOG ---
[file1, path1] = uigetfile('*.mat', 'Select FIRST MoTeC log (.mat)');
if isequal(file1,0)
    error('No file selected.');
end
load(fullfile(path1, file1));
fprintf('✅ Loaded first log: %s\n', file1);

% Extract key channels
lapDist1 = Lap_Distance.Value(:);
speed1   = Ground_Speed.Value(:);
longG1   = G_Force_Long.Value(:);

%% --- LOAD SECOND LOG ---
[file2, path2] = uigetfile('*.mat', 'Select SECOND MoTeC log (.mat)');
if isequal(file2,0)
    error('No file selected.');
end
load(fullfile(path2, file2));
fprintf('✅ Loaded second log: %s\n', file2);

lapDist2 = Lap_Distance.Value(:);
speed2   = Ground_Speed.Value(:);
longG2   = G_Force_Long.Value(:);

%% --- FIND APEX POINTS ---
% Apex ≈ where longitudinal G crosses zero (transition from braking to accel)
gSign1 = sign(longG1);
apexIdx1 = find(diff(gSign1) > 0);  % braking (neg G) → accel (pos G)
apexSpeeds1 = speed1(apexIdx1);

gSign2 = sign(longG2);
apexIdx2 = find(diff(gSign2) > 0);
apexSpeeds2 = speed2(apexIdx2);

% Match by position (trim to same number of corners)
numCorners = min(length(apexSpeeds1), length(apexSpeeds2));
apexSpeeds1 = apexSpeeds1(1:numCorners);
apexSpeeds2 = apexSpeeds2(1:numCorners);

%% --- CALCULATE DELTAS ---
deltaApex = apexSpeeds2 - apexSpeeds1;  % + means second log faster at apex

%% --- DISPLAY RESULTS ---
fprintf('\n--- Apex Speed Comparison ---\n');
fprintf('Corner | Apex1 [km/h] | Apex2 [km/h] | Δ Speed (2–1)\n');
fprintf('-----------------------------------------------\n');
for i = 1:numCorners
    fprintf(' %2d     |    %7.2f     |    %7.2f     |   %+6.2f\n', ...
        i, apexSpeeds1(i), apexSpeeds2(i), deltaApex(i));
end
fprintf('-----------------------------------------------\n');
fprintf('Mean Δ Apex Speed: %+6.2f km/h\n', mean(deltaApex));

%% --- PLOTS ---
figure('Name','Apex Speed Comparison','NumberTitle','off','Position',[100 100 900 600]);
hold on; grid on;
bar(1:numCorners, deltaApex, 'FaceColor', [0.2 0.6 1]);
yline(0, 'k--');
xlabel('Corner #');
ylabel('Δ Apex Speed [km/h]');
title('Apex Speed Delta (Second Run – First Run)');
for i = 1:numCorners
    if deltaApex(i) < 0
        bar(i, deltaApex(i), 'FaceColor', [1 0.3 0.3]); % red if slower
    else
        bar(i, deltaApex(i), 'FaceColor', [0.3 0.9 0.3]); % green if faster
    end
end
legend('Δ Apex Speed', 'Location', 'best');
hold off;

fprintf('\n✅ Comparison complete.\n');
