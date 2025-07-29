% Mode is either 'lectures' or 'custom'
function ruleTable = visualizeRuleTable(mode)
    
    % Initialize 9x9 matrix
    ruleTable = zeros(9, 9); 
    
    for i = 1:9 % i = E (rows)
        for j = 1:9 % j = dE (columns)
            switch mode
                case 'lectures'
                    out = max(min((i + j - 5), 9), 1);
                case 'custom'
                    if j < 5  % Negative dE
                        out = max(1, i + j - 6);  % Reduced aggressiveness
                    elseif j > 5  % Positive dE
                        out = min(9, i + j - 4);  % Increased aggressiveness
                    else
                        out = max(min(10 - i, 9), 1);  % Faster correction
                    end
                otherwise
                    error('Unknown mode. Use ''lectures'' or ''custom''.');
            end
            ruleTable(i, j) = out;
        end
    end

    % Display the table
    disp(['Rule Table for mode: ', mode]);
    disp(array2table(ruleTable, 'VariableNames', {'dE_1','dE_2', 'dE_3', 'dE_4', 'dE_5', 'dE_6', 'dE_7', 'dE_8', 'dE_9'}, 'RowNames', {'E_1','E_2', 'E_3', 'E_4', 'E_5', 'E_6', 'E_7', 'E_8', 'E_9'}));
end