%% Main
% Mark s as a transfer function variable
s = tf('s');

% Controller Parameters
K = 30; % Controller's Gain
c = 0.3; % Controller's Zero

% Open Loop System
A = (s+c)*K / (s*(s+0.1)*(s+10));

% Closed Loop System
Ac = feedback(A, 1, -1);

% Root Locus of the Open Loop Transfer Function
plotRootLocus(A);

% System Information about the Closed Loop Transfer Function
printSysInfo(Ac);

%% Functions
% Analyze closed loop system
function viable = checkViability(A)
    % Display step response information
    info = stepinfo(A);
    % disp(info);

    % Check if the system meets the specifications
    if (info.Overshoot < 8) && (info.RiseTime < 0.6)
        %disp('The system is within the specifications.');
        viable = true;
    else
        %disp('The system is NOT within the specifications.');
        viable = false;
    end
end

% Create a CSV file containing all viable (K, c) pairs based on the specifications
function createViableckCSV()
    % Mark s as a transfer function variable
    s = tf('s');
    viableCK = {};
    iter = 1;
    for K = 0:1:100
        for c = 0.1:0.1:10
            % Open Loop System
            A = (s+c)*K / (s*(s+0.1)*(s+10));

            % Closed Loop System
            Ac = feedback(A, 1, -1);

            % Insert viable  values for K and c
            if checkViability(Ac)
                viableCK{iter}=[c, K];
                iter = iter + 1;
            end
        end
    end

    if ~isempty(viableCK)
        % Convert cell array to Nx2 matrix
        dataMatrix = cell2mat(viableCK');
        
        % Create table with headers
        dataTable = array2table(dataMatrix, 'VariableNames', {'K_gain', 'c_zero'});
        
        % Write to CSV file
        writetable(dataTable, 'viableck.csv');
        
        disp(['Successfully exported ', num2str(size(dataMatrix,1)), ...
            ' viable (K,c) pairs to viable_controller_parameters.csv']);
    else
        disp('No viable parameter pairs found');
    end
end

% Root Locus
function plotRootLocus(A)
    % Plot the root locus of the open loop system
    figure;
    rlocus(A);
    title('Root Locus of A(s) [OLTF]');

    % % Just the poles and the zero of the open loop system
    % figure;
    % pzmap(A);
    % title('Poles and Zeros of A(s)');
end

% Print system information (poles, zeros, gain)
function printSysInfo(A)
    % Print rise time and overshoot
    info = stepinfo(A);
    fprintf('Step Response Information\n');
    fprintf('-------------------------\n');
    fprintf('Rise Time: %.4f seconds\n', info.RiseTime);
    fprintf('Overshoot: %.2f%%\n\n', info.Overshoot);
    
    % Fetch poles, zeros, and gain via zpkdata()
    [z, p, k] = zpkdata(A, 'v');

    % Poles
    fprintf('Root Locus Poles\n');
    fprintf('----------------\n');
    for i = 1:length(p)
        if imag(p(i)) ~= 0
            fprintf('Pole %d: %.4f + %.4fi\n', i, real(p(i)), imag(p(i)));
        else
            fprintf('Pole %d: %.4f\n', i, real(p(i)));
        end
    end

    % Zeros
    fprintf('\nRoot Locus Zeros\n');
    fprintf('------------------\n');
    for i = 1:length(z)
        if imag(z(i)) ~= 0
            fprintf('Zero %d: %.4f + %.4fi\n', i, real(z(i)), imag(z(i)));
        else
            fprintf('Zero %d: %.4f\n', i, real(z(i)));
        end
    end
    if isempty(z)
        fprintf('No zeros in the system.\n');
    end

    % Gain
    fprintf('\nRoot Locus Gain\n');
    fprintf('-----------------\n');
    fprintf('Gain: %.4f\n\n', k);
end