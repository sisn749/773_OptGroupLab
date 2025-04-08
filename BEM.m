function [obj, design] = BEM(alpha, Cl, Cd)
% This function evaluates a turbine design, given a set of properties in a
% format suitable for optimisation using metaheuristics.
%
% Inputs:  alpha - A 1D array of length nSections, containing the optimal
%                 angle of attack for the aerofoil present at each section
%           Cl - A 1D array of length nSection, containing the lift
%                 coefficient C_l at the optimal angle of attack for the
%                 aerofoil at that section
%           Cd - A 1D array of length nSection, containing the drag
%                 coefficient C_d at the optimal angle of attack for the
%                 aerofoil at that section
% Outputs:  obj = objective value of interest, to be defined for the
%                 application. Usually, Cp.
%           design = structure with turbine design features, specifically
%               r = cross-sectional radii
%               chord = chord length
%               Cp = power coefficient
%               alpha = angle of attack of aerofoil
%               beta = setting angle
%               RPM = RPM of the turbine spin
%               Q = torque of the turbine
%
% Your Name and Username goes here.

% Constants (to go into params)
global Vu rho eta nSections clearance B Re R Curve

r = linspace(clearance, R, nSections);
c = 0.5/B*ones(1,nSections);    % A good value for chord lengths, don't
                                % change for the BEM assignment submission
% TODO:
% Implement the BEM method to find Cp
% --------------------------------------------

% convergence tolerance
tol = 1*10^(-6);

% initial guess of lambda
lambda = 2; 

max_iterations = 5000;
iterations = 0;
converged = false;

% while lambda hasn't converged and less than max iterations
while ~converged && iterations < max_iterations

    % save the current lambda
    lambda_old = lambda;

    % calculate omega and lambda_r
    omega = lambda*Vu/R;
    lambda_r = omega * r / Vu;

    % update iteration 
    iterations = iterations + 1;

    % Initialize a and a_prime for each section as optimal values
    a = 0.33 * ones(1, nSections);   
    a_prime = zeros(1, nSections);   
    
    % set inner convergence loop values
    converged_inner = false;
    iterations_inner = 0;
    
    % loop until a and a_prime have converged
    while ~converged_inner && iterations_inner < max_iterations
        iterations_inner = iterations_inner +1;

        % Store old a and a_prime values 
        a_old = a;
        a_prime_old = a_prime;
        
        % calculate phi
        phi = atan((1 - a) ./ ((1 + a_prime) .* lambda_r));

        % calculate solidity
        solidity = B*c./(2*pi*r);
        if max(solidity) > 1
            solidity = min(solidity,1);
        end
        
        % find the normal and tangential coefficents
        Cn = Cl .* cos(phi) + Cd .* sin(phi);  
        Ct = Cl .* sin(phi) - Cd .* cos(phi);  

        % Compute Prandtl tip loss parameters 
        f = (B * ((R+0.0001*r) - r)) ./ (2 * r .* sin(phi));
        % make sure f isn't zero
        f = max(f, 1e-8);
        F = (2 / pi) * acos(exp(-f));  

        % Update a and a_prime 
        a = (solidity .* Cn) ./ (4 * F .* (sin(phi)).^2 + solidity .* Cn); 
        a_prime = (solidity .* Ct) ./ (4 * F .* sin(phi) .* cos(phi) - (solidity .* Ct));
       
        % Apply damping factor to avoid oscillations
        xi = 0.1;  
        a = a_old + xi*(a - a_old);
        a_prime = a_prime_old + xi*(a_prime - a_prime_old);
        
        % Check that a is within realistic bounds
        for i=1:nSections
            if a(i) < 0
                a(i) = 0;
            elseif a(i) > 0.5
                a(i) = 0.5;
            end
        end

        % Check for convergence of a and a_prime
        if all(abs(a - a_old) < tol) && all(abs(a_prime - a_prime_old) < tol)
            converged_inner = true;
        end

    end

    % Calculate tangential force 
    pT = (0.5 * rho * Vu^2 * (1 - a).^2 .* Ct .* c)./(sin(phi).^2);  
    
    % Integrate torque contribution
    delQ = trapz(r, pT.*r);
    Q = delQ*B;

    % Update omega and lambda using the generator curve
    lambda = pi*R*Curve(Q)/(30*Vu);

    % Check for convergence on lambda
    if all(abs(lambda_old - lambda)) < tol
        converged = true;
    end 
end

% Compute power and power coefficient
PE = omega * Q * eta;  
PT = 0.5 * rho * pi * R^2 * Vu^3;  
Cp = PE / PT; 

% set objective value as Cp
obj = Cp;  

% Output turbine design features
design.r = r;
design.chord = c;
design.Cp = Cp;
design.alpha = alpha;
design.beta = phi - alpha;  
design.RPM = omega*30/pi;  
design.Q = Q;  

return