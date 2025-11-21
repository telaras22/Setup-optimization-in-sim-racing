%% Simple tyre-temperature comparison between two MoTeC .mat logs
clear; clc;

%% --- Load files ---
[file1, path1] = uigetfile('*.mat', 'Select FIRST log');
if isequal(file1,0), error('No file selected'); end
D1 = load(fullfile(path1,file1));

[file2, path2] = uigetfile('*.mat', 'Select SECOND log');
if isequal(file2,0), error('No file selected'); end
D2 = load(fullfile(path2,file2));

fprintf('Loaded:\n 1) %s\n 2) %s\n', file1, file2);

%% --- Helper to extract .Value array ---
val = @(S) double(S.Value(:));

%% --- REQUIRED: you must edit these two lines to match your log names ---
lat1  = val(D1.G_Force_Lat);     long1 = val(D1.G_Force_Long);
lat2  = val(D2.G_Force_Lat);     long2 = val(D2.G_Force_Long);

%% --- High-load mask (|lat|>1 OR |long|>1) ---
mask1 = (abs(lat1)>1) | (abs(long1)>1);
mask2 = (abs(lat2)>1) | (abs(long2)>1);

%% --- Extract tyre temps for each log ---
extractTemps = @(D) struct( ...
    'FL_in',  val(D.Tyre_Temp_FL_Inner),  'FL_mid', val(D.Tyre_Temp_FL_Centre), 'FL_out', val(D.Tyre_Temp_FL_Outer), ...
    'FR_in',  val(D.Tyre_Temp_FR_Inner),  'FR_mid', val(D.Tyre_Temp_FR_Centre), 'FR_out', val(D.Tyre_Temp_FR_Outer), ...
    'RL_in',  val(D.Tyre_Temp_RL_Inner),  'RL_mid', val(D.Tyre_Temp_RL_Centre), 'RL_out', val(D.Tyre_Temp_RL_Outer), ...
    'RR_in',  val(D.Tyre_Temp_RR_Inner),  'RR_mid', val(D.Tyre_Temp_RR_Centre), 'RR_out', val(D.Tyre_Temp_RR_Outer));

T1 = extractTemps(D1);
T2 = extractTemps(D2);

%% --- Compute averages ---
computeAvg = @(T,mask) struct( ...
    'FL_in_mid',  mean(T.FL_in(mask) - T.FL_mid(mask)), ...
    'FL_out_mid', mean(T.FL_out(mask) - T.FL_mid(mask)), ...
    'FR_in_mid',  mean(T.FR_in(mask) - T.FR_mid(mask)), ...
    'FR_out_mid', mean(T.FR_out(mask) - T.FR_mid(mask)), ...
    'RL_in_mid',  mean(T.RL_in(mask) - T.RL_mid(mask)), ...
    'RL_out_mid', mean(T.RL_out(mask) - T.RL_mid(mask)), ...
    'RR_in_mid',  mean(T.RR_in(mask) - T.RR_mid(mask)), ...
    'RR_out_mid', mean(T.RR_out(mask) - T.RR_mid(mask)) );

A1_high = computeAvg(T1, mask1);
A1_low  = computeAvg(T1, ~mask1);
A2_high = computeAvg(T2, mask2);
A2_low  = computeAvg(T2, ~mask2);

%% --- Display results ---
corners = {'FL','FR','RL','RR'};
fields  = {'in\_mid','out\_mid'};

fprintf('\n=== Comparison of inner-mid and outer-mid averages ===\n');

for c = corners
    C = c{1};
    fprintf('\n--- %s ---\n', C);

    fprintf(' High load | Log1: inner-mid = %.2f, outer-mid = %.2f | Log2: inner-mid = %.2f, outer-mid = %.2f\n', ...
        A1_high.([C '_in_mid']), A1_high.([C '_out_mid']), ...
        A2_high.([C '_in_mid']), A2_high.([C '_out_mid']));

    fprintf(' Low load  | Log1: inner-mid = %.2f, outer-mid = %.2f | Log2: inner-mid = %.2f, outer-mid = %.2f\n', ...
        A1_low.([C '_in_mid']), A1_low.([C '_out_mid']), ...
        A2_low.([C '_in_mid']), A2_low.([C '_out_mid']));
end

fprintf('\nDone.\n');
