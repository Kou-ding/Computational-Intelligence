%% High demensionality Dataset Classification TSK(Takagi Sugeno Kang) Model
clear; % clear variables
close all; % close figures

% Load Dataset
data_table = readtable('Datasets/epileptic_seizure_data.csv'); % 179(178+1) attributes, 1 label, 11500 samples
data = table2array(data_table(:, 2:end)); % Convert table to array

% Set random seed for reproducibility
rng(0);

% Split - Preprocess Data
[trnData, chkData, tstData] = split_scale(data, 1); % 60% training, 20% validation, 20% test

%  Extract features and labels
trnX = trnData(:, 1:end-1);
trnY = trnData(:, end);
chkX = chkData(:, 1:end-1);
chkY = chkData(:, end);
tstX = tstData(:, 1:end-1);
tstY = tstData(:, end);

%% Dimensionality Reduction
% Reduce the number of IF-THEN rules by:
% selecting the most important features
% fuzzy clustering
% Two parameters to tune:
% 1. Number of features to select
% 2. Number of clusters (rules) or cluster radius (very similar)
% Use grid search to find the best combination of parameters, where grid is 2x2
% 5-fold cross-validation to evaluate the performance of each combination
% Feature selection algorithm: ReliefF
% Subtractive clustering 
% Manually change the linear output to constant output for classification
num_features_list = [5, 10, 15, 20]; % Number of features
radius_list = [0.2, 0.4, 0.6, 0.8]; % cluster radius
k = 5; % cross-validation folds

% Matrix to store the average RMSE for each (feature_index, radius_index) combination
RMSE_matrix = zeros(length(num_features_list), length(radius_list)); 
% Matrix to store the number of rules for each (feature_index, radius_index) combination
rules_matrix = zeros(length(num_features_list), length(radius_list));
% Ovelall accuracy Matrix
OA_matrix = zeros(length(num_features_list), length(radius_list));

% Iterate over all the potential number of features
for feature_index = 1:length(num_features_list)
    % Rank importance of predictors using ReliefF (10 nearest neighbors)
    [idx, weights] = relieff(trnX, trnY, 10);

    % Select only the top num_features_list(feature_index) features from the total important features list idx
    selected_Idx = idx(1:num_features_list(feature_index));
    
    % Select the top features from the training set
    selected_trnX = trnX(:, selected_Idx);

    % Iterate over all the potential radius values
    for radius_index = 1:length(radius_list)
        % Initialize array to store RMSE for each fold
        kfold_RMSE_list = zeros(k, 1);

        % Initialize array to store number of rules for each fold
        kfold_num_rules = zeros(k, 1);

        % Initialize array to store overall accuracy for each fold
        kfold_OA = zeros(k, 1); 

        % Create k-fold cross-validation partition
        cv = cvpartition(size(selected_trnX,1), 'KFold', k);
        
        % Iterate over each fold
        for fold = 1:k
            % Split data into training and validation sets
            kfold_trnX = selected_trnX(cv.training(fold), :);
            kfold_trnY = trnY(cv.training(fold));
            kfold_chkX = selected_trnX(cv.test(fold), :);
            kfold_chkY = trnY(cv.test(fold));

            % % Clip values to the range [0, 1]
            % kfold_trnX = min(max(kfold_trnX, 0), 1);
            % kfold_chkX = min(max(kfold_chkX, 0), 1);
            
            % Generate FIS from the selected number of features and radius
            % Uses subtractive clustering and the range of influence of the cluster centers is equal to radius_list(radius_index)
            options = genfisOptions('SubtractiveClustering', 'ClusterInfluenceRange', radius_list(radius_index));
            fis = genfis(kfold_trnX, kfold_trnY, options);
            % Deprecated atlernative
            % fis = genfis2(kfold_trnX, kfold_trnY, radius_list(radius_index));
            
            % Store the number of rules for the current fold
            kfold_num_rules(fold) = length(fis.rule);

            % Train the FIS using ANFIS
            [trnFis, ~] = anfis([kfold_trnX kfold_trnY], fis, 50, [0 0 0 0], [kfold_chkX kfold_chkY]);
            % Evaluate the FIS on the validation set
            Ypred = evalfis(trnFis, kfold_chkX);
            kfold_RMSE_list(fold) = sqrt(mean((Ypred - kfold_chkY).^2));
            Ypred = round(Ypred); % Round predictions to nearest integer for classification
            % Ensure predictions are within class limits
            Ypred(Ypred < 1) = 1; % Ensure minimum class is
            Ypred(Ypred > 5) = 5; % Ensure maximum class is 5

            % Calculate overall accuracy for the current fold
            kfold_OA(fold) = sum(Ypred == kfold_chkY) / length(kfold_chkY);
        end
        
        % Calculate average RMSE for the current (num_features, radius) combination
        RMSE_matrix(feature_index,radius_index) = mean(kfold_RMSE_list);

        % Calculate average number of rules for the current (num_features, radius) combination
        rules_matrix(feature_index,radius_index) = mean(kfold_num_rules);

        % Calculate overall accuracy for the current fold
        OA_matrix(feature_index, radius_index) = mean(kfold_OA);

        % Display the results
        fprintf('Features: %2d | Radius: %.2f | AvgRMSE: %.4f | AvgRules: %.4f | OA: %.4f\n ', num_features_list(feature_index), radius_list(radius_index), RMSE_matrix(feature_index,radius_index), rules_matrix(feature_index,radius_index), OA_matrix(feature_index, radius_index));
    end
