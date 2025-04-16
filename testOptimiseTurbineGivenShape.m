% tests task 3A

% 1. 
global Vu rho eta nSections clearance B Re R Curve
Vu = 6;             % Testing speed of 7m/s
R = 0.75;           % Outside radius of the turbine
Curve = @(x) generator(x);% Function relating torque to RPM of the generator
rho = 1.29;         % Density of air
eta = 1;            % System efficiency
nSections = 2;
clearance = 0.1;    % Radius of hub + any further distance with no blade section allowed.
B = 5;              % Number of blades
Re = 60000;         % Approximate Reynolds number for design

% 2.
fx = createSurrogate('NACA0012', true);

numblades = 5;

[c, beta] = optimiseTurbineGivenShape(fx, numblades);


