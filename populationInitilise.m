function population = populationInitilise()
    
    global nSections

    found = true;
    
    refDesign = zeros(1, 2*nSections);
    for i = 1:nSections
        refDesign(i) = 0.5;
        refDesign(i+nSections) = 0.02*i+0.2;
    end

    if found

        n_designs = 10;
        population = zeros(n_designs, length(refDesign));

        for i =1:n_designs
            design = (1 + 0.3 *(2*rand(size(refDesign))-1)).* refDesign;

            design = max(design, 0.7*refDesign);
            design = max(design, 1.3*refDesign);

            population(i, :) = design;
        end
    else 
        population = false;
    end

end
