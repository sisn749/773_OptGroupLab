function [obj, speed] = evaluateTurbine(fx, c, beta)
% This function evaluates a turbine design, given a set of properties in a
% format suitable for optimisation using metaheuristics.
%
% Inputs:  f - A fast (er than xFoil) function that we return the lift and
%              drag coefficients of our aerofoil for a given angle of
%              attack
%           c - A 1D array of length nSections, containing the chord length
%               for each section
%           beta - a 1D array of length nSections, containing the blade
%                  setting angle for each section
% Outputs:  obj = objective value of interest, to be defined for the
%                 application. Usually, Cp.
%           speed = The RPM of the turbine
%
% Your Name and Username goes here.
% Jessica Mooney - jmoo185

% Constants (to go into params)
global Vu rho eta nSections clearance B R Curve
r = linspace(clearance, R, nSections);

% TODO:
% Your code goes here!
% --------------------------------------------


% convergence tolerance
tol = 1*10^(-6);
converged = false;

% initial guess of lambda
lambda = 2; 

max_iterations = 5000;
iterations = 0;

while ~converged && iterations < max_iterations
    lambda_old = lambda;
    omega = lambda*Vu/R;
    lambda_r = omega * r / Vu;
    iterations = iterations + 1;
    
    converged_inner = false;

    % Initialize a and a_prime for each section
    a = 0.33 * ones(1, nSections);   
    a_prime = zeros(1, nSections);   

    iterations_inner = 0;
    
    % loop with a and a_prime have not converged
    while ~converged_inner && iterations_inner < max_iterations
        iterations_inner = iterations_inner +1;

        % Store old values of a and a_prime
        a_old = a;
        a_prime_old = a_prime;
        
        % calculate phi
        phi = atan((1 - a) ./ ((1 + a_prime) .* lambda_r));
        
        % calculate alpha
        alpha = phi - beta;
        
        % update cl and cd
        [Cl, Cd] = fx(alpha);

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
        % make sure f is not 0
        f = max(f, 1e-8);
        F = (2 / pi) * acos(exp(-f));  

        % Update a and a_prime 
        a = (solidity .* Cn) ./ (4 * F .* (sin(phi)).^2 + solidity .* Cn); 
        a_prime = (solidity .* Ct) ./ (4 * F .* sin(phi) .* cos(phi) - (solidity .* Ct));
       
        % Apply damping factor to avoid oscillations
        xi = 0.1;  
        a = a_old + xi*(a - a_old);
        a_prime = a_prime_old + xi*(a_prime - a_prime_old);
        
        % check a is within realistic bounds
        for i=1:nSections
            if a(i) < 0
                a(i) = 0;
            elseif a(i) > 0.5
                a(i) = 0.5;
            end
        end

        % Check for convergence
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

% set objective value as cp and set speed value
obj = Cp; 
speed = omega*30/pi;  

% --------------------------------------------
end

