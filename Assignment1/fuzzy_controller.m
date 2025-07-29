%% Fuzzy PI Controller

clear; % clear variables 
close all; % close figures
%clc; % clear command window

addpath('Assignment1'); % Add the folder containing initFIS.m

% Rules Mode - Mode dependent FZ PI gains
% Available modes: 'custom' or 'lectures'
mode = 'custom';

% Initialize the Fuzzy Inference System (FIS)
fis = initFIS(mode);

% Plot membership functions for inputs and output
myPlotMf(fis);

% Open Rule Viewer GUI (E = ZR, dE = PS)
ruleview(fis);

% Plot surface of output with respect to inputs
figure;
gensurf(fis);
title('Surface of Output with Respect to Inputs');
xlabel('E');
ylabel('dE');
zlabel('dU');
view(30, 30); % Set viewing angle

% Time parameters
Ts = 0.01; % Sampling period
total_time = 20; % Total simulation time in seconds
t = 0:Ts:total_time; % Time resolution

%% Reference signals
% Signal 0 (Step function)
% Requirement 1: Overshoot <5%
% Requirement 2: Rise time <0.6s
sig0 = 50 * ones(size(t)); 
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

% Simulate for each signal
for i=1:3
    if i == 1
        sig = sig0; % Use Signal 0
        metrics = true; % Print performance metrics
    elseif i == 2
        sig = sig1; % Use Signal 1
        metrics = false;
    else
        sig = sig2; % Use Signal 2
        metrics = false;
    end
    
    fprintf('Running simulation for Signal %d...\n', i);
    
    % Run the simulation with the current signal
    mySimulation(fis, sig, Ts, t, metrics, mode);
end


%% Functions
% Run the simulation for a particular reference signal
function mySimulation(fis, w, Ts, t, metrics, mode)
    % Mark s as a transfer function variable
    s = tf('s');

    % Fuzzy PI Parameters
    K = 30; % Controller's Gain (Proportional Gain - Kp = 30)
    c = 0.3; % Controller's Zero (Integral Gain - Ki = 9)

    % Mode dependent FZ PI gains
    if strcmp(mode, 'lectures')
        Ke = 0.0015; % Error Gain
        Kd = 0.0005; % dError Gain
        K1 = 150; % Fuzzy PI Gain
    elseif strcmp(mode, 'custom')
        Ke = 0.001; % Error Gain
        Kd = 0.0002; % dError Gain
        K1 = 80; % Fuzzy PI Gain
    end
        
    % Plant
    % Initial Kp, Ki equal to the linear controller Kp = 30, Ki = 9
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
    end
    
    % Check if the Fuzzy controller surpasses the normal on the step response
    if metrics == true
        % Calculate performance metrics
        % Find overshoot
        steady_state = w(end); % Final reference value
        max_output = max(y);
        overshoot_percent = ((max_output - steady_state) / steady_state) * 100;
        % Find rise time (10% to 90% of final value)
        rise_10_percent = 0.1 * steady_state;
        rise_90_percent = 0.9 * steady_state;
        rise_start_idx = find(y >= rise_10_percent, 1, 'first');
        rise_end_idx = find(y >= rise_90_percent, 1, 'first');
        rise_time = t(rise_end_idx) - t(rise_start_idx);
        % Display results
        fprintf('\nPerformance Metrics\n');
        fprintf('-------------------\n');
        fprintf('Overshoot: %.2f%%\n', overshoot_percent);
        fprintf('Rise Time: %.4f seconds\n', rise_time);
    end

    figure;
    plot(t, w, 'k--', t, y, 'b-', 'LineWidth', 1.5);
    xlabel('Time (s)');
    ylabel('Output (rad/sec)');
    title('Fuzzy Controller Response');
    legend('Reference Signal', 'Plant Output');
end

% Plot the membership functions for inputs and output
function myPlotMf(fis)
    % Visualize Membership Functions
    figure;
    % subplot args: rows, columns, index
    subplot(3,1,1); plotmf(fis, 'input', 1); title('Input E'); ylabel('μ','Rotation',0);
    subplot(3,1,2); plotmf(fis, 'input', 2); title('Input dE'); ylabel('μ','Rotation',0);
    subplot(3,1,3); plotmf(fis, 'output', 1); title('Output dU'); ylabel('μ','Rotation',0);
end

% Plot the scaled error and change of error (used for debugging)
function myPlotErrors(t, e_scaled, de_scaled)
    figure;
    plot(t, e_scaled, 'b-', t, de_scaled, 'c--', 'LineWidth', 1.5);
    xlabel('Time (s)');
    ylabel('Error (rad/sec)');
    title('Error and Change of Error Signals');
    legend('E Signal','dE Signal');
end