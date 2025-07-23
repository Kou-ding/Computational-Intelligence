%% Car Control FLC (Fuzzy Logic Controller)
%% Evironment parameters
% Walls
% Vertical wall segments
vertical_walls = [
    10, 0, 5;   % Wall at x=10 from y=0 to y=5
    11, 0, 6;   % Wall at x=11 from y=0 to y=6  
    12, 0, 7;   % Wall at x=12 from y=0 to y=7
];
% Horizontal wall segments
horizontal_walls = [
    10, 11, 5;  % Wall from x=10 to x=11 at y=5
    11, 12, 6;  % Wall from x=11 to x=12 at y=6
    12, 15, 7;  % Wall from x=12 to x=15 at y=7
];
% Combined wall data for collision detection
all_walls = struct('vertical', vertical_walls, 'horizontal', horizontal_walls);

%% Define membership function parameters
% Input 1: Vertical distance (dv) - triangular MFs from 0 to 1
dv_range = [0 1];
dv_small = [0 0 0.5];      % Triangular MF for Small (S)
dv_medium = [0 0.5 1];     % Triangular MF for Medium (M) 
dv_large = [0.5 1 1];      % Triangular MF for Large (L)

% Input 2: Horizontal distance (dh) - triangular MFs from 0 to 1  
dh_range = [0 1];
dh_small = [0 0 0.5];      % Triangular MF for Small (S)
dh_medium = [0 0.5 1];     % Triangular MF for Medium (M)
dh_large = [0.5 1 1];      % Triangular MF for Large (L)

% Input 3: Angle theta - triangular MFs from -180° to +180°
theta_range = [-180 180];
theta_negative = [-180 -180 0];    % Triangular MF for Negative (N)
theta_zero = [-180 0 180];         % Triangular MF for Zero (ZE)
theta_positive = [0 180 180];      % Triangular MF for Positive (P)

% Output: Delta theta (change in angle) - triangular MFs from -130° to +130°
delta_theta_range = [-130 130];
delta_theta_negative = [-130 -130 0];  % Triangular MF for Negative (N)
delta_theta_zero = [-130 0 130];       % Triangular MF for Zero (ZE)
delta_theta_positive = [0 130 130];    % Triangular MF for Positive (P)

%% Create Fuzzy Inference System
fis = mamfis('Name', 'CarController');

% Add input variables
fis = addInput(fis, dv_range, 'Name', 'dv');
fis = addMF(fis, 'dv', 'trimf', dv_small, 'Name', 'Small');
fis = addMF(fis, 'dv', 'trimf', dv_medium, 'Name', 'Medium');
fis = addMF(fis, 'dv', 'trimf', dv_large, 'Name', 'Large');

fis = addInput(fis, dh_range, 'Name', 'dh');
fis = addMF(fis, 'dh', 'trimf', dh_small, 'Name', 'Small');
fis = addMF(fis, 'dh', 'trimf', dh_medium, 'Name', 'Medium');
fis = addMF(fis, 'dh', 'trimf', dh_large, 'Name', 'Large');

fis = addInput(fis, theta_range, 'Name', 'theta');
fis = addMF(fis, 'theta', 'trimf', theta_negative, 'Name', 'Negative');
fis = addMF(fis, 'theta', 'trimf', theta_zero, 'Name', 'Zero');
fis = addMF(fis, 'theta', 'trimf', theta_positive, 'Name', 'Positive');

% Add output variable
fis = addOutput(fis, delta_theta_range, 'Name', 'delta_theta');
fis = addMF(fis, 'delta_theta', 'trimf', delta_theta_negative, 'Name', 'Negative');
fis = addMF(fis, 'delta_theta', 'trimf', delta_theta_zero, 'Name', 'Zero');
fis = addMF(fis, 'delta_theta', 'trimf', delta_theta_positive, 'Name', 'Positive');


%% Define Fuzzy Rules
% Rule structure: IF dv IS X AND dh IS Y AND theta IS Z THEN delta_theta IS W
% Navigation strategy: 
% - When close to obstacles (small dv/dh), prioritize avoidance
% - When far from obstacles (large dv/dh), focus on goal navigation
% - Use theta to determine appropriate steering direction