end

% Find the min RSME from the RMSE matrix
[minOA, minIdx] = max(OA_matrix(:));
% Convert linear index to row and column indices
[row, col] = ind2sub(size(RMSE_matrix), minIdx);
best_num_features = num_features_list(row);
best_radius = radius_list(col);
fprintf('Minimum OA: %.4f at Features: %d, Radius: %.2f\n', minOA, best_num_features, best_radius);

%% Grid Search Plots
% RMSE vs Number of Features
figure;
for i = 1:length(radius_list)
    subplot(1, length(radius_list), i);
    plot(num_features_list, RMSE_matrix(:,i), 'bo');
    xlabel('Number of Features');
    ylabel('RMSE');
    title(sprintf('Error vs Number of Features (Radius: %.2f)', radius_list(i)));
    grid on;
end
% RMSE vs Cluster Radius
figure;
for i = 1:length(num_features_list)
    subplot(length(num_features_list), 1, i);
    plot(radius_list, RMSE_matrix(i,:), 'bo');
    xlabel('Cluster Radius');
    ylabel('RMSE');
    title(sprintf('Error vs Cluster Radius (Features: %d)', num_features_list(i)));
    grid on;
end

%% Optimal Model Training
% Train Final Model with Best Parameters
[idx, weights] = relieff(trnX, trnY, 10);
final_Idx = idx(1:best_num_features);

final_trnX = trnX(:, final_Idx);
final_chkX = chkX(:, final_Idx);
final_tstX = tstX(:, final_Idx);

% Clip values to the range [0, 1]
final_trnX = min(max(final_trnX, 0), 1);
final_chkX = min(max(final_chkX, 0), 1);
final_tstX = min(max(final_tstX, 0), 1);

options = genfisOptions('SubtractiveClustering', 'ClusterInfluenceRange', best_radius);
inFIS = genfis(final_trnX, trnY, options);
% Deprecated alternative
%inFIS = genfis2(final_trnX, trnY, best_radius);

epochs = 100; % Number of epochs for training

% Plot membership functions before training
figure;
subplot(1, 3, 1);
plotmf(inFIS, 'input', 1); % Plot membership functions for the first input
xlabel('Input 1');
ylabel('Membership Degree');
title(sprintf('Fuzzy Set before Training (Cluster Radius: %.2f)', best_radius));subplot(1, 3, 2);
grid on;
subplot(1, 3, 2);
plotmf(inFIS, 'input', 2); % Plot membership functions for the second input
xlabel('Input 2');
ylabel('Membership Degree');
title(sprintf('Fuzzy Set before Training (Cluster Radius: %.2f)', best_radius));
grid on;
subplot(1, 3, 3);
plotmf(inFIS, 'input', 3); % Plot membership functions for the third input
xlabel('Input 3');
ylabel('Membership Degree');
title(sprintf('Fuzzy Set before Training (Cluster Radius: %.2f)', best_radius));
grid on;

% Set ANFIS options
opt = anfisOptions(...
    'InitialFIS', inFIS, ... % Initial FIS
    'EpochNumber', epochs, ... % Number of epochs
    'ValidationData', [final_chkX chkY]);  % Validation data
