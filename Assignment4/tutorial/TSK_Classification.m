%% ANFIS - Classification Example with Modern Fuzzy Functions (Fixed Version)
format compact
clear 
clc

%% Load and prepare data
data = load('phoneme.dat');
preproc = 1;
[trnData, chkData, tstData] = split_scale(data, preproc);

% Check for constant features and remove them
constant_features = find(range(trnData(:,1:end-1)) == 0);
if ~isempty(constant_features)
    fprintf('Removing constant features: %s\n', mat2str(constant_features));
    trnData(:,constant_features) = [];
    chkData(:,constant_features) = [];
    tstData(:,constant_features) = [];
end

radius = 0.5;
options = genfisOptions('SubtractiveClustering', 'ClusterInfluenceRange', radius);

%% Class-specific clustering approach
try
    % Create separate FIS for each class
    class0Data = trnData(trnData(:,end) == 0, :);
    class1Data = trnData(trnData(:,end) == 1, :);
    
    % Check if classes have enough samples
    min_samples = 5; % Minimum samples per class
    if size(class0Data,1) < min_samples || size(class1Data,1) < min_samples
        error('Not enough samples in one or more classes');
    end
    
    % Create individual FIS for each class with error handling
    fis0 = genfis(class0Data(:,1:end-1), class0Data(:,end), options);
    fis1 = genfis(class1Data(:,1:end-1), class1Data(:,end), options);
    
    % Combine the two FIS
    fis = sugfis('Name', 'phoneme_classifier');
    
    % Add inputs with proper ranges
    for i = 1:size(trnData,2)-1
        % Get actual data range for this input
        input_range = [min(trnData(:,i)) max(trnData(:,i))];
        % Ensure range is valid
        if input_range(1) >= input_range(2)
            input_range(2) = input_range(1) + 1; % Small adjustment
        end
        fis = addInput(fis, input_range, 'Name', sprintf('in%d',i));
        
        % Add MFs from fis0
        for j = 1:length(fis0.Inputs(i).MembershipFunctions)
            mf = fis0.Inputs(i).MembershipFunctions(j);
            fis = addMF(fis, sprintf('in%d',i), mf.Type, mf.Parameters, ...
                       'Name', sprintf('class0_mf%d',j));
        end
        
        % Add MFs from fis1
        for j = 1:length(fis1.Inputs(i).MembershipFunctions)
            mf = fis1.Inputs(i).MembershipFunctions(j);
            fis = addMF(fis, sprintf('in%d',i), mf.Type, mf.Parameters, ...
                       'Name', sprintf('class1_mf%d',j));
        end
    end
    
    % Add output
    fis = addOutput(fis, [0 1], 'Name', 'class');
    
    % Add rules
    numRules = length(fis0.Rules) + length(fis1.Rules);
    ruleList = zeros(numRules, size(trnData,2));
    weights = ones(numRules, 1);
    connections = ones(numRules, 1);
    
    for i = 1:numRules
        if i <= length(fis0.Rules)
            ruleList(i,:) = fis0.Rules(i).Antecedent;
            outputValue = 0; % Class 0
        else
            ruleList(i,:) = fis1.Rules(i-length(fis0.Rules)).Antecedent;
            outputValue = 1; % Class 1
        end
        fis = addRule(fis, [ruleList(i,:) outputValue weights(i) connections(i)]);
    end
    
    % Train ANFIS
    options = anfisOptions('InitialFIS', fis, 'EpochNumber', 100, ...
                          'InitialStepSize', 0.01, 'StepSizeDecreaseRate', 0.9, ...
                          'StepSizeIncreaseRate', 1.1, 'ValidationData', chkData);
    [trnFis, trnError, ~, valFis, valError] = anfis(trnData, options);
    
    figure;
    plot([trnError valError], 'LineWidth', 2); grid on;
    legend('Training Error', 'Validation Error');
    xlabel('# of Epochs');
    ylabel('Error');
    title('ANFIS with Class-Specific Clustering (Modern)');
    
    Y = evalfis(valFis, tstData(:,1:end-1));
    Y = round(Y);
    diff = tstData(:,end) - Y;
    Acc = (length(diff) - nnz(diff))/length(Y)*100;
    fprintf('Class-Specific Clustering Accuracy: %.2f%%\n', Acc);
    
catch ME
    fprintf('Error in class-specific approach: %s\n', ME.message);
end

%% Class-independent clustering approach
try
    fis = genfis(trnData(:,1:end-1), trnData(:,end), genfisOptions('SubtractiveClustering', ...
        'ClusterInfluenceRange', radius));
    
    options = anfisOptions('InitialFIS', fis, 'EpochNumber', 100, ...
                          'InitialStepSize', 0.01, 'StepSizeDecreaseRate', 0.9, ...
                          'StepSizeIncreaseRate', 1.1, 'ValidationData', chkData);
    [trnFis, trnError, ~, valFis, valError] = anfis(trnData, options);
    
    figure;
    plot([trnError valError], 'LineWidth', 2); grid on;
    legend('Training Error', 'Validation Error');
    xlabel('# of Epochs');
    ylabel('Error');
    title('Class-Independent Clustering');
    
    Y = evalfis(valFis, tstData(:,1:end-1));
    Y = round(Y);
    diff = tstData(:,end) - Y;
    Acc = (length(diff) - nnz(diff))/length(Y)*100;
    fprintf('Class-Independent Clustering Accuracy: %.2f%%\n', Acc);
    
catch ME
    fprintf('Error in class-independent approach: %s\n', ME.message);
end