% Rule structure: IF dv IS X AND dh IS Y AND theta IS Z THEN delta_theta IS W
% [ input1, input2, input3, output, weight, connection ]
rules = [
    % When vertical distance to obstacles is small (close to obstacle below/above)
    1 1 1 3 1 1;  % IF dv=Small AND dh=Small AND theta=Negative THEN delta_theta=Positive
    1 1 2 3 1 1;  % IF dv=Small AND dh=Small AND theta=Zero THEN delta_theta=Positive  
    1 1 3 1 1 1;  % IF dv=Small AND dh=Small AND theta=Positive THEN delta_theta=Negative
    
    1 2 1 3 1 1;  % IF dv=Small AND dh=Medium AND theta=Negative THEN delta_theta=Positive
    1 2 2 3 1 1;  % IF dv=Small AND dh=Medium AND theta=Zero THEN delta_theta=Positive
    1 2 3 2 1 1;  % IF dv=Small AND dh=Medium AND theta=Positive THEN delta_theta=Zero
    
    1 3 1 2 1 1;  % IF dv=Small AND dh=Large AND theta=Negative THEN delta_theta=Zero
    1 3 2 3 1 1;  % IF dv=Small AND dh=Large AND theta=Zero THEN delta_theta=Positive
    1 3 3 1 1 1;  % IF dv=Small AND dh=Large AND theta=Positive THEN delta_theta=Negative
    
    % When vertical distance to obstacles is medium
    2 1 1 3 1 1;  % IF dv=Medium AND dh=Small AND theta=Negative THEN delta_theta=Positive
    2 1 2 3 1 1;  % IF dv=Medium AND dh=Small AND theta=Zero THEN delta_theta=Positive
    2 1 3 1 1 1;  % IF dv=Medium AND dh=Small AND theta=Positive THEN delta_theta=Negative
    
    2 2 1 1 1 1;  % IF dv=Medium AND dh=Medium AND theta=Negative THEN delta_theta=Negative
    2 2 2 2 1 1;  % IF dv=Medium AND dh=Medium AND theta=Zero THEN delta_theta=Zero
    2 2 3 3 1 1;  % IF dv=Medium AND dh=Medium AND theta=Positive THEN delta_theta=Positive
    
    2 3 1 1 1 1;  % IF dv=Medium AND dh=Large AND theta=Negative THEN delta_theta=Negative
    2 3 2 2 1 1;  % IF dv=Medium AND dh=Large AND theta=Zero THEN delta_theta=Zero
    2 3 3 3 1 1;  % IF dv=Medium AND dh=Large AND theta=Positive THEN delta_theta=Positive
    
    % When vertical distance to obstacles is large (far from vertical obstacles)
    3 1 1 3 1 1;  % IF dv=Large AND dh=Small AND theta=Negative THEN delta_theta=Positive
    3 1 2 3 1 1;  % IF dv=Large AND dh=Small AND theta=Zero THEN delta_theta=Positive
    3 1 3 1 1 1;  % IF dv=Large AND dh=Small AND theta=Positive THEN delta_theta=Negative
    
    3 2 1 1 1 1;  % IF dv=Large AND dh=Medium AND theta=Negative THEN delta_theta=Negative
    3 2 2 2 1 1;  % IF dv=Large AND dh=Medium AND theta=Zero THEN delta_theta=Zero
    3 2 3 3 1 1;  % IF dv=Large AND dh=Medium AND theta=Positive THEN delta_theta=Positive
    
    3 3 1 1 1 1;  % IF dv=Large AND dh=Large AND theta=Negative THEN delta_theta=Negative
    3 3 2 2 1 1;  % IF dv=Large AND dh=Large AND theta=Zero THEN delta_theta=Zero
    3 3 3 3 1 1;  % IF dv=Large AND dh=Large AND theta=Positive THEN delta_theta=Positive
];

fis = addRule(fis, rules);

% Set implication, aggregation and defuzzification methods
fis.ImplicationMethod = 'prod'; % Larsen implication
fis.AggregationMethod = 'max'; % max-min aggregation, ALSO through max
fis.DefuzzificationMethod = 'centroid'; % Defuzzification method COA (Center of Area)

%% Visualize the membership functions
figure('Name', 'Membership Functions', 'Position', [200 50 800 600]);

subplot(2,2,1);
plotmf(fis, 'input', 1);
title('Vertical Obstacle Distance (dv) Membership Functions');
xlabel('Normalized Distance [0,1]');

subplot(2,2,2);
plotmf(fis, 'input', 2);
title('Horizontal Obstacle Distance (dh) Membership Functions');
xlabel('Normalized Distance [0,1]');

subplot(2,2,3);
plotmf(fis, 'input', 3);
title('Angle Error (theta) Membership Functions');
xlabel('Angle [degrees]');

subplot(2,2,4);
plotmf(fis, 'output', 1);
title('Delta Theta Output Membership Functions');
xlabel('Angle Change [degrees]');

%% Car parameters
% End goal position
xd = 15; % Desired x position (has to be precise)
yd = 7.2; % Desired y position (should be close to 7.2)

% Initial conditions
xinit = 9; % Initial x position in meters
yinit = 4.4; % Initial y position in meters
u = 0.05; % Constant Car speed in m/s
theta_init = [0, 45, 90]; % Initial angle in degrees

