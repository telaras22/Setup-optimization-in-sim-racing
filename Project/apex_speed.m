%% --- Apex Speed Comparison (Dual Bar Plot) ---
clear; clc; close all;

%% --- USER INPUT (for labeling only) ---
baselineName = input('Enter BASELINE run name : ', 's');
improvedName = input('Enter IMPROVED run name : ', 's');

%% --- DATA (km/h) ---
% Improved vs Baseline apex speeds
improved = [125.6, 100.8, 116.8, 107.4, 116.5,  87.4, 101.0, 101.1, 107.2,  94.4, 118.7, 113.1, 144.7];
baseline = [115.8,  96.5, 112.1, 104.7, 108.2,  97.6, 101.2,  98.6, 111.0,  96.0, 129.8, 102.5, 128.2];

apexCount = numel(improved);
delta = improved - baseline;

%% --- PRINT TABLE ---
fprintf('\n--- Apex Speed Comparison (%s vs %s) ---\n', improvedName, baselineName);
fprintf('Apex |  %s [km/h]  |  %s [km/h]  |  Δ (Imp - Base)\n', improvedName, baselineName);
fprintf('-------------------------------------------------\n');
for i = 1:apexCount
    fprintf(' %2d   |     %6.1f     |     %6.1f     |    %+6.2f\n', ...
        i, improved(i), baseline(i), delta(i));
end
fprintf('-------------------------------------------------\n');
fprintf('Mean Δ Apex Speed: %+6.2f km/h\n', mean(delta));

%% --- PLOT ---
figure('Name','Apex Speed Comparison','NumberTitle','off','Position',[100 100 1000 600]);
hold on; grid on;

barData = [baseline(:), improved(:)];
b = bar(1:apexCount, barData, 'grouped');
b(1).FaceColor = [0.85, 0.33, 0.10];  % orange for baseline
b(2).FaceColor = [0.20, 0.80, 0.20];  % green for improved

xlabel('Apex #');
ylabel('Apex Speed [km/h]');
title(sprintf('Apex Speeds: %s vs %s', improvedName, baselineName));
xticks(1:apexCount);
legend({baselineName, improvedName}, 'Location', 'northoutside', 'Orientation', 'horizontal');

% Add delta text annotations
for i = 1:apexCount
    yMax = max(barData(i,:));
    deltaStr = sprintf('%+.1f', delta(i));
    text(i, yMax + 1.5, deltaStr, 'HorizontalAlignment','center', ...
        'FontWeight','bold', 'Color', delta(i)>=0*[0 0.5 0]-[0.7 0 0]);
end

ylim([min([baseline, improved]) - 5, max([baseline, improved]) + 10]);
hold off;

fprintf('\n✅ Dual-bar apex speed comparison complete.\n');
