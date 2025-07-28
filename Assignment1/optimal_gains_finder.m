%% Fuzzy PI Controller
addpath('Assignment1'); % Add the folder containing initFIS.m
% Initialize the Fuzzy Inference System (FIS)
fis = initFIS();

%% System and Simulation 
% Mark s as a transfer function variable
s = tf('s');

% Fuzzy PI Parameters
Ts = 0.01; % Sampling period
K = 30; % Controller's Gain
c = 0.3; % Controller's Zero

% Plant
plant = ((s+c)*K)/(s*(s+0.1)*(s+10));
% plant = feedback(plant, 1, -1); % Closed loop system
% step(plant);  % Verify if the plant responds as expected
plant = c2d(plant, Ts, 'tustin'); % Continuous to discrete conversion

% Initialize simulation parameters
total_time = 4; % Total simulation time in seconds
t = 0:Ts:total_time; % Time resolution

%% Parameter Optimization Loop
% Define parameter ranges to search
K1_range = 50:10:150;           % Fuzzy PI Gain range
Ke_range = 0.001:0.0005:0.005;  % Error Gain range
Kd_range = 0.0001:0.0001:0.001; % dError Gain range

% Performance targets
max_overshoot = 5;    % Maximum allowed overshoot (%)
max_rise_time = 0.6;  % Maximum allowed rise time (s)

% Initialize best parameters
best_params = struct();
best_overshoot = inf;
best_rise_time = inf;
valid_solutions = [];

fprintf('Searching for optimal parameters...\n');
fprintf('Target: Overshoot < %.1f%%, Rise Time < %.2fs\n\n', max_overshoot, max_rise_time);

iteration = 0;
total_iterations = length(K1_range) * length(Ke_range) * length(Kd_range);

% Parameter sweep
for K1_test = K1_range
    for Ke_test = Ke_range
        for Kd_test = Kd_range
            iteration = iteration + 1;
            
            % Progress indicator
            if mod(iteration, 50) == 0
                fprintf('Progress: %.1f%% (%d/%d)\n', (iteration/total_iterations)*100, iteration, total_iterations);
            end
            
            % Run simulation with test parameters
            e_test = zeros(size(t));
            de_test = zeros(size(t));
            y_test = zeros(size(t));
            u_test = zeros(size(t));
            e_scaled_test = zeros(size(t));
            de_scaled_test = zeros(size(t));
            
            for k = 2:length(t)
                e_test(k) = w(k) - y_test(k-1);
                de_test(k) = (e_test(k) - e_test(k-1))/Ts;
                e_scaled_test(k) = min(max(e_test(k)*Ke_test, -1), 1);
                de_scaled_test(k) = min(max(de_test(k)*Kd_test, -1), 1);
                du_test = evalfis(fis, [e_scaled_test(k), de_scaled_test(k)]);
                u_test(k) = u_test(k-1) + K1_test*du_test;
                y_temp = lsim(plant, u_test(1:k), t(1:k));
                y_test(k) = y_temp(end);
            end
            
            % Calculate performance metrics
            steady_state = w(end);
            max_output = max(y_test);
            overshoot_percent = ((max_output - steady_state) / steady_state) * 100;
            rise_10_percent = 0.1 * steady_state;
            rise_90_percent = 0.9 * steady_state;
            rise_start_idx = find(y_test >= rise_10_percent, 1, 'first');
            rise_end_idx = find(y_test >= rise_90_percent, 1, 'first');
            
            if ~isempty(rise_start_idx) && ~isempty(rise_end_idx)
                rise_time = t(rise_end_idx) - t(rise_start_idx);
            else
                rise_time = inf; % Invalid solution
            end
            
            % Check if solution meets criteria
            if overshoot_percent <= max_overshoot && rise_time <= max_rise_time
                valid_solutions = [valid_solutions; K1_test, Ke_test, Kd_test, overshoot_percent, rise_time];
                
                % Update best solution (prioritize lower overshoot, then lower rise time)
                if overshoot_percent < best_overshoot || ...
                   (abs(overshoot_percent - best_overshoot) < 0.1 && rise_time < best_rise_time)
                    best_overshoot = overshoot_percent;
                    best_rise_time = rise_time;
                    best_params.K1 = K1_test;
                    best_params.Ke = Ke_test;
                    best_params.Kd = Kd_test;
                end
            end
        end
    end
end

% Display results
fprintf('\nOptimization Results\n');
fprintf('--------------------\n');
if ~isempty(valid_solutions)
    fprintf('Found %d valid solutions!\n', size(valid_solutions, 1));
    fprintf('\nBest Parameters:\n');
    fprintf('K1 = %.0f, Ke = %.4f, Kd = %.4f\n', best_params.K1, best_params.Ke, best_params.Kd);
    fprintf('Resulting Performance:\n');
    fprintf('Overshoot: %.2f%% (target: <%.1f%%)\n', best_overshoot, max_overshoot);
    fprintf('Rise Time: %.4f s (target: <%.2fs)\n', best_rise_time, max_rise_time);
else
    fprintf('No valid solutions found with current parameter ranges.\n');
    fprintf('Consider expanding the search ranges or relaxing the constraints.\n');
end