[fis, trainError, stepSize, chkFIS, chkError] = anfis([final_trnX trnY], opt);

% Number of rules in the final FIS
num_rules = length(chkFIS.rule);

% Predict on Test Set
Ypred_test = evalfis(chkFIS, final_tstX);

% Error matrix kxk, where k=numofclasses 
% Columns: Real, Rows: Predicted (Diagonal->True Positives)
% Generate error matrix 2x2 - Class 1: y=1, Class 2: y=2
error_matrix = zeros(5, 5);

% Round predicted class to the nearest integer
predicted = round(Ypred_test);
actual = tstY;

for k = 1:length(Ypred_test)
    % Keep within class limits
    if predicted(k) < 1
        predicted(k) = 1; % Ensure minimum class is 1
    elseif predicted(k) > 5
        predicted(k) = 5; % Ensure maximum class is 5
    end
    
    % Update error matrix
    error_matrix(predicted(k), actual(k)) = error_matrix(predicted(k), actual(k)) + 1;
end

% Plot membership functions after training
figure;
subplot(1, 3, 1);
plotmf(chkFIS, 'input', 1); % Plot membership functions for the first input
xlabel('Input 1');
ylabel('Membership Degree');
title(sprintf('Fuzzy Set after Training (Cluster Radius: %.2f)', best_radius));
grid on;
subplot(1, 3, 2);
plotmf(chkFIS, 'input', 2); % Plot membership functions for the second input
xlabel('Input 2');
ylabel('Membership Degree');
title(sprintf('Fuzzy Set after Training (Cluster Radius: %.2f)', best_radius));
grid on;
subplot(1, 3, 3);
plotmf(chkFIS, 'input', 3); % Plot membership functions for the third input
xlabel('Input 3');
ylabel('Membership Degree');
title(sprintf('Fuzzy Set after Training (Cluster Radius: %.2f)', best_radius));
grid on;

%% Optimal Model Plots
% Real vs Predicted labels
figure;
scatter(actual, Ypred_test, 10, 'filled');
hold on;
plot([min(tstY), max(tstY)], [min(tstY), max(tstY)], 'k--', 'LineWidth', 1.5); % 45° reference line
xlabel('True Values');
ylabel('Predicted Values');
title('Predicted vs True Values on Test Set');
grid on;
axis equal;
xlim([min(tstY), max(tstY)]);
ylim([min(tstY), max(tstY)]);

% Error vs Iterations
figure;
plot(trainError, 'b', 'LineWidth', 1.5); hold on;
plot(chkError, 'r', 'LineWidth', 1.5);
xlabel('Epoch');
ylabel('RMSE');
title('Training and Validation Learning Curve');
legend('Training Error', 'Validation Error');
grid on;

% Performance metrics
OA = sum(diag(error_matrix)) / sum(error_matrix(:)); % Overall Accuracy
PA = diag(error_matrix) ./ sum(error_matrix, 2); % Producer's Accuracy aka Recall
UA = diag(error_matrix) ./ sum(error_matrix, 1)'; % User's Accuracy aka Precision
K_hat = (sum(error_matrix(:)) * sum(diag(error_matrix)) - sum(sum(error_matrix, 1) .* sum(error_matrix, 2))) / (sum(error_matrix(:))^2 - sum(sum(error_matrix, 1) .* sum(error_matrix, 2)));

% Performance metrics table (OA, PA, UA, K_hat)
fprintf('\n#### Optimal Model ####:\n');
fprintf('Cluster Radius: %.2f\n', best_radius);
fprintf('Number of Features: %d\n', best_num_features);
fprintf('Number of Rules: %d\n', num_rules);
fprintf('Error Matrix:\n');
disp(error_matrix);
fprintf('Overall Accuracy (OA): %.4f\n', OA);
fprintf("Producer\'s Accuracy (PA): %.4f, %.4f, %.4f, %.4f, %.4f\n", PA(1), PA(2), PA(3), PA(4), PA(5));
fprintf("User\'s Accuracy (UA): %.4f, %.4f, %.4f, %.4f, %.4f\n", UA(1), UA(2), UA(3), UA(4), UA(5));
fprintf('K_hat: %.4f\n\n', K_hat);
