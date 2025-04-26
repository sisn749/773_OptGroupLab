function visualize(shape, nsection, design)
% Usage: visualize('NACA2412', 10, results(4).design)
    
    % Load airfoil shape from XFOIL
    [~, foil] = callXfoil(shape, 0, 50000, 0);
    x_base = foil.x(1:300); 
    y_base = foil.y(1:300);
    
    % Prepare storage for scaled and rotated airfoils
    X = zeros(300, nsection);
    Y = zeros(300, nsection);
    Z = zeros(300, nsection);
    
    chord_lengths = design(1:nsection);
    angles = design(nsection+1:end);
    
    % Scale airfoils
    for i = 1:nsection
            chord = chord_lengths(i);
            angle = angles(i);
            
            % Scale
            x_scaled = x_base * chord;
            y_scaled = y_base * chord;
    
            % Rotate
            x_rot = cos(angle)*x_scaled - sin(angle)*y_scaled;
            y_rot = sin(angle)*x_scaled + cos(angle)*y_scaled;
    
            % Store result and change z
            X(:, i) = x_rot;
            Y(:, i) = y_rot;
            Z(:, i) = (((i-1) * ones(1,300))/nsection)*0.6;
    end
    
    % Plot surface
    figure;
    surf(X, Y, Z, 'FaceAlpha', 0.5, 'EdgeColor', 'none');
    hold on;
    
    % Plot each section
    for i = 1:nsection
        plot3(X(:, i), Y(:, i), Z(:, i), 'k-');
    end
    
    % Labeling the axes and setting the grid
    axis equal;
    grid on;
    xlabel('x');
    ylabel('y');
    zlabel('length');
    title(['Visualization for airfoil: ' shape]);

end
