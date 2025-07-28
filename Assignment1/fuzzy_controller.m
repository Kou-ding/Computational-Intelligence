%% Fuzzy PI Controller
addpath('Assignment1'); % Add the folder containing initFIS.m
% Initialize the Fuzzy Inference System (FIS)
fis = initFIS();

%% System and Simulation 


% Time parameters
Ts = 0.01; % Sampling period
total_time = 20; % Total simulation time in seconds
t = 0:Ts:total_time; % Time resolution


% Signal 0 (Step function)
sig0 = 50 * ones(size(t)); % Reference signal

% Signal 1
sig1 = zeros(size(t));
sig1(t <= 5) = 50;
sig1(t > 5 & t <= 10) = 18;
sig1(t > 10) = 35;

% Signal 2
sig2 = zeros(size(t));
sig2(t <= 5) = linspace(0.4, 50, sum(t <= 5));
sig2(t > 5 & t <= 10) = 50;
sig2(t > 10) = linspace(50, 0.4, sum(t > 10));

mySimulation(fis, sig1, Ts, t);
function mySimulation(fis, w, Ts, t)
    % Mark s as a transfer function variable
    s = tf('s');

    % Fuzzy PI Parameters
    K = 30; % Controller's Gain
    c = 0.3; % Controller's Zero
    Kp = 30; % Proportional Gain
    Ki = 9; % Integral Gain
    Ke = 0.001; % Error Gain (0.002 also good value)
    Kd = 0.0002; % dError Gain
    K1 = 80; % Fuzzy PI Gain (90 also good value)

    % Plant
    plant = ((s+c)*K)/(s*(s+0.1)*(s+10));
    % plant = feedback(plant, 1, -1); % Closed loop system
    % step(plant);  % Verify if the plant responds as expected
    plant = c2d(plant, Ts, 'tustin'); % Continuous to discrete conversion

    % Preallocate arrays for simulation results
    e = zeros(size(t)); % Error signal
    e_scaled = zeros(size(t)); % Scaled error
    de_scaled = zeros(size(t)); % Scaled error derivative
    de = zeros(size(t)); % Error derivative
    y = zeros(size(t)); % Plant output
    u = zeros(size(t)); % Plant input (control signal)

    % Simulation
    for k = 2:length(t)
        % Error signal
        e(k) = w(k) - y(k-1); 
        
        % Error derivative
        de(k) = (e(k) - e(k-1))/Ts;

        % Scale FIS inputs to fuzzy range [-1, 1]
        e_scaled(k) = min(max(e(k)*Ke, -1), 1);
        de_scaled(k) = min(max(de(k)*Kd, -1), 1); 

        % Fuzzy Logic Controller
        du = evalfis(fis, [e_scaled(k), de_scaled(k)]);

        % Fuzzy PI output
        u(k) = u(k-1) + K1*du;

        % Simulate the plant output
        y_temp = lsim(plant, u(1:k), t(1:k));
        y(k) = y_temp(end);

        % Debugging prints for the first few iterations
        if k<4
            disp('| k | E | dE | E_scaled | dE_scaled | dU | U | y |');
            disp('--------------------------------------------------');
            fprintf('| %d | %.4f | %.4f | %.4f | %.4f | %.4f | %.4f | %.4f |\n\n', k, e(k), de(k), e_scaled(k), de_scaled(k), du, u(k), y(k));
        end
    end
    % Calculate performance metrics
    % Find settling time (2% criterion)
    steady_state = w(end); % Final reference value
    settling_tolerance = 0.02 * steady_state;
    settling_idx = find(abs(y - steady_state) <= settling_tolerance, 1, 'first');
    settling_time = t(settling_idx);

    % Find overshoot
    max_output = max(y);
    overshoot_percent = ((max_output - steady_state) / steady_state) * 100;

    % Find rise time (10% to 90% of final value)
    rise_10_percent = 0.1 * steady_state;
    rise_90_percent = 0.9 * steady_state;
    rise_start_idx = find(y >= rise_10_percent, 1, 'first');
    rise_end_idx = find(y >= rise_90_percent, 1, 'first');
    rise_time = t(rise_end_idx) - t(rise_start_idx);

    % Display results
    fprintf('\nPerformance Metrics');
    fprintf('-------------------\n');
    fprintf('Overshoot: %.2f%%\n', overshoot_percent);
    fprintf('Rise Time: %.4f seconds\n', rise_time);
    fprintf('Settling Time: %.4f seconds\n', settling_time);
    fprintf('Maximum Output: %.4f rad/sec\n', max_output);

    figure;
    plot(t, w, 'k--', t, y, 'b-', 'LineWidth', 1.5);
    xlabel('Time (s)');
    ylabel('Output (rad/sec)');
    title('Fuzzy Controller Response');
    legend('Reference Signal', 'Plant Output');
end



%% Functions

% Plot the membership functions for inputs and output
function myPlotMf()
    % Visualize Membership Functions
    figure;
    % subplot args: rows, columns, index
    subplot(3,1,1); plotmf(fis, 'input', 1); title('Input E'); ylabel('μ','Rotation',0);
    subplot(3,1,2); plotmf(fis, 'input', 2); title('Input dE'); ylabel('μ','Rotation',0);
    subplot(3,1,3); plotmf(fis, 'output', 1); title('Output dU'); ylabel('μ','Rotation',0);
end

% Plot the scaled error and change of error 
function myPlotErrors(t, e_scaled, de_scaled)
    figure;
    plot(t, e_scaled, 'b-', t, de_scaled, 'c--', 'LineWidth', 1.5);
    xlabel('Time (s)');
    ylabel('Error (rad/sec)');
    title('Error and Change of Error Signals');
    legend('E Signal','dE Signal');
end



%% Scenario 1
%sig = 50*stepfun;
% a)
% Overshoot <5%
% Rise time <0.6s
% Initial Kp, Ki equal to the linear controller Kp = 30, Ki = 9
% Plot final system output after optimizing the gains
% Plot system response and system stimulation

% b)
% E = ZR, dE = PS
% Open Rule Viewer GUI
ruleview(fis);

% c)
% Plot surface of output with respect to inputs
figure;
gensurf(fis);
title('Surface of Output with Respect to Inputs');
xlabel('E');
ylabel('dE');
zlabel('dU');
view(30, 30); % Set viewing angle

%% Scenario 2
% Time vector
t = 0:0.01:20;



% % Plot signals and system response
% figure;
% subplot(2,1,1); % Create a 2-row subplot

% % Signal 1 Response Plot
% plot(t, sig1, 'k', 'LineWidth', 1.5);
% xlabel('seconds');
% ylabel('(rad/sec)');
% title('Signal 1');
% ylim([0 60]);
% hold on;
% y = lsim(Ac, sig1, t);
% plot(t, y, 'b', 'LineWidth', 1.5);
% title('Fuzzy Controller Response to Signal 1');
% xlabel('Time (s)');
% ylabel('Output (rad/sec)');

% % Signal 2 Response Plot
% subplot(2,1,2);
% plot(t, sig2, 'k', 'LineWidth', 1.5);
% xlabel('seconds');
% ylabel('(rad/sec)');
% title('Signal 2');
% ylim([0 60]);
% hold on;
% y = lsim(Ac, sig2, t);
% plot(t, y, 'b', 'LineWidth', 1.5);
% title('Fuzzy Controller Response to Signal 2');
% xlabel('Time (s)');
% ylabel('Output (rad/sec)');