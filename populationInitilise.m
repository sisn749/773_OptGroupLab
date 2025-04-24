function population = populationInitilise(airfoil, numBlades, refResults)
    
    found = false;
    for i = 1:length(refResults)
        if refResults(i, 1) == airfoil && refResults(i, 2) == numBlades
            refDesign = refResults(i, 4);
            found = true;
        end
    end

    if found

        n_designs = 10;
        population = zeros(n_designs, length(refDesign));

        for i =1:n_designs
            design = (1 + 0.3 *(2*rand(siz(refDesign))-1)).* refDesign;

            design = max(design, 0.7*refDesign);
            design = max(design, 1.3*refDesign);

            population(i, :) = design;
        end
    else 
        population = false;
    end

end