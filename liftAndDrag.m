function [alpha, Cl, Cd] = liftAndDrag(varargin)
% This function evaluates a turbine design, given a set of properties in a
% format suitable for optimisation using metaheuristics.
% 1 Input:  x - either a string that contains the ONE aerofoil type to be
%               used, or else a cell array that contains the aerofoil type
%               at each cross-section.
%            -- OR --
% 4 Inputs: for aerofoil information already found from elsewhere if the 
%           Inputs must be in correct order. 
%           1. x = 1 x n matrix containing the sequence number (1...k) of the 
%                aerofoil to be used at each section. n == nSections
%           2. CL = 1 x k matrix containing lift coefficient for each of k
%           aerofoils
%           3. CD = 1 x k matrix containing drag coefficient at optimal angle
%           of attack for each of k aerofoils.
%           4. alpha = 1 x k matrix containing optimal angle of attack for
%           each of k aerofoils
% Outputs:  alpha - A 1D array of length nSections, containing the optimal
%                 angle of attack for the aerofoil present at each section
%           Cl - A 1D array of length nSection, containing the lift
%                 coefficient C_l at the optimal angle of attack for the
%                 aerofoil at that section
%           Cd - A 1D array of length nSection, containing the drag
%                 coefficient C_d at the optimal angle of attack for the
%                 aerofoil at that section
%
% Note: xFoil takes a long time to run! We shouldn't call it more than
% neccessary!

% Jessica Mooney - jmoo185

global nSections Re

if nargin == 1
    x = varargin{1};
    angles = 0:1:15;
    % TODO
    % Get aerofoil data, and save Cl, Cd and alpha for each cross section
    % at the optimal alpha value.
    % -------------------------------------

    % check if x is not a cell if so the same areofoil at each section
    if ~isa(x, 'cell')

        % find the values with xfoil
        [pol, ~] = callXfoil(x,angles,Re,0); 
        
        % find the optimal angle
        clcd = pol.CL ./ pol.CD;
        [~, maxInd] = max(clcd);
        
        % save this optimal angle, cl and cd
        alpha = angles(maxInd)* ones(1, nSections) * 2 * pi /360;
        Cl = pol.CL(maxInd)* ones(1, nSections);
        Cd = pol.CD(maxInd)* ones(1, nSections);
    else
        % initialise the cl and cd array
        Cl = zeros(1,nSections);
        Cd = zeros(1,nSections);
        alpha = zeros(1,nSections);
        
        % loop through each section
        for i = 1:nSections
            found = false;
            % if it is not the first section check if xfoil has alreday been called
            % for the same areofoil as the current section
            if i~=1
                for j = 1:i-1
                    if strcmp(x{i}, x{j})
                        % Use the index to retrieve previously calculated values
                        alpha(i) = alpha(j);
                        Cl(i) = Cl(j);
                        Cd(i) = Cd(j);
                        found = true;
                    end    
                end
            end

            % if we have not calculated the values for this areofoil before
            % then call xfoil
            if found == false
                [pol, ~] = callXfoil(x{i},angles,Re,0);
            
                % find the optimal angle for this section
                clcd = pol.CL ./ pol.CD;
                [~, maxInd] = max(clcd);
            
                % save this optimal angle, cl and cd for this section
                alpha(i) = angles(maxInd)* 2 * pi /360;
                Cl(i) = pol.CL(maxInd);
                Cd(i) = pol.CD(maxInd);
            end
        end
    end 

    % -------------------------------------
       
elseif nargin == 4
    % Aerofoil info already pre-generated and is read in. Angle of attack
    % is already specified too.
    x = varargin{1};
    LiftCoeffs = varargin{2};
    DragCoeffs = varargin{3};
    Alphas = varargin{4};
    
    Cl = LiftCoeffs(x); % Lift coeff for EACH cross-section
    Cd = DragCoeffs(x); % Drag coeff for EACH cross-section
    alpha = Alphas(x); % angle of attack for each aerofoil at EACH cross-section
else
    error("Incorrect number of inputs")
end

end