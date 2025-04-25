clear;
clc;

global Vu rho eta nSections clearance B Re R Curve

R = 0.75;           % Outside radius of the turbine
Curve = @(x) generator(x);% Function relating torque to RPM of the generator
rho = 1.29;         % Density of air
eta = 1;            % System efficiency
nSections = 10;
clearance = 0.1;    % Radius of hub + any further distance with no blade section allowed.
Re = 60000;         % Approximate Reynolds number for design


% define airfoils and blade counts to consider and initialise results
airfoil_candidates = {'NACA0012', 'NACA2412', 'NACA4415'};
blade_counts = [3, 4, 5];  % can expand later like [3, 5]
results = struct('airfoil', {}, 'bladeCount', {}, 'Cp', {}, 'design', {});




% loop over airfoil and blade count combinations
for i = 1:length(airfoil_candidates)
    airfoil = airfoil_candidates{i};

    try
        % try to create surrogate model for the airfoil
        fx = createSurrogate(airfoil);  
    catch ME
        warning('Failed to create surrogate for %s. Skipping. Error: %s', airfoil, ME.message);
        continue;
    end

    for j = 1:length(blade_counts)
        b = blade_counts(j);
        try
            % run inner loop optimisation
            [fitness, design] = optimiseTurbineGivenShape(fx, b);

            % save results
            result.airfoil = airfoil;
            result.bladeCount = b;
            result.Cp = -fitness;
            result.design = design;

            results(end+1) = result;

        catch ME
            warning('Failed to optimise turbine for %s with %d blades. Skipping. Error: %s', airfoil, b, ME.message);
        end
    end
end

% identify best result based on max power coefficient (Cp)
if ~isempty(results)
    [~, idx] = max([results.Cp]); 
    best = results(idx);

    fprintf('Airfoil\t\tBlades\tWeighted Power Sum with Smoothness Penalty\n');
    fprintf('-----------------------------\n');
    for k = 1:length(results)
        fprintf('%-10s\t%d\t%.4f\n', results(k).airfoil, results(k).bladeCount, results(k).Cp);
    end

    
    fprintf('\nBest design found:\n');
    fprintf('  Airfoil: %s\n', best.airfoil);
    fprintf('  Blade count: %d\n', best.bladeCount);
    fprintf('  Weighted Power Sum with Smoothness Penalty: %.4f\n', best.Cp);
else
    fprintf('No successful designs were generated.\n');
end
