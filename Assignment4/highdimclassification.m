%% High demensionality Dataset Classification TSK(Takagi Sugeno Kang) Model
% Load Dataset
data = load('Datasets/epileptic_seizure_data.csv'); % 179 attributes, 1 label, 11500 samples

% Set random seed for reproducibility
rng(0);

% Split - Preprocess Data
[trnData, chkData, tstData] = split_scale(data, 1); % 60% training, 20% validation, 20% test

%  Extract features and labels
X_trn = trnData(:,1:end-1);
Y_trn = trnData(:,end);
X_val = chkData(:,1:end-1);
Y_val = chkData(:,end);
X_chk = tstData(:,1:end-1);
Y_chk = tstData(:,end);

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

%% Grid Search Plots
% RMSE vs Number of Features
% RMSE vs Cluster Radius

%% Optimal Model Training
% Train the model with the best parameters found in the grid search

%% Optimal Model Evaluation

%% Optimal Model Plots
% Real vs Predicted labels
% Error vs Iterations
% Fuzzy sets before vs after training (endeiktika)
% Performance metrics table (OA, PA, UA, K_hat)
