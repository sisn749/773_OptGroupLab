function objValue = turbineObj(design, fx)
    
    global Vu rho eta nSections clearance B Re R Curve

    %initilaise weighted power 
    weighted_power = 0;

    % set wind speeds and weights 
    wind_speeds = [4, 5, 6, 7];
    weights = [0.25, 0.45, 0.2, 0.1];

    lambda_angle = 5;
    lambda_cord = 5;

    % evaluate performace at each wind speed
    for i = 1:length(wind_speeds)
        % run evaluate turbine to get power at this wind speed
        Vu = wind_speeds(i);
        [obj, speed] = evaluateTurbine(fx, design(1:nSections), design(nSections+1:end)); 
        
        % CHECK THIS - do we want expected power or cp
        cp = obj;
        power = cp*0.5*rho*pi*R^2*Vu^3;

        % currently power = cp
        % power = obj;
        
        % check it is within limits
        if speed > 200 || speed < 0
            power = 0; 
        end

        % add to the weighted power
        weighted_power = weighted_power + power*weights(i);

    end

    % Extract chord and angle parts of the design
    chord = design(1:nSections);
    angle = design(nSections+1:end);

    % Compute second-order differences
    second_diff_chord = chord(3:end) - 2*chord(2:end-1) + chord(1:end-2);
    second_diff_angle = angle(3:end) - 2*angle(2:end-1) + angle(1:end-2);

    % Compute smoothness penalty
    penalty = lambda_cord * sum(second_diff_chord.^2) + ...
     lambda_angle * sum(second_diff_angle.^2);

    weighted_power = weighted_power - penalty;
    
    % return as negative so minimised is best
    objValue = -weighted_power;

end
