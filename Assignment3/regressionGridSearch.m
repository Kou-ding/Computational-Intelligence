%% Regrssion (Takagi Sugeno Kang) Model
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
numFeaturesList = [5, 10, 20, 30]; % Number of features
radiusList = [0.2, 0.4, 0.6, 0.8]; % cluster radius
k = 5; % cross-validation folds

bestRMSE = inf;

fprintf('Starting grid search...\n');

for nf = numFeaturesList
    % Rank importance of predictors using ReliefF (10 nearest neighbors)
    [ranked, ~] = relieff(trnX, trnY, 10);
    selIdx = ranked(1:nf);
    
    trnX_sel = trnX(:, selIdx);
    
    for ra = radiusList
        % Initialize array to store RMSE for each fold
        RMSE_folds = zeros(k, 1);
        % Create k-fold cross-validation partition
        cv = cvpartition(size(trnX_sel,1), 'KFold', k);
        
        for i = 1:k
            % Split for fold
            Xtrain = trnX_sel(cv.training(i), :);
            Ytrain = trnY(cv.training(i));
            Xval = trnX_sel(cv.test(i), :);
            Yval = trnY(cv.test(i));
            
            try
                fis = genfis2(Xtrain, Ytrain, ra);
                [trnFis, ~] = anfis([Xtrain Ytrain], fis, 50, [0 0 0 0], [Xval Yval]);
                Ypred = evalfis(trnFis, Xval);
                RMSE_folds(i) = sqrt(mean((Ypred - Yval).^2));
            catch
                RMSE_folds(i) = inf;
            end
        end
        
        avgRMSE = mean(RMSE_folds);
        fprintf('Features: %2d | Radius: %.2f | AvgRMSE: %.4f\n', nf, ra, avgRMSE);
        
        % Update best parameters if current RMSE is lower
        if avgRMSE < bestRMSE
            bestRMSE = avgRMSE;
            bestParams.numFeatures = nf;
            bestParams.radius = ra;
        end
    end
end
% Plots regarding all models
% Plot error vs number of rules
figure;

% Plot error vs number of features
figure;

% Display best parameters
fprintf('Best Parameters -> Features: %d, Radius: %.2f, CV-RMSE: %.4f\n', ...
    bestParams.numFeatures, bestParams.radius, bestRMSE);

% Train Final Model with Best Parameters
fprintf('Training final model with best parameters...\n');

[ranked, ~] = relieff(trnX, trnY, 10);
selIdx = ranked(1:bestParams.numFeatures);

trnX_sel = trnX(:, selIdx);
chkX_sel = chkX(:, selIdx);
tstX_sel = tstX(:, selIdx);

fis = genfis2(trnX_sel, trnY, bestParams.radius);
finalFis = anfis([trnX_sel trnY], fis, 100);

% Predict on Test Set
Ypred_test = evalfis(finalFis, tstX_sel);
rmse_test = sqrt(mean((Ypred_test - tstY).^2));

% Plots regarding the optimal model
% Plot real vs predicted values
figure;

% Plot error vs iterations
figure;

% Display table including RMSE, NMSE, NDEI, R^2
fprintf('###### Performance metrics ######\n');

fprintf('Final RMSE on test set: %.4f\n', rmse_test);