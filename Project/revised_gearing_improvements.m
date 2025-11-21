%% --- Compare Two MoTeC Logs: Long G & Speed with Color-Coded Zones ---
clear; clc; close all;

%% --- LOAD FILES ---
disp('Select baseline (before gear change) log:');
[file1, path1] = uigetfile('*.mat');
if isequal(file1,0), error('No file selected.'); end
load(fullfile(path1, file1));
log1.longG = G_Force_Long.Value(:);
log1.speed = Ground_Speed.Value(:);
log1.dist  = Lap_Distance.Value(:);

disp('Select new (after gear change) log:');
[file2, path2] = uigetfile('*.mat');
if isequal(file2,0), error('No file selected.'); end
load(fullfile(path2, file2));
log2.longG = G_Force_Long.Value(:);
log2.speed = Ground_Speed.Value(:);
log2.dist  = Lap_Distance.Value(:);

%% --- DEFINE ANALYSIS ZONES (in meters) ---
zones = [
    584 1282;
    1488 1576;
    1690 2100;
    2264 2352;
    2455 2532;
    2636 2811;
    2936 3018;   % ✅ corrected zone 7
    3116 3520;
    3804 4057;
    4186 4269;
    4336 4806;
    4956 5396
];
nZones = size(zones,1);

%% --- INTERPOLATE BOTH FILES TO COMMON DISTANCE VECTOR ---
maxDist = min(max(log1.dist), max(log2.dist));
dist_common = linspace(0, maxDist, 20000);

longG1 = interp1(log1.dist, log1.longG, dist_common, 'linear', 'extrap');
longG2 = interp1(log2.dist, log2.longG, dist_common, 'linear', 'extrap');
speed1 = interp1(log1.dist, log1.speed, dist_common, 'linear', 'extrap');
speed2 = interp1(log2.dist, log2.speed, dist_common, 'linear', 'extrap');

%% --- COMPUTE ZONE DELTAS ---
zoneDelta = zeros(nZones,2); % [ΔLongG, ΔSpeed]
for i = 1:nZones
    d1 = zones(i,1); d2 = zones(i,2);
    idx = dist_common >= d1 & dist_common <= d2;
    if sum(idx) < 10, continue; end
    zoneDelta(i,1) = mean(longG2(idx)) - mean(longG1(idx));
    zoneDelta(i,2) = mean(speed2(idx)) - mean(speed1(idx));
end

%% --- CREATE COLOR FUNCTION ---
getColor = @(delta) (delta >= 0) * [0.2 0.8 0.2] + (delta < 0) * [0.9 0.3 0.3];

%% --- CREATE PLOTS ---
figure('Name','Gear Ratio Comparison (Color-Coded Zones)','NumberTitle','off','Position',[100 100 1200 800]);

% --- SPEED OVERLAY ---
subplot(2,1,1);
hold on; grid on;
for i = 1:nZones
    d1 = zones(i,1); d2 = zones(i,2);
    c = getColor(zoneDelta(i,2)); % green/red by Δspeed
    xpatch = [d1, d2, d2, d1];
    ypatch = [0, 0, max([speed1 speed2]), max([speed1 speed2])];
    patch(xpatch, ypatch, c, 'FaceAlpha', 0.25, 'EdgeColor', 'none');
end
plot(dist_common, speed1, 'r', 'LineWidth', 1.2);
plot(dist_common, speed2, 'b', 'LineWidth', 1.2);
xlabel('Distance [m]');
ylabel('Corrected Speed [km/h]');
legend('Before Gearing', 'After Gearing', 'Location', 'best');
title('Speed Comparison (Green = Gain, Red = Loss)');

% --- LONG G OVERLAY ---
subplot(2,1,2);
hold on; grid on;
for i = 1:nZones
    d1 = zones(i,1); d2 = zones(i,2);
    c = getColor(zoneDelta(i,2)); % same color as speed improvement
    xpatch = [d1, d2, d2, d1];
    ypatch = [min([longG1 longG2]), min([longG1 longG2]), max([longG1 longG2]), max([longG1 longG2])];
    patch(xpatch, ypatch, c, 'FaceAlpha', 0.25, 'EdgeColor', 'none');
end
plot(dist_common, longG1, 'r', 'LineWidth', 1.2);
plot(dist_common, longG2, 'b', 'LineWidth', 1.2);
xlabel('Distance [m]');
ylabel('Longitudinal G [g]');
legend('Before Gearing', 'After Gearing', 'Location', 'best');
title('Longitudinal G Comparison (Green = Gain, Red = Loss)');

%% --- PRINT DELTAS ---
fprintf('\n--- Mean Deltas per Zone ---\n');
fprintf('%5s | %12s | %12s\n', 'Zone', 'Δ LongG (mean)', 'Δ Speed (mean)');
fprintf('----------------------------------------\n');
for i = 1:nZones
    if zoneDelta(i,2) == 0, continue; end
    fprintf('%5d | %+12.4f | %+12.3f\n', i, zoneDelta(i,1), zoneDelta(i,2));
end
fprintf('----------------------------------------\n');
fprintf('🟩 Positive = improved accel/speed | 🟥 Negative = performance loss\n');
