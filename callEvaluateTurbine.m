global Vu rho eta nSections clearance B Re R Curve

Vu = 6;             % Testing speed of 7m/s
R = 0.75;           % Outside radius of the turbine
Curve = @(x) generator(x);% Function relating torque to RPM of the generator
rho = 1.29;         % Density of air
eta = 1;            % System efficiency
nSections = 15;
clearance = 0.1;    % Radius of hub + any further distance with no blade section allowed.
B = 5;              % Number of blades
Re = 60000;         % Approximate Reynolds number for design

% An example of some blade setting angles in radians
beta = [0.7448,0.6545,0.5749,0.5060,0.4470,0.3966,0.3533,0.3161,0.2836,0.2548,0.2284,0.2031,0.1765,0.1421,0.0872];
c = [0.2659,0.3132,0.3318,0.3329,0.3241,0.3103,0.2943,0.2776,0.2609,0.2442,0.2270,0.2081,0.1850,0.1500,0.0927];

try
    [Cp, RPM] = evaluateTurbine(@fx, c, beta);
catch
    Cp = 'Error';
end
disp(Cp)

function [Cl, Cd] = fx(alpha)
% An example of a function that can approximate the lift and drag
% coefficient for an aerofoil. Example is a NACA0012 aerofoil, and we
% linearly interpolate between the coefficients at discrete values of alpha
if ~all(isreal(alpha))
    error('Imaginary alpha, model has diverged')
end

ClIndex = [0; -0.0034; 0.3176; 0.4633; 0.5428; 0.6175; 0.6897; 0.7699; ...
0.8469; 0.9005; 0.8599; 0.6989; 0.5380; 0.5343; 0.5424; 0.5244];

CdIndex = [0.0196; 0.0207; 0.0212; 0.0198; 0.0200; 0.0216; 0.0249; ...
0.0301; 0.0373; 0.0479; 0.0664; 0.1058; 0.1451; 0.1582; 0.1710; 0.1791];

alphaIndex = pi/180*[0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15];

Cl = interp1(alphaIndex, ClIndex, alpha, 'linear', ClIndex(end));
Cd = interp1(alphaIndex, CdIndex, alpha, 'linear', CdIndex(end));
end

function RPM = generator(Q)
    if Q > 4.8
        % Outside the practical range for the generator.
        RPM = 314.0*Q-1200.0;
    elseif Q < 0
        RPM = 0;
    else
        RPM = 1.25*(279-sqrt(77841.0-16000.0*Q));
    end
end