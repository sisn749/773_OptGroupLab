function [fx, success] = createSurrogate(airfoil, force_construct, alpha_range)
    % Creates a surrogate model for a given airfoil with caching
    %
    % Inputs:
    %   airfoil - String specifying the airfoil (e.g., 'NACA2412')
    %   force_construct - (Optional) Boolean to force new construction (default: false)
    %   alpha_range - (Optional) Range of alpha values to try (default: -10:1:10)
    %
    % Output:
    %   fx - Function handle for surrogate model that returns [CL, CD]
    %   success - Boolean indicating if surrogate creation was successful
    
    % Default parameters
    if nargin < 2
        force_construct = false;
    end
    if nargin < 3
        alpha_range = -10:1:12;
    end
    
    % Set cache file path
    cache_file = fullfile(pwd, 'surrogate_cache.mat');
    
    % Check if cache exists and try to load the surrogate
    success = false;
    if ~force_construct && exist(cache_file, 'file')
        cached_data = load(cache_file);
        if isfield(cached_data, 'surrogates') && isfield(cached_data.surrogates, airfoil)
            fx_data = cached_data.surrogates.(airfoil);
            fx = @(alpha_rad) simpleExtrapolation(alpha_rad, fx_data.alpha, fx_data.CL, fx_data.CD);
            fprintf('Loaded surrogate for %s from cache.\n', airfoil);
            success = true;
            return;
        end
    end
    
    % XFOIL parameters
    Re = 60000;
    Mach = 0;
    MIN_VALID_POINTS = 3;
    
    fprintf('Creating surrogate for %s...\n', airfoil);
    
    % Call XFOIL directly with two sweeps for better convergence
    try
        % Find the min and max of the requested alpha range
        min_alpha = min(alpha_range);
        max_alpha = max(alpha_range);
        
        % Determine the step size from the original alpha_range
        if length(alpha_range) > 1
            diffs = diff(sort(alpha_range));
            step_size = min(diffs(diffs > 0)); % Use smallest positive step
        else
            step_size = 1;  % Default step size if only one value is provided
        end
        
        % Execute the first sweep (positive angles)
        fprintf('  Sweep 1: Positive angles (0 to %.1f) with step size %.2f...\n', max_alpha, step_size);
        
        alpha_pos = 0:step_size:max_alpha;
        if length(alpha_pos) > 0
            polar_pos = callXfoil(airfoil, alpha_pos, Re, Mach);
            
            valid_idx_pos = ~isnan(polar_pos.CL) & ~isnan(polar_pos.CD);
            alpha_valid_pos = polar_pos.alpha(valid_idx_pos);
            CL_valid_pos = polar_pos.CL(valid_idx_pos);
            CD_valid_pos = polar_pos.CD(valid_idx_pos);
            
            fprintf('    Found %d valid points in positive sweep\n', sum(valid_idx_pos));
        else
            alpha_valid_pos = [];
            CL_valid_pos = [];
            CD_valid_pos = [];
            fprintf('    No positive angles requested\n');
        end
        
        % Execute the second sweep (negative angles)
        fprintf('  Sweep 2: Negative angles (%.1f to %.1f) with step size %.2f...\n', -step_size, min_alpha, step_size);
        
        alpha_neg = -step_size:-step_size:min_alpha;  % Start at -step_size to avoid duplicating zero
        if length(alpha_neg) > 0
            polar_neg = callXfoil(airfoil, alpha_neg, Re, Mach);
            
            valid_idx_neg = ~isnan(polar_neg.CL) & ~isnan(polar_neg.CD);
            alpha_valid_neg = polar_neg.alpha(valid_idx_neg);
            CL_valid_neg = polar_neg.CL(valid_idx_neg);
            CD_valid_neg = polar_neg.CD(valid_idx_neg);
            
            fprintf('    Found %d valid points in negative sweep\n', sum(valid_idx_neg));
        else
            alpha_valid_neg = [];
            CL_valid_neg = [];
            CD_valid_neg = [];
            fprintf('    No negative angles requested\n');
        end
        
        % Combine the data
        alpha_valid = [alpha_valid_neg; alpha_valid_pos];
        CL_valid = [CL_valid_neg; CL_valid_pos];
        CD_valid = [CD_valid_neg; CD_valid_pos];
        
        % Check if we have enough valid points
        num_valid = length(alpha_valid);
        fprintf('  Total valid data points: %d\n', num_valid);
        
        if num_valid < MIN_VALID_POINTS
            error('XFOIL_CONVERGENCE:InsufficientData', ...
                  'Failed to create surrogate for %s: Only %d valid points (minimum %d required)', ...
                  airfoil, num_valid, MIN_VALID_POINTS);
        end
        
        % Process successful XFOIL data
        fprintf('XFOIL runs successful. Creating surrogate...\n');
        
        % Create surrogate function
        fx = @(alpha_rad) simpleExtrapolation(alpha_rad, alpha_valid, CL_valid, CD_valid);
        
        % Save to cache file
        if exist(cache_file, 'file')
            cached_data = load(cache_file);
            surrogates = cached_data.surrogates;
        else
            surrogates = struct();
        end
        
        % Store data needed to recreate function
        surrogates.(airfoil) = struct('alpha', alpha_valid, 'CL', CL_valid, 'CD', CD_valid);
        save(cache_file, 'surrogates');
        
        fprintf('Successfully created and cached surrogate for %s.\n', airfoil);
        success = true;
        
    catch ME
        fx = @(x) deal(zeros(size(x)), zeros(size(x)));
        fprintf('Error: %s\n', ME.message);
        success = false;
    end
