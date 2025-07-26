%% Fuzzy PI Controller
%% FIS (Fuzzy Inference System) Setup
% Mamdani Fuzzy Inference System (FIS)
fis = mamfis('Name', 'FuzzyController');
% AND is implemented through the min operator
fis.AndMethod = 'min';
% Larsen implication
fis.ImplicationMethod = 'prod';
% ALSO is implemented through the max operator
fis.AggregationMethod = 'max';
% COA(Center of Area) defuzzification method
fis.DefuzzificationMethod = 'centroid';

% Membership Functions
labels = {'NV','NL','NM','NS','ZR','PS','PM','PL','PV'};
A = 1;
cent = -A:(A/4):A; % Centers of the membership functions [-A -A+(A/4) ... A-(A/4) A]
w = (1.5/4)*A; % Half width of the membership functions

% Inputs: E and dE, Output: dU
fis = addInput(fis,[-A A],'Name','E');
fis = addInput(fis,[-A A],'Name','dE');
fis = addOutput(fis,[-A A],'Name','dU');
% 9 Membership Functions for E, dE and dU
for k = 1:9
    fis = addMF(fis,'E','trimf',[cent(k)-w cent(k) cent(k)+w],'Name',labels{k});
    fis = addMF(fis,'dE','trimf',[cent(k)-w cent(k) cent(k)+w],'Name',labels{k});
    fis = addMF(fis,'dU','trimf',[cent(k)-w cent(k) cent(k)+w],'Name',labels{k});
end

% Preallocate Rule Base matrix 
rules = zeros(81,5); % 
% Rule index
index = 1;
for i = 1:9
    for j = 1:9
        if (j == 5)
            out = i; % If dE is ZR, output is E
        end
        if j < 5  % If dE negative
            % Reduce control action aggressiveness
            out = max(1, i+j-5); 
        elseif j > 5  % If dE positive
            % Increase control action aggressiveness
            out = min(9, i+j-5); 
        end
        rules(index,:) = [i j out 1 1]; % [E, dE, dU, weight, connection]
        index = index + 1;
    end
end
fis = addRule(fis,rules);

% Visualize Membership Functions
figure;
% subplot args: rows, columns, index
subplot(3,1,1); plotmf(fis, 'input', 1); title('Input E'); ylabel('μ','Rotation',0);
subplot(3,1,2); plotmf(fis, 'input', 2); title('Input dE'); ylabel('μ','Rotation',0);
subplot(3,1,3); plotmf(fis, 'output', 1); title('Output dU'); ylabel('μ','Rotation',0);

%% System and Simulation 
% Mark s as a transfer function variable
s = tf('s');

% Controller Parameters
K = 30; % Controller's Gain
c = 0.3; % Controller's Zero

% Open Loop System
A = ((s+c)*K) / (s*(s+0.1)*(s+10));

% Closed Loop System
Ac = feedback(A, 1, -1);

% Sampling period
T = 0.01;

% Controller Parameters
Kp = 30; % Proportional gain
Ki = 9; % Integral gain
Ti = Kp / Ki; % Integral time constant

% Initialize simulation parameters
% N = 500; % Number of simulation steps
% w = 50 * ones(N,1); % Reference signal
% y = zeros(N,1); % Plant output
% U = zeros(N,1); % Control input
% dU = zeros(N,1); % Change in control input
% E = zeros(N,1); % Error
% dE = zeros(N,1); % Change in error
% for k = 1:N
%     % Calculate error
%     E(k) = w(k) - y(k);
%     % Calculate change in error
%     dE(k) = E(k) - (k > 1) * E(k-1); % Avoid index out of bounds for k=1

%     % Evaluate fuzzy inference system
%     dU(k) = evalfis(fis,[E(k), dE(k)]);

%     % Update control input
%     u(k+1) = u(k) + du(k);
%     % Simulate plant response (discrete-time model)
%     y(k+1) = lsim(Ac, u(k+1), [0 T], y(k));
% end

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

% Plot signals and system response
figure;
subplot(2,1,1); % Create a 2-row subplot

% Signal 1 Response Plot
plot(t, sig1, 'k', 'LineWidth', 1.5);
xlabel('seconds');
ylabel('(rad/sec)');
title('Signal 1');
ylim([0 60]);
hold on;
y = lsim(Ac, sig1, t);
plot(t, y, 'b', 'LineWidth', 1.5);
title('Fuzzy Controller Response to Signal 1');
xlabel('Time (s)');
ylabel('Output (rad/sec)');

% Signal 2 Response Plot
subplot(2,1,2);
plot(t, sig2, 'k', 'LineWidth', 1.5);
xlabel('seconds');
ylabel('(rad/sec)');
title('Signal 2');
ylim([0 60]);
hold on;
y = lsim(Ac, sig2, t);
plot(t, y, 'b', 'LineWidth', 1.5);
title('Fuzzy Controller Response to Signal 2');
xlabel('Time (s)');
ylabel('Output (rad/sec)');