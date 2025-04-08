function fx = createSurrogateFromList(airfoil_list, force_construct)
    % Creates a surrogate model using different airfoils for different angles
    %
    % Inputs:
    %   airfoil_list - Cell array of strings specifying airfoils for different sections
    %   force_construct - (Optional) Boolean to force new construction (default: false)
    %
    % Output:
    %   fx - Function handle for surrogate model that returns [CL, CD]
    
    % Input validation
    if ~iscell(airfoil_list)
        error('airfoil_list must be a cell array of strings');
    end
    
    if nargin < 2
        force_construct = false;
    end
    
    num_sections = length(airfoil_list);
    fprintf('Creating surrogates for %d airfoil types...\n', num_sections);
    
    % Create surrogate models for each unique airfoil
    surrogate_funcs = cell(num_sections, 1);
    
    for i = 1:num_sections
        airfoil = airfoil_list{i};
        fprintf('Creating surrogate %d/%d for airfoil: %s\n', i, num_sections, airfoil);
        [surrogate_funcs{i}, success] = createSurrogate(airfoil, force_construct);
        
        if ~success
            error('Failed to create surrogate for airfoil %s', airfoil);
        end
    end
    
    % Return a function handle that selects appropriate surrogate for each angle
    fx = @(alpha_rad) evaluateSurrogates(alpha_rad, surrogate_funcs, num_sections);
    
    fprintf('Successfully created surrogates for all airfoils.\n');
end

function [CL, CD] = evaluateSurrogates(alpha_rad, surrogate_funcs, num_sections)
    % For each input angle, evaluate with the appropriate airfoil
    
    % Get number of input angles
    n_angles = length(alpha_rad);
    
    % Initialize output arrays
    CL = zeros(size(alpha_rad));
    CD = zeros(size(alpha_rad));
    
    % Use the specified surrogate for each angle based on its index
    for i = 1:n_angles
        % Map this angle to the correct section/airfoil
        section_idx = mod(i-1, num_sections) + 1;
        
        % Get the surrogate for this section
        section_surrogate = surrogate_funcs{section_idx};
        
        % Call that airfoil's surrogate with this alpha value
        [cl, cd] = section_surrogate(alpha_rad(i));
        
        % Store results
        CL(i) = cl;
        CD(i) = cd;
    end
end