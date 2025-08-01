% Optimal parameters found through 5-fold cross-validation in highdimregression.m
best_radius = 0.4; % Optimal cluster radius
best_num_features = 20; % Optimal number of features

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

epochs = 20; % Number of epochs for training

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