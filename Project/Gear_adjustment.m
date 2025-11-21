%% --- Viper Gearing Efficiency Analysis (Powerband-Based, Auto Gear Ratio Suggestion) ---
% Detects braking zones, checks RPM vs powerband, and suggests revised gear ratios.
clear; clc; close all;

%% --- LOAD DATA ---
[file, path] = uigetfile('*.mat', 'Select your MoTeC .mat log file');
if isequal(file,0)
    error('No file selected.');
end
load(fullfile(path, file));
fprintf('✅ Loaded %s\n', file);

%% --- MAP SIGNALS (adjust if variable names differ) ---
t        = Running_Lap_Time.Time(:);
speed    = Ground_Speed.Value(:);    % [kph]
rpm      = Engine_RPM.Value(:);
throttle = Throttle_Pos.Value(:);
latG     = G_Force_Lat.Value(:);
longG    = G_Force_Long.Value(:);
damperFL = Damper_Pos_FL.Value(:);
damperFR = Damper_Pos_FR.Value(:);
damperRL = Damper_Pos_RL.Value(:);
damperRR = Damper_Pos_RR.Value(:);
tyreFL_in  = Tyre_Temp_FL_Inner.Value(:);
tyreFL_mid = Tyre_Temp_FL_Centre.Value(:);
tyreFL_out = Tyre_Temp_FL_Outer.Value(:);
tyreFR_in  = Tyre_Temp_FR_Inner.Value(:);
tyreFR_mid = Tyre_Temp_FR_Centre.Value(:);
tyreFR_out = Tyre_Temp_FR_Outer.Value(:);

%% --- PARAMETERS ---
redline = 6500;             % rpm
moderateThresh = 5150;      % moderate gearing inefficiency
severeThresh = 4800;        % severe gearing inefficiency
brakeG_threshold = -0.8;    % g threshold for braking
brake_min_separation = 0.5; % seconds (debounce)
cluster_time_s = 2.0;       % cluster braking detections within 2s
preBrakeOffset_s = 0.05;    % sample RPM/speed 50 ms before braking

gear_ratios = [8.509, 5.496, 4.395, 3.707, 3.273, 2.865];  % nominal
gear_top_kph = [100, 154, 190, 223, 251, 290];             % top speeds [kph]

%% --- BRAKING ZONE DETECTION (with 2s clustering filter) ---
isBraking = longG <= brakeG_threshold;
fs_est = 1/median(diff(t));
min_sep_samples = max(1, round(brake_min_separation * fs_est));
edges = find(diff([0; isBraking]) == 1);

cluster_samples = round(cluster_time_s * fs_est);
filtered_edges = [];
lastEdge = -inf;
for i = 1:length(edges)
    if edges(i) - lastEdge > cluster_samples
        filtered_edges(end+1) = edges(i); %#ok<AGROW>
        lastEdge = edges(i);
    end
end
brake_start_idx = filtered_edges;

%% --- SAMPLE PRE-BRAKE SPEEDS & RPMs ---
preBrakeSpeeds = [];
preBrakeRPMs = [];
preBrakeTimes = [];
for i = 1:length(brake_start_idx)
    idx = brake_start_idx(i);
    offset_samples = round(preBrakeOffset_s * fs_est);
    sample_idx = max(1, idx - offset_samples);
    preBrakeSpeeds(end+1) = speed(sample_idx); %#ok<AGROW>
    preBrakeRPMs(end+1) = rpm(sample_idx); %#ok<AGROW>
    preBrakeTimes(end+1) = t(sample_idx); %#ok<AGROW>
end
nEvents = numel(preBrakeSpeeds);

%% --- ASSIGN GEARS BASED ON SPEED RANGE ---
assignedGear = zeros(nEvents,1);
for i=1:nEvents
    v = preBrakeSpeeds(i);
    gidx = find(v <= gear_top_kph, 1, 'first');
    if isempty(gidx), gidx = numel(gear_top_kph); end
    assignedGear(i) = gidx;
end

