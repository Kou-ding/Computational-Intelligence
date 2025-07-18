%% Classification TSK(Takagi Sugeno Kang) Model
% Load Dataset
data = load('Datasets/haberman.data');

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

