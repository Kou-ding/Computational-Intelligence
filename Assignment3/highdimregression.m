%% High demensionality Dataset Regression TSK(Takagi Sugeno Kang) Model
clear; % clear variables 
close all; % close figures

% Load Dataset
data = load('Datasets/superconduct.csv');

% Set random seed for reproducibility
rng(0);

% Split - Preprocess Data
addpath('Assignment3');
[trnData, chkData, tstData] = split_scale(data, 1);

trnX = trnData(:, 1:end-1);
trnY = trnData(:, end);
chkX = chkData(:, 1:end-1);
chkY = chkData(:, end);
tstX = tstData(:, 1:end-1);
tstY = tstData(:, end);

% Grid Search Parameters
num_features_list = [5, 10, 15, 20]; % Number of features
radius_list = [0.2, 0.4, 0.6, 0.8]; % cluster radius
k = 5; % cross-validation folds

% Matrix to store the average RMSE for each (feature_index, radius_index) combination
RMSE_matrix = zeros(length(num_features_list), length(radius_list)); 
% Matrix to store the number of rules for each (feature_index, radius_index) combination
rules_matrix = zeros(length(num_features_list), length(radius_list));

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

        % Create k-fold cross-validation partition
        cv = cvpartition(size(selected_trnX,1), 'KFold', k);
        
        % Iterate over each fold
        for i = 1:k
            % Split data into training and validation sets
            kfold_trnX = selected_trnX(cv.training(i), :);
            kfold_trnY = trnY(cv.training(i));
            kfold_chkX = selected_trnX(cv.test(i), :);
            kfold_chkY = trnY(cv.test(i));

            % Clip values to the range [0, 1]
            kfold_trnX = min(max(kfold_trnX, 0), 1);
            kfold_chkX = min(max(kfold_chkX, 0), 1);
            
            % Generate FIS from the selected number of features and radius
            % Uses subtractive clustering and the range of influence of the cluster centers is equal to radius_list(radius_index)
            options = genfisOptions('SubtractiveClustering', 'ClusterInfluenceRange', radius_list(radius_index));
            fis = genfis(kfold_trnX, kfold_trnY, options);
            % Deprecated atlernative
            % fis = genfis2(kfold_trnX, kfold_trnY, radius_list(radius_index));
            
            % Store the number of rules for the current fold
            kfold_num_rules(i) = length(fis.rule);

            % Train the FIS using ANFIS
            [trnFis, ~] = anfis([kfold_trnX kfold_trnY], fis, 50, [0 0 0 0], [kfold_chkX kfold_chkY]);
            % Evaluate the FIS on the validation set
            Ypred = evalfis(trnFis, kfold_chkX);
            kfold_RMSE_list(i) = sqrt(mean((Ypred - kfold_chkY).^2));
        end
        
        % Calculate average RMSE for the current (num_features, radius) combination
        RMSE_matrix(feature_index,radius_index) = mean(kfold_RMSE_list);

        % Calculate average number of rules for the current (num_features, radius) combination
        rules_matrix(feature_index,radius_index) = mean(kfold_num_rules);

        % Display the results
        fprintf('Features: %2d | Radius: %.2f | AvgRMSE: %.4f | AvgRules: %.4f\n', num_features_list(feature_index), radius_list(radius_index), RMSE_matrix(feature_index,radius_index), rules_matrix(feature_index,radius_index));
    end
end

% Find the min RSME from the RMSE matrix
[minRMSE, minIdx] = min(RMSE_matrix(:));
% Convert linear index to row and column indices
[row, col] = ind2sub(size(RMSE_matrix), minIdx);
best_num_features = num_features_list(row);
best_radius = radius_list(col);
fprintf('Minimum RMSE: %.4f at Features: %d, Radius: %.2f\n', minRMSE, best_num_features, best_radius);

% Plots regarding all models
% Plot error vs number of rules
figure;
for i = 1:1:length(num_features_list)
    for j = 1:1:length(radius_list)
        plot(rules_matrix(i,j), RMSE_matrix(i,j), 'bo');
        hold on;
    end
end
xlabel('Number of Rules');
ylabel('RMSE');
title('Error vs Number of Rules');

% Plot error vs number of features
figure;
for i = 1:length(radius_list)
    subplot(1, length(radius_list), i);
    plot(num_features_list, RMSE_matrix(:,i), 'bo');
    xlabel('Number of Features');
    ylabel('RMSE');
    title(sprintf('Error vs Number of Features (Radius: %.2f)', radius_list(i)));
    grid on;
end

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

epochs = 45; % Number of epochs for training

% Set ANFIS options
opt = anfisOptions(...
    'InitialFIS', inFIS, ... % Initial FIS
    'EpochNumber', epochs, ... % Number of epochs
    'ValidationData', [final_chkX chkY]);  % Validation data
[fis, trainError, stepSize, chkFIS, chkError] = anfis([final_trnX trnY], opt);

% Predict on Test Set
Ypred_test = evalfis(chkFIS, final_tstX);
rmse_test = sqrt(mean((Ypred_test - tstY).^2));
error = tstY - Ypred_test;

% Performance metrics
mse = mean(error.^2); % Mean Squared Error
rmse = sqrt(mse); % Root Mean Square Error
nmse = mse / var(tstY, 1);  % Normalized Mean Squared Error
ndei = sqrt(nmse); % Normalized Deviation Error Index
r2 = 1 - sum(error.^2)/sum((tstY - mean(tstY)).^2);

% Plots regarding the optimal model
% Plot real vs predicted values
figure;
scatter(tstY, Ypred_test, 10, 'filled');
hold on;
plot([min(tstY), max(tstY)], [min(tstY), max(tstY)], 'k--', 'LineWidth', 1.5); % 45° reference line
xlabel('True Values');
ylabel('Predicted Values');
title('Predicted vs True Values on Test Set');
grid on;
axis equal;
xlim([min(tstY), max(tstY)]);
ylim([min(tstY), max(tstY)]);

% Plot error vs iterations
figure;
plot(trainError, 'b', 'LineWidth', 1.5); hold on;
plot(chkError, 'r', 'LineWidth', 1.5);
xlabel('Epoch');
ylabel('RMSE');
title('Training and Validation Learning Curve');
legend('Training Error', 'Validation Error');
grid on;

% Display table including RMSE, NMSE, NDEI, R^2
fprintf('\n###### Performance metrics ######\n');
fprintf('Final RMSE on test set: %.4f\n', rmse);
fprintf('Final NMSE on test set: %.4f\n', nmse);
fprintf('Final NDEI on test set: %.4f\n', ndei);
fprintf('Final R^2 on test set: %.4f\n', r2);
fprintf('Final number of Rules: %d\n', length(chkFIS.rule));
