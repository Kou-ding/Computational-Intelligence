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

% Sampling period
T = 0.01;

% Controller Parameters
Kp = 30; % Proportional gain
Ki = 9; % Integral gain
Ti = Kp / Ki; % Integral time constant

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
labels = {'NV','NL','NM','NS','ZR','PS','PM','PL',' PV'};
A = 1;
cent = -A:(A/4):A; % Centers of the membership functions [-A -A+(A/4) ... A-(A/4) A]
w = (1.5/4)*A; % Half width of the membership functions

% Inputs: E and dE
fis = addInput(fis,[-A A],'Name','E');
fis = addInput(fis,[-A A],'Name','dE');
% 9 Membership Functions for E and dE
for k = 1:9
    fis = addMF(fis,'E','trimf',[cent(k)-w cent(k) cent(k)+w],'Name',labels{k});
    fis = addMF(fis,'dE','trimf',[cent(k)-w cent(k) cent(k)+w],'Name',labels{k});
end

% Output: dU
fis = addOutput(fis,[-A A],'Name','dU');  % Δu (normalised)
% 9 Membership Functions for dU
for k = 1:9
    fis = addMF(fis,'dU','trimf',[cent(k)-w cent(k) cent(k)+w],'Name',labels{k});
end

% Rule Base
rules = [];
for i = 1:9
    for j = 1:9
        k = min(9,max(1, i+j-5));
        rules = [rules ; i j k 1 1];
    end
end
fis = addRule(fis,rules);

% Visualize Membership Functions
figure;
% subplot args: rows, columns, index
subplot(3,1,1); plotmf(fis, 'input', 1); title('Input E'); ylabel('μ','Rotation',0);
subplot(3,1,2); plotmf(fis, 'input', 2); title('Input dE'); ylabel('μ','Rotation',0);
subplot(3,1,3); plotmf(fis, 'output', 1); title('Output dU'); ylabel('μ','Rotation',0);


dU = evalfis(fis,[0 0]);  % Initial output for (E,dE) = (0,0)
