function [c, beta] = optimiseTurbineGivenShape(fx, numblades)
% this function is the "inner loop" and optimises the cord length and beta
% angle for a given turbine shape. 

% inputs:
% fx: surrogate function for given airfoil design (function) - implicitly
% inputs the given airfoil design
% numblades: number of blades (ndarray of ints)

% outputs:
% c: optimal chord length
% beta: optimal setting angle

% 0. call the global variables ------------------------------------------
global Vu rho eta nSections clearance B Re R Curve

% 1. set the bounds -----------------------------------------------------

% Solidity-based bounds using proper wind turbine theory
r = linspace(clearance, R, nSections); % Radius at each blade section

% Define target solidity range (example)
% Solidity (sigma) = (B × chord) / (2 pi r)
sigma_max_hub = 0.9; % Higher upper bound for solidity at hub
sigma_max_tip = 0.5; % Lower upper solidity at tip
sigma_range = linspace(sigma_max_hub, sigma_max_tip, nSections);

% Calculate chord bounds based on solidity
% Rearranged solidity formula: chord = sigma × (2 pi r) / B
local_circumference = 2*pi*r;
ub_chord = sigma_range .* local_circumference / B;
lb_chord = 0.01 * ub_chord; % 1 percent of upper bound

% Setting angle bounds
lb_beta = 0 * pi/180 * ones(1, nSections);
ub_beta = 60 * pi/180 * ones(1, nSections);

% 2. 


end