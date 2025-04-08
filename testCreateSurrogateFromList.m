% Test script for createSurrogateFromList function
clear;
close all;

fprintf('\n===== Testing createSurrogateFromList =====\n');

% Define angles for each section
section_angles_deg = [-5, 0, 3, 6, 9];  % 5 sections, different angles
section_angles_rad = section_angles_deg * pi/180;

% 1. Create a surrogate for a single reference airfoil
single_airfoil = 'NACA2412';
fprintf('\n1. Creating single airfoil surrogate for %s...\n', single_airfoil);
[fx_single, success1] = createSurrogate(single_airfoil, false);

if ~success1
    error('Failed to create single airfoil surrogate');
end

% 2. Create a list of different airfoils for different sections
fprintf('\n2. Creating variable airfoil surrogate...\n');
% Each section can have a different airfoil, strategically selected based on angle:
% - Root sections (low angles): Use higher-thickness, lower-camber airfoils for structural strength
% - Middle sections: Use moderate, efficient airfoils
% - Tip sections (high angles): Use higher-camber, thinner airfoils for better performance

% Improved airfoil selection for better performance
airfoil_list = {'NACA0015', 'NACA2412', 'NACA4412', 'NACA6412', 'NACA4415'};
fprintf('   Using airfoils: %s, %s, %s, %s, %s\n', airfoil_list{:});
fprintf('   Airfoils strategically selected for each section''s operating angle:\n');
fprintf('   - Section 1 (%.1f°): %s - Thick, low camber for structural strength at root\n', section_angles_deg(1), airfoil_list{1});
fprintf('   - Section 2 (%.1f°): %s - Moderate airfoil for inboard section\n', section_angles_deg(2), airfoil_list{2});
fprintf('   - Section 3 (%.1f°): %s - Efficient airfoil for mid-span\n', section_angles_deg(3), airfoil_list{3});
fprintf('   - Section 4 (%.1f°): %s - Higher camber for outboard section\n', section_angles_deg(4), airfoil_list{4});
fprintf('   - Section 5 (%.1f°): %s - Higher thickness for better lift at high angles\n', section_angles_deg(5), airfoil_list{5});
fx_variable = createSurrogateFromList(airfoil_list, false);

% 3. For validation, create a list where all airfoils are the same
fprintf('\n3. Creating validation surrogate with identical airfoils...\n');
identical_list = repmat({single_airfoil}, 1, 5);  % 5 sections, all the same airfoil
fx_validation = createSurrogateFromList(identical_list, false);

fprintf('\nEvaluating at section angles: ');
fprintf('%.1f° ', section_angles_deg);
fprintf('\n');

% Evaluate all surrogates
[CL_single, CD_single] = fx_single(section_angles_rad);
[CL_variable, CD_variable] = fx_variable(section_angles_rad);
[CL_validation, CD_validation] = fx_validation(section_angles_rad);

% Calculate lift-to-drag ratios
LD_single = CL_single ./ CD_single;
LD_variable = CL_variable ./ CD_variable;
LD_validation = CL_validation ./ CD_validation;

% Plot the results
figure('Name', 'Surrogate Model Comparison');

% LIFT COEFFICIENT PLOT
subplot(3,1,1);
plot(section_angles_deg, CL_single, 'ko-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Single Airfoil (NACA2412)');
hold on;
plot(section_angles_deg, CL_variable, 'go-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Variable Airfoils');
plot(section_angles_deg, CL_validation, 'b--', 'LineWidth', 2, 'DisplayName', 'Validation (Identical)');
grid on;
xlabel('Angle of Attack (degrees)');
ylabel('Lift Coefficient (CL)');
title('Lift Coefficient Comparison');
legend('Location', 'best');

% Add airfoil labels above the data points for the variable case
for i = 1:length(airfoil_list)
    text(section_angles_deg(i), CL_variable(i)+0.05, airfoil_list{i}, ...
        'HorizontalAlignment', 'center', 'FontSize', 8);
end

% DRAG COEFFICIENT PLOT
subplot(3,1,2);
plot(section_angles_deg, CD_single, 'ko-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Single Airfoil (NACA2412)');
hold on;
plot(section_angles_deg, CD_variable, 'go-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Variable Airfoils');
plot(section_angles_deg, CD_validation, 'b--', 'LineWidth', 2, 'DisplayName', 'Validation (Identical)');
grid on;
xlabel('Angle of Attack (degrees)');
ylabel('Drag Coefficient (CD)');
title('Drag Coefficient Comparison');
legend('Location', 'best');

% LIFT-TO-DRAG RATIO PLOT
subplot(3,1,3);
plot(section_angles_deg, LD_single, 'ko-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Single Airfoil (NACA2412)');
hold on;
plot(section_angles_deg, LD_variable, 'go-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Variable Airfoils');
plot(section_angles_deg, LD_validation, 'b--', 'LineWidth', 2, 'DisplayName', 'Validation (Identical)');
grid on;
xlabel('Angle of Attack (degrees)');
ylabel('Lift-to-Drag Ratio (L/D)');
title('Lift-to-Drag Ratio Comparison');
legend('Location', 'best');

% Check validation accuracy
fprintf('\nValidation Results:\n');
cl_diff = max(abs(CL_single - CL_validation));
cd_diff = max(abs(CD_single - CD_validation));
fprintf('Maximum CL difference: %.6f\n', cl_diff);
fprintf('Maximum CD difference: %.6f\n', cd_diff);

if cl_diff < 1e-10 && cd_diff < 1e-10
    fprintf('Validation successful! createSurrogateFromList works correctly with identical airfoils.\n');
else
    warning('Validation failed! Results differ between createSurrogate and createSurrogateFromList.');
end

% Add annotation explaining the plots
annotation('textbox', [0.15, 0.01, 0.7, 0.05], ...
    'String', ['Each point represents a different blade section. The variable airfoil blade (green) ' ...
               'uses different airfoils for each section, while the black line uses NACA2412 throughout.'], ...
    'FitBoxToText', 'on', 'HorizontalAlignment', 'center', 'EdgeColor', 'none');