%% Classification TSK(Takagi Sugeno Kang) Model
clear; % clear variables
close all; % close figures

% Load Dataset
data = load('Datasets/haberman.data'); % 3 attributes, 1 label (4 columns)

% Set random seed for reproducibility
rng(0);

% Split - Preprocess Data
addpath('Assignment4');
[trnData, chkData, tstData] = split_scale(data, 1);

%  Extract features and labels
trnX = trnData(:, 1:end-1);
trnY = trnData(:, end);
chkX = chkData(:, 1:end-1);
chkY = chkData(:, end);
tstX = tstData(:, 1:end-1);
tstY = tstData(:, end);

%% 4 TSK Models with different number of IF-THEN rules each
% 2 class dependant clustering 
% 2 class independent clustering
% all singletons
% cluster size parameter should get extreme values to show change
% Hybrid training: mf parameters are updated through backpropagation, output parameters are updated through least squares

cluster_radius = [0.2, 0.4, 0.6, 0.8, 0.2, 0.4, 0.6, 0.8]; % Number of rules

for i=1:length(cluster_radius) 
    fprintf('\n#### Model: %d ####\n', i);
    % Divide input space through Subtractive clustering 
    if i <= length(cluster_radius)/2
        options = genfisOptions('SubtractiveClustering','ClusterInfluenceRange', cluster_radius(i));

        inFIS = genfis(trnX, trnY, options);

        % Number of rules
        num_rules = length(inFIS.rule);

        % ANFIS (Adaptive Neuro Fuzzy Inference System)
        epochs = 100; % Number of epochs
        opt = anfisOptions(...
            'InitialFIS', inFIS, ... % Initial FIS
            'EpochNumber', epochs, ... % Number of epochs
            'OptimizationMethod', 1, ... % Hybrid training: backpropagation to compute input membership function parameters, and least squares estimation to compute output membership function parameters
            'ValidationData', [chkX, chkY],... % Validation data
            'DisplayStepSize', 0,... % Don't display step size
            'DisplayErrorValues', 0,... % Don't display error values
            'DisplayANFISInformation', 0); % Don't display ANFIS information

        % Train the model
        [fis, trainError, stepSize, chkFIS, chkError] = anfis([trnX, trnY], opt);

        % Evaluate the model on the test set
        Y_pred_test = evalfis(chkFIS, tstX);
    else
        classes = [1, 2]; % Dataset classes: Class 1: y=1, Class 2: y=2
        % subclust
        % args: data, radius
        % returns: cluster centers, sigmas
        [c1,sig1]=subclust(trnData(tstY==1,:),cluster_radius(i)); % data: samples where label is 1
        [c2,sig2]=subclust(trnData(tstY==2,:),cluster_radius(i)); % data: samples where label is 2
        
        % Number of rules
        num_rules = size(c1,1) + size(c2,1);

        % Build FIS From Scratch
        fis=sugfis('Name','FIS_SC');

        % Add Input-Output Variables
        names_in={'in1','in2','in3'};
        for j=1:size(trnData,2)-1
            fis=addInput(fis,[0 1],'Name',names_in{j});
        end
        fis=addOutput(fis,[0 1],'Name','out1');

        % Add Input Membership Functions
        name='sth';
        for j=1:size(trnData,2)-1
            for k=1:size(c1,1)
                fis=addMF(fis,names_in{j},'gaussmf',[sig1(j) c1(k,j)]);
            end
            for k=1:size(c2,1)
                fis=addMF(fis,names_in{j},'gaussmf',[sig2(j) c2(k,j)]);
            end
        end

        % Add Output Membership Functions
        params=[zeros(1,size(c1,1)) ones(1,size(c2,1))];
        for j=1:num_rules
            fis=addMF(fis,'out1','constant',params(j));
        end

        % Add FIS Rule Base
        ruleList=zeros(num_rules,size(trnData,2));
        for j=1:size(ruleList,1)
            ruleList(j,:)=j;
        end
        ruleList=[ruleList ones(num_rules,2)];
        fis=addRule(fis,ruleList);

        % ANFIS (Adaptive Neuro Fuzzy Inference System)
        epochs = 100; % Number of epochs
        opt = anfisOptions(...
            'InitialFIS', fis, ... % Initial FIS
            'EpochNumber', epochs, ... % Number of epochs
            'OptimizationMethod', 1, ... % Hybrid training: backpropagation to compute input membership function parameters, and least squares estimation to compute output membership function parameters
            'ValidationData', [chkX, chkY],... % Validation data
            'DisplayStepSize', 0,... % Don't display step size
            'DisplayErrorValues', 0,... % Don't display error values
            'DisplayANFISInformation', 0); % Don't display ANFIS information
        % Train the model
        [fis, trainError, stepSize, chkFIS, chkError] = anfis(trnData,opt);

        % Evaluate the model on the test set
        Y_pred_test = evalfis(chkFIS, tstX);
    end

    % Plot the fuzzy set after training
    figure;
    subplot(1, 3, 1);
    plotmf(chkFIS, 'input', 1); % Plot membership functions for the first input
    if i <= length(cluster_radius)/2
       title(sprintf('Fuzzy Set after Training (Cluster Radius: %.2f)\n Clustering Type: Class Independent', cluster_radius(i)));
    else
        title(sprintf('Fuzzy Set after Training (Cluster Radius: %.2f)\n Clustering Type: Class Dependent', cluster_radius(i)));
    end
    xlabel('Input Value');
    ylabel('Membership Degree');
    grid on;
    subplot(1, 3, 2);
    plotmf(chkFIS, 'input', 2); % Plot membership functions for the second input
    if i <= length(cluster_radius)/2
       title(sprintf('Fuzzy Set after Training (Cluster Radius: %.2f)\n Clustering Type: Class Independent', cluster_radius(i)));
    else
        title(sprintf('Fuzzy Set after Training (Cluster Radius: %.2f)\n Clustering Type: Class Dependent', cluster_radius(i)));
    end
    xlabel('Input Value');
    ylabel('Membership Degree');
    grid on;
    subplot(1, 3, 3);
    plotmf(chkFIS, 'input', 3); % Plot membership functions for the third input
    if i <= length(cluster_radius)/2
       title(sprintf('Fuzzy Set after Training (Cluster Radius: %.2f)\n Clustering Type: Class Independent', cluster_radius(i)));
    else
        title(sprintf('Fuzzy Set after Training (Cluster Radius: %.2f)\n Clustering Type: Class Dependent', cluster_radius(i)));
    end
    xlabel('Input Value');
    ylabel('Membership Degree');
    grid on;

    % Plot error vs iterations
    figure;
    plot(trainError, 'b-', 'LineWidth', 2);
    hold on;
    plot(chkError, 'r-', 'LineWidth', 2);
    xlabel('Epochs');
    ylabel('Error');
    if i <= length(cluster_radius)/2
       title(sprintf('Training and Validation Error (Cluster Radius: %.2f)\n Clustering Type: Class Independent', cluster_radius(i)));
    else
        title(sprintf('Training and Validation Error (Cluster Radius: %.2f)\n Clustering Type: Class Dependent', cluster_radius(i)));
    end
    legend('Training Error', 'Validation Error');

    % Error matrix kxk, where k=numofclasses 
    % Columns: Real, Rows: Predicted (Diagonal->True Positives)
    % Generate error matrix 2x2 - Class 1: y=1, Class 2: y=2
    error_matrix = zeros(2, 2);

    for k = 1:length(Y_pred_test)
        % Round predicted class to the nearest integer
        predicted = round(Y_pred_test(k));
        actual = tstY(k);

        % Keep within class limits
        if predicted < 1
            predicted = 1; % Ensure minimum class is 1
        elseif predicted > 2
            predicted = 2; % Ensure maximum class is 2
        end
        
        % Update error matrix
        error_matrix(predicted, actual) = error_matrix(predicted, actual) + 1;
    end

    % Performance metrics
    OA = sum(diag(error_matrix)) / sum(error_matrix(:)); % Overall Accuracy
    PA = diag(error_matrix) ./ sum(error_matrix, 2); % Producer's Accuracy
    UA = diag(error_matrix) ./ sum(error_matrix, 1)'; % User's Accuracy
    K_hat = (sum(error_matrix(:)) * sum(diag(error_matrix)) - sum(sum(error_matrix, 1) .* sum(error_matrix, 2))) / (sum(error_matrix(:))^2 - sum(sum(error_matrix, 1) .* sum(error_matrix, 2)));

    % Display performance metrics
    if i <= length(cluster_radius)/2
        fprintf('Clustering Type: Class Independent\n');
    else
        fprintf('Clustering Type: Class Dependent\n');
    end
    fprintf('Cluster Radius: %.2f\n', cluster_radius(i));
    fprintf('Number of Rules: %d\n', num_rules);
    fprintf('Error Matrix:\n');
    disp(error_matrix);
    fprintf('Overall Accuracy (OA): %.4f\n', OA);
    fprintf("Producer\'s Accuracy (PA): %.4f, %.4f\n", PA(1), PA(2));
    fprintf("User\'s Accuracy (UA): %.4f, %.4f\n", UA(1), UA(2));
    fprintf('K_hat: %.4f\n\n', K_hat);
end