%% --- COMPUTE SUGGESTED RATIOS (DATA-BASED) ---
suggested_ratios = gear_ratios;
gear_events = cell(6,1);
for g=1:6
    idxs = find(assignedGear == g);
    gear_events{g} = preBrakeSpeeds(idxs);
    if ~isempty(idxs)
        V_target = median(preBrakeSpeeds(idxs)); % typical pre-brake speed
        V_current_top = gear_top_kph(g);
        suggested_ratios(g) = gear_ratios(g) * (V_current_top / V_target);
    end
end

%% --- POWERBAND-BASED INEFFICIENCY DETECTION ---
moderateIdx = find(rpm < moderateThresh & throttle > 50 & speed > 20);
severeIdx   = find(rpm < severeThresh & throttle > 50 & speed > 20);

%% --- OUTPUT SUMMARY ---
fprintf('\n--- GEARING EFFICIENCY ANALYSIS ---\n');
fprintf('Detected %d braking events after clustering (threshold %.2f g)\n', nEvents, brakeG_threshold);

% Print a few pre-brake samples
for i=1:min(10,nEvents)
    fprintf(' - t=%.2fs: %.1f kph, %.0f rpm, gear=%d\n', preBrakeTimes(i), preBrakeSpeeds(i), preBrakeRPMs(i), assignedGear(i));
end

% Flag RPM inefficiency
fprintf('\nPowerband inefficiency (throttle>50%%, speed>20kph):\n');
fprintf('⚠️ Moderate (<%.0f rpm): %d samples\n', moderateThresh, numel(moderateIdx));
fprintf('🚨 Severe (<%.0f rpm): %d samples\n', severeThresh, numel(severeIdx));

% Gear ratio suggestions
fprintf('\nSuggested Gear Ratios (data-based):\n');
fprintf('Gear | Old Ratio | TopSpeed(kph) | Median PreBrake(kph) | Suggested Ratio\n');
for g=1:6
    medV = median(gear_events{g});
    if isempty(medV), medV = NaN; end
    fprintf('%4d | %9.4f | %12.1f | %20.1f | %14.4f\n', g, gear_ratios(g), gear_top_kph(g), medV, suggested_ratios(g));
end

fprintf('\n--- Analysis complete. ---\n');

%% --- PLOTS ---

figure('Name','Speed & RPM Overview','NumberTitle','off');
subplot(3,1,1);
plot(t, speed, 'b'); hold on;
scatter(preBrakeTimes, preBrakeSpeeds, 30, 'r', 'filled');
xlabel('Time [s]'); ylabel('Speed [kph]'); grid on;
title('Speed with Braking Entry Markers');

subplot(3,1,2);
plot(t, rpm, 'k'); hold on; grid on;
yline(moderateThresh,'y--','Moderate Limit');
yline(severeThresh,'r--','Severe Limit');
xlabel('Time [s]'); ylabel('Engine RPM');
title('RPM with Powerband Limits');

subplot(3,1,3);
plot(t, throttle, 'g'); hold on;
plot(t, latG, 'b'); plot(t, longG, 'r');
legend('Throttle','Lat G','Long G');
xlabel('Time [s]'); ylabel('Value');
grid on; title('Throttle & G Forces');

figure('Name','Gear Ratios: Current vs Suggested','NumberTitle','off');
barData = [gear_ratios; suggested_ratios]';
bar(barData); grid on;
xticks(1:6); xticklabels({'1','2','3','4','5','6'});
xlabel('Gear'); ylabel('Gear Ratio');
legend('Current','Suggested');
title('Current vs Suggested Gear Ratios');

%% --- SAVE PLOTS ---
outdir = fullfile(pwd,'plots','GearingAnalysis');
if ~exist(outdir,'dir'), mkdir(outdir,'s'); end
figs = findall(0,'Type','figure');
for k=1:length(figs)
    f = figs(k);
    fname = sprintf('Fig_%s.png', strrep(f.Name,' ','_'));
    saveas(f, fullfile(outdir, fname));
end
fprintf('Saved plots to %s\n', outdir);
