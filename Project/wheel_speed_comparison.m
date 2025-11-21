% ============================================================
% Compare Differential Lock Tendency Between Two MoTeC Logs
% ============================================================

% Ask user for the two .mat files
[file1, path1] = uigetfile('*.mat', 'Select baseline run');
filePath1 = fullfile(path1, file1);
[file2, path2] = uigetfile('*.mat', 'Select comparison run');
filePath2 = fullfile(path2, file2);

% Load the data
data1 = load(filePath1);
data2 = load(filePath2);

% --- Adjust these field names if different in your file ---
RL1 = data1.Wheel_Speed_RL.Value;   % Rear Left wheel speed
RR1 = data1.Wheel_Speed_RR.Value;   % Rear Right wheel speed
SA1 = data1.Steering_Wheel_Angle.Value; % Steering angle (deg)

RL2 = data2.Wheel_Speed_RL.Value;
RR2 = data2.Wheel_Speed_RR.Value;
SA2 = data2.Steering_Wheel_Angle.Value;

% Define thresholds
angleThreshold = 10;   % degrees
speedTolerance = 0.3;  % same units as your data (usually km/h)

% Function to compute diff lock percentage
computeLockPct = @(RL, RR, SA) ...
    sum(abs(RR - RL) < speedTolerance & (abs(SA) > angleThreshold)) ...
    / sum(abs(SA) > angleThreshold) * 100;

% Compute for both runs
lockPct1 = computeLockPct(RL1, RR1, SA1);
lockPct2 = computeLockPct(RL2, RR2, SA2);

% Display results
fprintf('--- Differential Lock Tendency ---\n');
fprintf('Baseline Run   : %.2f%% of cornering time wheels nearly locked\n', lockPct1);
fprintf('Comparison Run : %.2f%% of cornering time wheels nearly locked\n', lockPct2);

if lockPct2 > lockPct1
    fprintf('→ The differential seems to lock MORE in the comparison run.\n');
elseif lockPct2 < lockPct1
    fprintf('→ The differential seems to lock LESS in the comparison run.\n');
else
    fprintf('→ Both runs show equal locking tendency.\n');
end
