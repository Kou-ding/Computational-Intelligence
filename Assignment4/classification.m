%% Classification TSK(Takagi Sugeno Kang) Model
% Load Dataset
data = load('Datasets/haberman.data'); % 3 attributes, 1 label (4 columns)

% Set random seed for reproducibility
rng(0);

% Split - Preprocess Data
[trnData, chkData, tstData] = split_scale(data, 1);

%  Extract features and labels
X_trn = trnData(:,1:end-1);
Y_trn = trnData(:,end);
X_val = chkData(:,1:end-1);
Y_val = chkData(:,end);
X_chk = tstData(:,1:end-1);
Y_chk = tstData(:,end);

%% 4 TSK Models with different number of IF-THEN rules each
% 2 class dependant clustering 
% 2 class independent clustering
% all singletons
% cluster size parameter should get extreme values to show change
% Hybrid training: mf parameters are updated through backpropagation, output parameters are updated through least squares

% Divide input space through Subtractive clustering 
numRulesList = [2, 3, 4, 5]; % Number of rules

%% Model Performance
% Error matrix kxk, where k=numofclasses 
% Columns: Real, Rows: Predicted (Diagonal->True Positives)
% Overall Accuracy = OA = (correct predictions) / (total predictions) = OA = (1/N) * sum(xii) from i=1 to k
% Producer's accuracy = PA = x_jj / x_jc
% User's accuracy = UA = x_ii / x_ir
% K_hat = (N*sum(x_ii)) - sum((x_ir)(x_ic))) / (N^2 - sum((x_ic)(x_ir)))

%% Plots
% fuzzy set after training
% error vs iterations
% peformance metrics table
