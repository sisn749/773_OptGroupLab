function RPM = generator(Q)
    if Q > 4.8
        % Outside the practical range for the generator.
        RPM = 314.0*Q-1200.0;
    elseif Q >= 0
        RPM = 1.25*(279-sqrt(77841.0-16000.0*Q));
    else
        % This is bad news, but allowing the generator to deal with
        % negative torque can help with convergence
        RPM = -generator(-Q);
    end
end