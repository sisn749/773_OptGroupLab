clear;
clc;

% define airfoils and blade counts to consider and initialise results
airfoil_candidates = {'NACA0012', 'NACA2412', 'NACA4415'};
blade_counts = [5];  % can expand later like [3, 5]
results = [];

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
            result.Cp = fitness;
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
    
    fprintf('\nBest design found:\n');
    fprintf('  Airfoil: %s\n', best.airfoil);
    fprintf('  Blade count: %d\n', best.bladeCount);
    fprintf('  Power coefficient (Cp): %.4f\n', best.Cp);
else
    fprintf('No successful designs were generated.\n');
end
