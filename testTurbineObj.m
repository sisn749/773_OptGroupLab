% test turbineObj

% Sample design to test
airfoil = 'NACA0012';
num_blades = 5;
chord = [0.19, 0.18, 0.17, 0.16, 0.15, 0.14, 0.13, 0.12, 0.11, 0.10, 0.09, 0.08, 0.07, 0.06, 0.05];
beta = [25, 22, 19, 17, 15, 13, 11, 9, 8, 7, 6, 5, 4, 3, 2] * pi/180;

 global Vu rho eta nSections clearance B Re R Curve

nSections = length(chord);
R = 0.75;           % Outside radius of the turbine
Curve = @(x) generator(x);% Function relating torque to RPM of the generator
rho = 1.29;         % Density of air
eta = 1;            % System efficiency
clearance = 0.1;    % Radius of hub + any further distance with no blade section allowed.
B = num_blades;              % Number of blades
Re = 60000;         % Approximate Reynolds number for design

fx = createSurrogate(airfoil, true, -20:1:35);

% Call turbineObj
val = turbineObj([chord, beta], fx);
