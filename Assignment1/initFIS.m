%% FIS (Fuzzy Inference System) Setup
function fis = initFIS()
    % Mamdani Fuzzy Inference System (FIS)
    fis = mamfis('Name', 'FuzzyController');
    % AND is implemented through the min operator
    fis.AndMethod = 'min';
    % Larsen implication
    fis.ImplicationMethod = 'prod';
    % ALSO is implemented through the max operator
    fis.AggregationMethod = 'max';
    % COA(Center of Area) defuzzification method
    fis.DefuzzificationMethod = 'centroid';

    % Membership Functions
    labels = {'NV','NL','NM','NS','ZR','PS','PM','PL','PV'};
    A = 1;
    cent = -A:(A/4):A; % Centers of the membership functions [-A -A+(A/4) ... A-(A/4) A]
    w = (1.5/4)*A; % Half width of the membership functions

    % Inputs: E and dE, Output: dU
    fis = addInput(fis,[-A A],'Name','E');
    fis = addInput(fis,[-A A],'Name','dE');
    fis = addOutput(fis,[-A A],'Name','dU');
    % 9 Membership Functions for E, dE and dU
    for k = 1:9
        fis = addMF(fis,'E','trimf',[cent(k)-w cent(k) cent(k)+w],'Name',labels{k});
        fis = addMF(fis,'dE','trimf',[cent(k)-w cent(k) cent(k)+w],'Name',labels{k});
        fis = addMF(fis,'dU','trimf',[cent(k)-w cent(k) cent(k)+w],'Name',labels{k});
    end

    % Preallocate Rule Base matrix 
    rules = zeros(81,5); % 
    % Rule index
    index = 1;
    for i = 1:9 % i = E
        for j = 1:9 % j = dE
            if j < 5  % Negative dE
                out = max(1, i+j-6);  % Reduced aggressiveness
            elseif j > 5  % Positive dE
                out = min(9, i+j-4);  % Increased aggressiveness
            else
                out = max(min(10-i, 9), 1);  % Faster correction
            end
            rules(index,:) = [i j out 1 1]; % [E, dE, dU, weight, connection]
            index = index + 1;
        end
    end
    fis = addRule(fis,rules);

end