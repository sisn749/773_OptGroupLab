function objValue = turbineObj(design, fx)
    
    global Vu rho eta nSections clearance B Re R Curve

    %initilaise weighted power 
    weighted_power = 0;

    % set wind speeds and weights 
    wind_speeds = [4, 5, 6, 7];
    weights = [0.25, 0.45, 0.2, 0.1];

    lambda_angle = 1;
    lambda_cord = 1;

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

        % penalty
        penalty = lambda_cord*sum(diff(design(1:nSections).^2)) + ...
            lambda_angle*sum(diff(design(nSections+1:end).^2));
        weighted_power = weighted_power - penalty;


    end
    
    % return as negative so minimised is best
    objValue = -weighted_power;

end
