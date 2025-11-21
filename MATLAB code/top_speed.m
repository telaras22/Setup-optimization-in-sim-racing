%% --- Top-End Speed Comparison (10 zones, manual input) ---
clear; clc; close all;

%% --- USER INPUT ---
baselineName = input('Enter BASELINE run name : ', 's');
improvedName = input('Enter IMPROVED run name : ', 's');

fprintf('\nEnter the 10 TOP-END speeds [km/h] for each run.\n');

fprintf('\n--- %s ---\n', baselineName);
baseline = zeros(1,10);
for i = 1:10
    baseline(i) = input(sprintf('  Top speed %2d: ', i));
end

fprintf('\n--- %s ---\n', improvedName);
improved = zeros(1,10);
for i = 1:10
    improved(i) = input(sprintf('  Top speed %2d: ', i));
end

%% --- CALCULATIONS ---
nZones = numel(improved);
delta = improved - baseline;
percentDelta = (delta ./ baseline) * 100;

%% --- PRINT TABLE ---
fprintf('\n--- Top-End Speed Comparison (%s vs %s) ---\n', improvedName, baselineName);
fprintf('Zone |  %s [km/h]  |  %s [km/h]  |  Δ (km/h)  |  Δ (%%)\n', improvedName, baselineName);
fprintf('-------------------------------------------------------------\n');
for i = 1:nZones
    fprintf(' %2d   |     %6.1f     |     %6.1f     |   %+6.2f   |   %+6.2f%%\n', ...
        i, improved(i), baseline(i), delta(i), percentDelta(i));
end
fprintf('-------------------------------------------------------------\n');
fprintf('Mean Δ Top Speed: %+6.2f km/h (%+.2f%%)\n', mean(delta), mean(percentDelta));

%% --- PLOT ---
figure('Name','Top-End Speed Comparison','NumberTitle','off','Position',[100 100 1000 600]);
hold on; grid on;

barData = [baseline(:), improved(:)];
b = bar(1:nZones, barData, 'grouped');
b(1).FaceColor = [0.85, 0.33, 0.10];  % orange for baseline
b(2).FaceColor = [0.20, 0.80, 0.20];  % green for improved

xlabel('Zone #');
ylabel('Top-End Speed [km/h]');
title(sprintf('Top-End Speeds: %s vs %s', improvedName, baselineName));
xticks(1:nZones);
legend({baselineName, improvedName}, 'Location', 'northoutside', 'Orientation', 'horizontal');

% --- Add delta annotations ---
for i = 1:nZones
    yMax = max(barData(i,:));
    deltaStr = sprintf('%+.1f km/h (%+.1f%%)', delta(i), percentDelta(i));
    if delta(i) >= 0
        text(i, yMax + 1.5, deltaStr, 'HorizontalAlignment','center', ...
            'FontWeight','bold', 'Color',[0 0.6 0]);
    else
        text(i, yMax + 1.5, deltaStr, 'HorizontalAlignment','center', ...
            'FontWeight','bold', 'Color',[0.8 0 0]);
    end
end

ylim([min([baseline, improved]) - 5, max([baseline, improved]) + 12]);
hold off;

fprintf('\n✅ 10-zone top-end speed comparison complete.\n');
