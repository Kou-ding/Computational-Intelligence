%% Regrssion TSK(Terrace Step Kink) Model
% Load Dataset
data = load('Datasets/airfoil_self_noise.dat');

% Split - Preprocess Data
[trnData, chkData, tstData] = split_scale(data, 1);

% Train TSK model
opt = genfisOptions('GridPartition');
opt.NumMembershipFunctions = 2;
opt.InputMembershipFunctionType = 'gbellmf';
opt.OutputMembershipFunctionType = 'constant';

init_fis = genfis(trnData(:,1:end-1), trnData(:,end), opt);

% Train with ANFIS
epochs = 100;
[tsk_model, trainError, ~, valError, chkFIS] = anfis(trnData, init_fis, epochs, [0 0 0 0], chkData, 1);

% Evaluate
if ~isfis(chkFIS)
    chkFIS = tsk_model;
end

y_pred = evalfis(tstData(:,1:end-1), chkFIS);

% Calculate metrics
rmse = sqrt(mean((tstData(:,end) - y_pred).^2));
r2 = 1 - sum((tstData(:,end) - y_pred).^2)/sum((tstData(:,end) - mean(tstData(:,end))).^2);

% Display results
disp('Evaluation Results:');
disp('-------------------');
disp(['RMSE: ' num2str(rmse)]);
disp(['R²: ' num2str(r2)]);

% Plot
figure;
plot(Dchk(:,6), 'b'); hold on;
plot(y_pred, 'r--');
legend('Real', 'Prediction');
title('Real vs Predicted Values');
xlabel('Sample Index');
ylabel('Sound Pressure (dB)');