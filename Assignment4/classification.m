%% Classification TSK(Terrace Step Kink) Model
% Load Dataset
data = load('Datasets/haberman.data');

% Split - Preprocess Data
[trnData, chkData, tstData] = split_scale(data, 1);

%  Extract features and labels
X_trn = trnData(:,1:end-1);
Y_trn = trnData(:,end);
X_val = chkData(:,1:end-1);  % Using chkData as validation set
Y_val = chkData(:,end);
X_chk = tstData(:,1:end-1);  % Using tstData as test set
Y_chk = tstData(:,end);

% Check class distribution
fprintf('Training set class distribution: %s\n', mat2str(histcounts(Y_trn)/length(Y_trn)));
fprintf('Validation set class distribution: %s\n', mat2str(histcounts(Y_val)/length(Y_val)));
fprintf('Test set class distribution: %s\n', mat2str(histcounts(Y_chk)/length(Y_chk)));