%% Simulate car trajectory
% Simulate the car trajectory for each initial angle
for i = 1:length(theta_init)
    % Initialize car position and angle
    theta = theta_init(i); % Current angle
    x = xinit; % Reset x position
    y = yinit; % Reset y position
    max_iterations = 1000;
    iter = 0; % Initialize iteration counter
    
    % Store trajectory for plotting
    trajectory_x = zeros(1, max_iterations+1);
    trajectory_y = zeros(1, max_iterations+1);
    trajectory_x(1) = x; % Store initial x position
    trajectory_y(1) = y; % Store initial y position
    
    % Simulate until reaching the goal or exceeding max iterations
    for j = 1:max_iterations
        % Calculate distances to obstacles and goal
        dv = calculateVerticalDistance(x, y, all_walls);
        dh = calculateHorizontalDistance(x, y, all_walls);
        theta_error = calculateAngleError(x, y, xd, yd, theta);
        
        % Normalize inputs
        dv_norm = min(dv / 10, 1);
        dh_norm = min(dh / 10, 1);
        theta_norm = theta_error;
        
        % Evaluate fuzzy inference system
        delta_theta = evalfis(fis, [dv_norm, dh_norm, theta_norm]);
        
        % Update car position and angle
        theta = theta + delta_theta; % Update angle
        x = x + u * cosd(theta); % Update x position
        y = y + u * sind(theta); % Update y position
        
        % Store trajectory points
        trajectory_x(j+1) = x;
        trajectory_y(j+1) = y;
        
        % Check if goal is reached
        % y must be accurate
        % x must be close enough to the goal
        if norm(y - yd) < 0.1 && norm(x - xd) < 1 % use absolute distances
            break; % Stop if close enough to the goal
        end
    end
    
    % Plot the trajectory for the current initial angle
    % before optimizing the membership funciton parameters
    trajectory_x = trajectory_x(1:j);
    trajectory_y = trajectory_y(1:j);

    % Plot trajectory
    figure;
    hold on;
    grid on;
    axis equal;

    % Plot walls
    % Vertical walls (as lines)
    for w = 1:size(vertical_walls, 1)
        x_wall = vertical_walls(w, 1);
        y_start = vertical_walls(w, 2);
        y_end = vertical_walls(w, 3);
        plot([x_wall, x_wall], [y_start, y_end], 'k-', 'LineWidth', 2, 'DisplayName', sprintf('Wall'));
    end

    % Horizontal walls (as lines)
    for w = 1:size(horizontal_walls, 1)
        x_start = horizontal_walls(w, 1);
        x_end = horizontal_walls(w, 2);
        y_wall = horizontal_walls(w, 3);
        plot([x_start, x_end], [y_wall, y_wall], 'k-', 'LineWidth', 2, 'DisplayName', sprintf('Wall'));
    end

    % Plot trajectory
    plot(trajectory_x, trajectory_y, 'b-', 'LineWidth', 2, ...
        'DisplayName', sprintf('Trajectory (θ₀ = %d°)', theta_init(i)));

    % Plot start and goal
    plot(xinit, yinit, 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
    text(xinit + 0.1, yinit, 'Start', 'Color', 'g', 'FontWeight', 'bold');

    plot(xd, yd, 'rx', 'MarkerSize', 10, 'LineWidth', 2);
    text(xd + 0.1, yd, 'Goal', 'Color', 'r', 'FontWeight', 'bold');

    title(sprintf('Trajectory from θ₀ = %d°', theta_init(i)));
    xlabel('X Position (m)');
    ylabel('Y Position (m)');
    legend('Location', 'best');
end

function dv = calculateVerticalDistance(x, y, walls)
    % Compute distance to nearest vertical wall at the current y position
    dv_list = [];
    for i = 1:size(walls.vertical, 1)
        % x position of the wall segment
        x_wall = walls.vertical(i,1);
        % Edges of the wall segment
        y1 = walls.vertical(i,2);
        y2 = walls.vertical(i,3);
        % Check if y is within the span of the wall
        if y >= y1 && y <= y2
            dv_list(end+1) = abs(x - x_wall);
        end
    end
    % If no walls are nearby, return a large default value
    if isempty(dv_list)
        dv = 10;
    % Otherwise, return the minimum distance to the nearest wall
    else
        dv = min(dv_list);
    end
end

function dh = calculateHorizontalDistance(x, y, walls)
    % Compute distance to nearest horizontal wall at the current x position
    dh_list = [];
    for i = 1:size(walls.horizontal, 1)
        % y position of the wall segment
        y_wall = walls.horizontal(i,3);
        % Edges of the wall segment
        x1 = walls.horizontal(i,1);
        x2 = walls.horizontal(i,2);
        % Check if x is within the span of the wall
        if x >= x1 && x <= x2
            dh_list(end+1) = abs(y - y_wall);
        end
    end
    % If no walls are nearby, return a large default value
    if isempty(dh_list)
        dh = 10; 
    % Otherwise, return the minimum distance to the nearest wall
    else
        dh = min(dh_list);
    end
end

function theta_error = calculateAngleError(x, y, xd, yd, theta)
    % Calculate angle error to the goal position
    goal_angle = atan2d(yd - y, xd - x); % Angle to the goal
    theta_error = goal_angle - theta; % Angle error
    % Normalize angle error to [-180, 180]
    if theta_error > 180
        theta_error = theta_error - 360;
    elseif theta_error < -180
        theta_error = theta_error + 360;
    end
end
