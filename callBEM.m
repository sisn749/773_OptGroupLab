% Example calls to evaluateTurbine()
% Defines required global vars.

global Vu rho eta nSections clearance B Re R Curve optimise_c

Vu = 7;  % Design speed, e.g. 5 m/s
R = 0.75;           % Outside radius of the turbine
Curve = @(x) generator(x);% Function relating torque to RPM of the generator
rho = 1.29;         % Density of air
eta = 1;            % System efficiency
nSections = 15;
clearance = 0.1;    % Radius of hub + any further distance with no blade section allowed.
B = 5;              % Number of blades
Re = 60000;         % Approximate Reynolds number for design
optimise_c = true;

[alpha, Cl, Cd] = liftAndDrag('NACA0012');
[obj1, design1] = BEM(alpha, Cl, Cd);

testArray = {'NACA0015', 'NACA0015', 'NACA0015', 'NACA0015', 'NACA0015', 'NACA0015', 'NACA0015', 'NACA0015', ...
     'e176.dat', 'e176.dat', 'e176.dat', 'e176.dat', 'e176.dat', 'e176.dat', 'e176.dat'};
[alpha, Cl, Cd] = liftAndDrag(testArray);
[obj2, design2] = BEM(alpha, Cl, Cd);

CL = [1.3054    0.8773    0.6231];
CD = [0.0126    0.0110    0.0123];
Alphas = [0.0873    0.0785    0.0873]; % in radians
x = [1 1 1 1 2 2 2 2 2 2 3 3 3 3 1];

[alpha, Cl, Cd] = liftAndDrag(x, CL, Cd, Alphas);
[obj3, design3] = BEM(alpha, Cl, Cd);

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