function objValue = turbineObj(design, fx)
    
    global Vu rho eta nSections clearance B Re R Curve

    %initilaise weighted power 
    weighted_power = 0;

    % set wind speeds and weights 
    wind_speeds = [4, 5, 6, 7];
    weights = [0.25, 0.45, 0.2, 0.1];

    % evaluate performace at each wind speed
    for i = 1:length(wind_speeds)
        % run evaluate turbine to get power at this wind speed
        Vu = wind_speeds(i);
        [obj, speed] = evaluateTurbine(fx, design(1:nSections), design(nSections+1:end)); 
        
        % CHECK THIS - do we want expected power or cp
        %power = cp*0.5*rho*pi*R^2*Vu^3;

        % currently power = cp
        power = obj;
        
        % check it is within limits
        if speed > 200 || speed < 0
            power = 0; 
        end

        % add to the weighted power
        weighted_power = weighted_power + power*weights(i);

    end
    
    % return as negative so minimised is best
    objValue = -weighted_power;

end