end

% Local function for extrapolation
function [CL, CD] = simpleExtrapolation(alpha_rad, alpha_valid_deg, CL_valid, CD_valid)
    % Convert input to degrees
    alpha_deg = alpha_rad * 180/pi;
    
    % Ensure data is sorted by alpha
    [alpha_sorted, sort_idx] = sort(alpha_valid_deg);
    CL_sorted = CL_valid(sort_idx);
    CD_sorted = CD_valid(sort_idx);
    
    % Initialize outputs to match input size
    CL = zeros(size(alpha_deg));
    CD = zeros(size(alpha_deg));
    
    % Get min/max of valid data range
    alpha_min = min(alpha_sorted);
    alpha_max = max(alpha_sorted);
    
    % Process each input angle
    for i = 1:numel(alpha_deg)
        curr_alpha = alpha_deg(i);
        
        if curr_alpha >= alpha_min && curr_alpha <= alpha_max
            % Within valid range - use interpolation
            CL(i) = interp1(alpha_sorted, CL_sorted, curr_alpha, 'pchip');
            CD(i) = interp1(alpha_sorted, CD_sorted, curr_alpha, 'pchip');
        
        elseif curr_alpha < alpha_min
            % Pre-stall extrapolation (negative angles)
            % Use up to 3 points for more robust linear extrapolation
            if length(alpha_sorted) >= 3
                % Use the first three points for a more robust fit
                p_cl = polyfit(alpha_sorted(1:3), CL_sorted(1:3), 1);
                CL(i) = polyval(p_cl, curr_alpha);
            elseif length(alpha_sorted) >= 2
                % Use two points if that's all we have
                p_cl = polyfit(alpha_sorted(1:2), CL_sorted(1:2), 1);
                CL(i) = polyval(p_cl, curr_alpha);
            else
                % Fallback to constant if only one point is available
                CL(i) = CL_sorted(1);
            end
            
            % For CD, use linear extrapolation based on last three points
            if length(alpha_sorted) >= 3
                % Use the first three points for a more robust fit
                p_drag = polyfit(alpha_sorted(1:3), CD_sorted(1:3), 1);
                CD(i) = polyval(p_drag, curr_alpha);
            elseif length(alpha_sorted) >= 2
                % Use two points if that's all we have
                p_drag = polyfit(alpha_sorted(1:2), CD_sorted(1:2), 1);
                CD(i) = polyval(p_drag, curr_alpha);
            else
                % Fallback to constant if only one point is available
                CD(i) = CD_sorted(1);
            end
            
        else % curr_alpha > alpha_max
            % Post-stall extrapolation (positive angles)
            dist_from_valid = curr_alpha - alpha_max;
            
            % Gentler linear decay model for lift coefficient after stall
            % Reduced decay factor from 0.03 to 0.015 for slower drop-off
            decay_factor = 0.95; %max(0.6, 1 - 0.015 * dist_from_valid);
            CL(i) = CL_sorted(end) * decay_factor;
            
            % For CD, use linear extrapolation based on last three points
            if length(alpha_sorted) >= 3
                % Use the last three points for a more robust fit
                p_drag = polyfit(alpha_sorted(end-2:end), CD_sorted(end-2:end), 1);
                CD(i) = polyval(p_drag, curr_alpha);
            elseif length(alpha_sorted) >= 2
                % Use two points if that's all we have
                p_drag = polyfit(alpha_sorted(end-1:end), CD_sorted(end-1:end), 1);
                CD(i) = polyval(p_drag, curr_alpha);
            else
                % Fallback to constant if only one point is available
                CD(i) = CD_sorted(end);
            end;
        end
    end
end