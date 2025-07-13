%% Regrssion (Takagi Sugeno Kang) Model
% Load Dataset
data = load('Datasets/airfoil_self_noise.dat');

% Split - Preprocess Data
addpath('Assignment3');
[trnData, chkData, tstData] = split_scale(data, 1);

% Models: model_name, numMFs, outputType
models = {
    'TSK_{model 1}', 2, 'constant';   % Singleton output
    'TSK_{model 2}', 3, 'constant';   % Singleton output
    'TSK_{model 3}', 2, 'linear';     % Polynomial output
    'TSK_{model 4}', 3, 'linear'      % Polynomial output
};

% Number of epochs
epochs = 100;

% Store performance metrics
results = [];

% Loop over all models
for i = 1:size(models,1)-1
    % Extract model parameters from the cell array
    model_name = models{i,1};
    numMFs = models{i,2};
    outType = models{i,3};

    fprintf('\n========== %s ==========\n', model_name);
    fprintf('MFs per input: %d | Output type: %s\n', numMFs, outType);

    % Generate FIS (Fuzzy Inference System)
    opt = genfisOptions('GridPartition');
    % Number of membership functions
    opt.NumMembershipFunctions = numMFs;
    % Bell shaped membership functions
    opt.InputMembershipFunctionType = 'gbellmf';
    % Output membership function type
    opt.OutputMembershipFunctionType = outType;

    % Generate initial FIS
    init_fis = genfis(trnData(:,1:end-1), trnData(:,end), opt);

    % ANFIS (Adaptive Neuro Fuzzy Inference System)
    % Generates a single-output Sugeno fuzzy inference system (FIS)
    [fis, trainError, ~, valfis, valError] = anfis(trnData, init_fis, epochs, [0 0 0 0], chkData, 2);
    
    % If chkFIS is invalid, fallback
    if ~isfis(chkFIS)
        chkFIS = fis;
    end

    % Evaluation
    y_pred = evalfis(chkFIS, tstData(:,1:end-1));
    y_true = tstData(:,end);
    error = y_true - y_pred;

    % Performance metrics
    mse = mean(error.^2); % Mean Squared Error
    rmse = sqrt(mse); % Root Mean Square Error
    nmse = mse / var(y_true, 1);  % Normalized Mean Squared Error
    ndei = sqrt(nmse); % Normalized Deviation Error Index

    r2 = 1 - mse/sum((y_true - mean(y_true)).^2);
    
    % Store results
    results = [results; {model_name, numMFs, outType, rmse, nmse, ndei, r2}];

    % Plot 1: Membership Functions After Training
    figure('Name', [model_name ' - Membership Functions']);
    numInputs = numel(chkFIS.Inputs);

    for j = 1:numInputs
        subplot(2, ceil(numInputs/2), j);
        [x, mf] = plotmf(chkFIS, 'input', j);
        plot(x, mf);
        title(['Input ' num2str(j) ' - MFs']);
        xlabel(['x' num2str(j)]);
        ylabel('μ');
        grid on;
    end

    % Plot 2: Learning Curve
    figure('Name', [model_name ' - Learning Curve']);
    plot(trainError, 'b', 'LineWidth', 1.5); hold on;  % Add hold on here
    plot(valError, 'r--', 'LineWidth', 1.5);
    title(['Learning Curve - ' model_name]);
    xlabel('Epoch');
    ylabel('RMSE');
    legend('Training Error', 'Validation Error');
    grid on;

    % Plot 3: Prediction Error
    figure('Name', [model_name ' - Prediction Errors']);
    subplot(2,1,1);
    plot(y_true, 'b'); hold on;
    plot(y_pred, 'r--');
    title(['True vs Predicted - ' model_name]);
    legend('True', 'Predicted');
    ylabel('Sound Pressure (dB)');
    grid on;

    subplot(2,1,2);
    plot(error, 'k');
    title('Prediction Error');
    xlabel('Sample Index');
    ylabel('Error (dB)');
    grid on;
end

% Display Final Results Table
% Column titles
headers = {'Model', 'NumMFs', 'OutputType', 'RMSE', 'NMSE', 'NDEI', 'R^2'};

% Convert results to table
results_table = cell2table(results, 'VariableNames', headers);

% Display
disp('========== Final Performance Table ==========');
disp(results_table);