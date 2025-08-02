%% Classification TSK(Takagi Sugeno Kang) Model
% Load Dataset
data = load('Datasets/haberman.data'); % 3 attributes, 1 label (4 columns)

% Set random seed for reproducibility
rng(0);

% Split - Preprocess Data
addpath('Assignment3');
[trnData, chkData, tstData] = split_scale(data, 1);

%  Extract features and labels
trnX = trnData(:, 1:end-1);
trnY = trnData(:, end);
chkX = chkData(:, 1:end-1);
chkY = chkData(:, end);
tstX = tstData(:, 1:end-1);
tstY = tstData(:, end);

%% 4 TSK Models with different number of IF-THEN rules each
% 2 class dependant clustering 
% 2 class independent clustering
% all singletons
% cluster size parameter should get extreme values to show change
% Hybrid training: mf parameters are updated through backpropagation, output parameters are updated through least squares

cluster_radius = [0.2, 0.8, 0.2, 0.8]; % Number of rules

for i=1:length(cluster_radius) 
    fprintf('\n#### Model: %d ####\n', i);
    % Divide input space through Subtractive clustering 
    if i == 1 || i == 2
        options = genfisOptions('SubtractiveClustering','ClusterInfluenceRange', cluster_radius(i));

        inFIS = genfis(trnX, trnY, options);

        % Number of rules
        num_rules = length(inFIS.rule);

        % ANFIS (Adaptive Neuro Fuzzy Inference System)
        epochs = 50; % Number of epochs
        opt = anfisOptions(...
            'InitialFIS', inFIS, ... % Initial FIS
            'EpochNumber', epochs, ... % Number of epochs
            'OptimizationMethod', 1, ... % Hybrid training: backpropagation to compute input membership function parameters, and least squares estimation to compute output membership function parameters
            'ValidationData', [chkX, chkY],... % Validation data
            'DisplayStepSize', 0,... % Don't display step size
            'DisplayErrorValues', 0,... % Don't display error values
            'DisplayANFISInformation', 0); % Don't display ANFIS information

        % Train the model
        [fis, trainError, stepSize, chkFIS, chkError] = anfis([trnX, trnY], opt);

        % Evaluate the model on the test set
        Y_pred_test = evalfis(chkFIS, tstX);
    elseif i == 3 || i == 4
        classes = [1, 2]; % Dataset classes: Class 1: y=1, Class 2: y=2
        fis_array = cell(length(classes), 1); % Cell array to store FIS for each class

        for j = 1:length(classes)
            % Extract data for current class
            class_mask = (trnY == classes(j));
            class_data_X = trnX(class_mask, :);
            class_data_Y = trnY(class_mask);
            
            % Apply subtractive clustering to this class
            options = genfisOptions('SubtractiveClustering', 'ClusterInfluenceRange', cluster_radius(i));
            
            % Generate FIS for this class
            class_fis = genfis(class_data_X, class_data_Y, options);
            
            % Store the FIS for this class
            fis_array{j} = class_fis;
        end
        % Create combined FIS structure starting with first class
        combined_fis = fis_array{1};
        % Add rules from second class
        combined_fis = addRule(combined_fis, fis_array{2});

        % Number of rules
        num_rules = length(combined_fis.rule);
        
        % ANFIS (Adaptive Neuro Fuzzy Inference System)
        epochs = 50; % Number of epochs
        opt = anfisOptions(...
            'InitialFIS', combined_fis, ... % Initial FIS
            'EpochNumber', epochs, ... % Number of epochs
            'OptimizationMethod', 1, ... % Hybrid training: backpropagation to compute input membership function parameters, and least squares estimation to compute output membership function parameters
            'ValidationData', [chkX, chkY],... % Validation data
            'DisplayStepSize', 0,... % Don't display step size
            'DisplayErrorValues', 0,... % Don't display error values
            'DisplayANFISInformation', 0); % Don't display ANFIS information

        % Train the model
        [fis, trainError, stepSize, chkFIS, chkError] = anfis([trnX, trnY], opt);

        % Evaluate the model on the test set
        Y_pred_test = evalfis(chkFIS, tstX);
    end

    % Plot the fuzzy set after training
    figure;
    plotmf(chkFIS, 'input', 1); % Plot membership functions for the first input
    title(sprintf('Fuzzy Set after Training (Cluster Radius: %.2f)', cluster_radius(i)));
    xlabel('Input Value');
    ylabel('Membership Degree');
    grid on;

    % Plot error vs iterations
    figure;
    plot(trainError, 'b-', 'LineWidth', 2);
    hold on;
    plot(chkError, 'r-', 'LineWidth', 2);
    xlabel('Epochs');
    ylabel('Error');
    title(sprintf('Training and Validation Error (Cluster Radius: %.2f)', cluster_radius(i)));
    legend('Training Error', 'Validation Error');

    % Error matrix kxk, where k=numofclasses 
    % Columns: Real, Rows: Predicted (Diagonal->True Positives)
    % Generate error matrix 2x2 - Class 1: y=1, Class 2: y=2
    error_matrix = zeros(2, 2);
    % Round predicted class to the nearest integer
    Y_pred_test = round(Y_pred_test);
    for k = 1:length(Y_pred_test)
        if Y_pred_test(k) == 1 && tstY(k) == 1
            error_matrix(1,1) = error_matrix(1,1) + 1; % True Positive
        elseif Y_pred_test(k) == 1 && tstY(k) == 2
            error_matrix(1,2) = error_matrix(1,2) + 1; % False Positive
        elseif Y_pred_test(k) == 2 && tstY(k) == 1
            error_matrix(2,1) = error_matrix(2,1) + 1; % False Negative
        elseif Y_pred_test(k) == 2 && tstY(k) == 2
            error_matrix(2,2) = error_matrix(2,2) + 1; % True Negative
        end
    end

    % Performance metrics
    OA = sum(diag(error_matrix)) / sum(error_matrix(:)); % Overall Accuracy
    PA = diag(error_matrix) ./ sum(error_matrix, 2); % Producer's Accuracy
    UA = diag(error_matrix) ./ sum(error_matrix, 1)'; % User's Accuracy
    K_hat = (sum(error_matrix(:)) * sum(diag(error_matrix)) - sum(sum(error_matrix, 1) .* sum(error_matrix, 2))) / (sum(error_matrix(:))^2 - sum(sum(error_matrix, 1) .* sum(error_matrix, 2)));

    % Display performance metrics
    if i == 1 || i == 2
        fprintf('Clustering Type: Class Independent\n');
    elseif i == 3 || i == 4
        fprintf('Clustering Type: Class Dependent\n');
    end
    fprintf('Cluster Radius: %.2f\n', cluster_radius(i));
    fprintf('Number of Rules: %d\n', num_rules);
    fprintf('Overall Accuracy (OA): %.4f\n', OA);
    fprintf("Producer\'s Accuracy (PA): %.4f, %.4f\n", PA(1), PA(2));
    fprintf("User\'s Accuracy (UA): %.4f, %.4f\n", UA(1), UA(2));
    fprintf('K_hat: %.4f\n\n', K_hat);
    
end
