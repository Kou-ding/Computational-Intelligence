%% Regrssion (Takagi Sugeno Kang) Model
% Load Dataset
data = load('Datasets/airfoil_self_noise.dat');

% Set random seed for reproducibility
rng(0);

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
% Columns: Model, Training Time, RMSE, NMSE, NDEI, R^2
% Rows: number of models
results = [];

% Training times
training_times = zeros(size(models, 1), 1);

% Loop over all models
for i = 1:size(models,1)
    % Extract model parameters from the cell array
    model_name = models{i,1};
    numMFs = models{i,2};
    outType = models{i,3};

    fprintf('\n========== %s ==========\n', model_name);
    fprintf('MFs per input: %d | Output type: %s\n', numMFs, outType);

    % Generate FIS (Fuzzy Inference System)
    genopt = genfisOptions('GridPartition');
    % Number of membership functions
    genopt.NumMembershipFunctions = numMFs;
    % Bell shaped membership functions
    genopt.InputMembershipFunctionType = 'gbellmf';
    % Output membership function type
    genopt.OutputMembershipFunctionType = outType;

    % Start the timer
    tic;
    
    % Generate initial FIS
    inFIS = genfis(trnData(:,1:end-1), trnData(:,end), genopt);

    % ANFIS (Adaptive Neuro Fuzzy Inference System)
    % Set ANFIS options
    opt = anfisOptions(...
        'InitialFIS', inFIS, ... % Initial FIS
        'EpochNumber', epochs, ... % Number of epochs
        'ValidationData', chkData);  % Validation data

    % Generates a single-output Sugeno fuzzy inference system (FIS)
    [fis, trainError, stepSize, chkFIS, chkError] = anfis(trnData, opt);

    % Record the training time
    training_times(i) = toc;

    % Evaluation
    y_pred = evalfis(chkFIS, tstData(:,1:end-1)); % all columns except last
    y_true = tstData(:,end); % last column
    error = y_true - y_pred;

    % Performance metrics
    mse = mean(error.^2); % Mean Squared Error
    rmse = sqrt(mse); % Root Mean Square Error
    nmse = mse / var(y_true, 1);  % Normalized Mean Squared Error
    ndei = sqrt(nmse); % Normalized Deviation Error Index

    r2 = 1 - mse/sum((y_true - mean(y_true)).^2);
    
    % Store results
    results = [results; {model_name, training_times(i), rmse, nmse, ndei, r2}];

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

    % Plot 2-3: Learning Curve
    figure('Name', [model_name ' - Learning Curve']);
    plot(trainError, 'b', 'LineWidth', 1.5); hold on;
    plot(chkError, 'r', 'LineWidth', 1.5);
    title(['Learning Curve - ' model_name]);
    xlabel('Epoch');
    ylabel('RMSE');
    legend('Training Error', 'Validation Error');
    grid on;

end

% Display Final Results Table
% Column titles
headers = {'Model', 'Training Time', 'RMSE', 'NMSE', 'NDEI', 'R^2'};

% Convert results to table
results_table = cell2table(results, 'VariableNames', headers);

% Display
fprintf('\n============================== Final Performance Table ==============================\n\n');
disp(results_table);