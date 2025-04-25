% Airfoil shapes from XFOIL
[~, foil1] = callXfoil('NACA0012', 5, 50000, 0);
[~, foil2] = callXfoil('NACA4415', 5, 50000, 0);

x1 = foil1.x(1:300); 
y1 = foil1.y(1:300);  
x2 = foil2.x(1:300);  
y2 = foil2.y(1:300);  

% Plot the airfoil shapes
figure;
plot(x1, y1, 'b.-', 'DisplayName', 'NACA0012');
hold on;
plot(x2, y2, 'r.-', 'DisplayName', 'NACA4415');
axis equal;
grid on;
xlabel('x');
ylabel('y');
title('Airfoil Shapes');
legend show;

% Create a 3D plot of the two airfoils and a surface connecting them
figure;
% Set distance between airfoils.
z_vals = linspace(0, 1, 100);
% Interpolate the x and y coordinates between 1 and 2
x_interp = (1 - z_vals) .* x1 + z_vals .* x2;
y_interp = (1 - z_vals) .* y1 + z_vals .* y2;

% Plot the two airfoils in 3D
plot3(x1, y1, zeros(size(x1)), 'b-', 'LineWidth', 1.5);
hold on;
plot3(x2, y2, ones(size(x2)), 'r-', 'LineWidth', 1.5);

% Plot the surface connecting the two airfoils
surf(x_interp, y_interp, repmat(z_vals, 300, 1), 'FaceAlpha', 0.5, 'EdgeColor', 'none');

% Labeling the axes and setting the grid
xlabel('x');
ylabel('y');
zlabel('length');
title('Surface connecting airfoils');
grid on;
axis equal;
