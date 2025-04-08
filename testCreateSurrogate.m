% Test script for surrogate function with direct XFOIL interaction
clear all; close all; clc;

%% Settings
airfoil = 'NACA0012';  % Try different NACA airfoils
alpha_range_build = -10:1:12;  % Set of angles to build surrogate (sparse)
alpha_range_plot = -30:0.5:30;  % Set of angles to plot (dense)

fprintf('Testing surrogate for %s with alpha range %s\n', airfoil, mat2str(alpha_range_build));

%% Create surrogate
force_construct = true;
[fx, success] = createSurrogate(airfoil, force_construct, alpha_range_build);

%% Check if surrogate creation was successful
if ~success
    error('Failed to create surrogate! Check error messages above.');
end

% We need to extract valid data for plotting
% First, use the cache to get our data
cache_file = fullfile(pwd, 'surrogate_cache.mat');
if exist(cache_file, 'file')
    cached_data = load(cache_file);
    if isfield(cached_data, 'surrogates') && isfield(cached_data.surrogates, airfoil)
        fx_data = cached_data.surrogates.(airfoil);
        alpha_valid = fx_data.alpha;
        CL_valid = fx_data.CL;
        CD_valid = fx_data.CD;
        
        fprintf('Successfully created surrogate with %d valid data points\n', length(alpha_valid));
        fprintf('Valid alpha range: %.1f to %.1f degrees\n', min(alpha_valid), max(alpha_valid));
    else
        error('Could not find airfoil data in cache');
    end
else
    error('Cache file not found');
end

%% Visualize results: raw data vs surrogate
figure('Position', [100, 100, 900, 400]);

% Evaluate surrogate at a denser set of points
surrogate_cl = zeros(size(alpha_range_plot));
surrogate_cd = zeros(size(alpha_range_plot));

for i = 1:length(alpha_range_plot)
    [surrogate_cl(i), surrogate_cd(i)] = fx(alpha_range_plot(i) * pi/180);  % Convert to radians
end

% Plot CL
subplot(1,2,1);
hold on;
% Plot XFOIL data points
plot(alpha_valid, CL_valid, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8, 'DisplayName', 'XFOIL Data');
% Plot surrogate curve
plot(alpha_range_plot, surrogate_cl, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Surrogate');

% Add vertical lines to mark interpolation vs extrapolation
xline(min(alpha_valid), 'k--', 'DisplayName', 'Data Range');
xline(max(alpha_valid), 'k--', 'HandleVisibility', 'off');

grid on;
xlabel('Angle of Attack (°)');
ylabel('Lift Coefficient (C_L)');
title('Lift Coefficient');
legend('Location', 'best');

% Plot CD
subplot(1,2,2);
hold on;
% Plot XFOIL data points
plot(alpha_valid, CD_valid, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8, 'DisplayName', 'XFOIL Data');
% Plot surrogate curve
plot(alpha_range_plot, surrogate_cd, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Surrogate');

% Add vertical lines to mark interpolation vs extrapolation
xline(min(alpha_valid), 'k--', 'DisplayName', 'Data Range');
xline(max(alpha_valid), 'k--', 'HandleVisibility', 'off');

grid on;
xlabel('Angle of Attack (°)');
ylabel('Drag Coefficient (C_D)');
title('Drag Coefficient');
legend('Location', 'best');

% Add title
sgtitle(['Airfoil Surrogate: ' airfoil], 'FontSize', 14);

% Create a new figure for lift-to-drag ratio
figure('Position', [100, 550, 600, 400]);

% Calculate lift-to-drag ratio from surrogate data
% Avoid division by zero by using a small epsilon
epsilon = 1e-6;
surrogate_ld = surrogate_cl ./ (surrogate_cd + epsilon);

% Calculate L/D from raw data points
ld_valid = CL_valid ./ (CD_valid + epsilon);

% Plot L/D
hold on;
% Plot XFOIL data points
plot(alpha_valid, ld_valid, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8, 'DisplayName', 'XFOIL Data');
% Plot surrogate curve
plot(alpha_range_plot, surrogate_ld, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Surrogate');

% Add vertical lines to mark interpolation vs extrapolation
xline(min(alpha_valid), 'k--', 'DisplayName', 'Data Range');
xline(max(alpha_valid), 'k--', 'HandleVisibility', 'off');

grid on;
xlabel('Angle of Attack (°)');
ylabel('Lift-to-Drag Ratio (L/D)');
title(['Lift-to-Drag Ratio: ' airfoil]);
legend('Location', 'best');

% Find optimal L/D point
[max_ld, max_idx] = max(surrogate_ld);
optimal_alpha = alpha_range_plot(max_idx);

% Add marker for optimal L/D point
plot(optimal_alpha, max_ld, 'gs', 'MarkerSize', 10, 'MarkerFaceColor', 'g', 'DisplayName', 'Optimal L/D');

% Print data stats
fprintf('\nSurrogate Stats:\n');
fprintf('  CL range: %.4f to %.4f\n', min(CL_valid), max(CL_valid));
fprintf('  CD range: %.4f to %.4f\n', min(CD_valid), max(CD_valid));
fprintf('  L/D range: %.1f to %.1f\n', min(ld_valid), max(ld_valid));
fprintf('  Best L/D: %.1f at %.1f degrees\n', max_ld, optimal_alpha);