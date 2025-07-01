% Mark s as a transfer function variable
s = tf('s');

% Controlled plant
H = 25 / ((s+0.1) * (s+10));
% Controller
%K = 4; % Gain
c = 0.1; % Zero
Gc = K*(s+c) / s;
% Emerging System
GcH = Gc*H;

% Plot the root locus of the closed loop system
figure;
rlocus(GcH);
title('Root Locus of GcH = Gc * H');

% Closed loop transfer function
cloop = feedback(GcH, 1, -1);
[z, p, k] = zpkdata(cloop, 'v');

% Poles
fprintf('Closed loop poles\n----------------\n');
for i = 1:length(p)
    if imag(p(i)) ~= 0
        fprintf('Pole %d: %.4f + %.4fi\n', i, real(p(i)), imag(p(i)));
    else
        fprintf('Pole %d: %.4f\n', i, real(p(i)));
    end
end

% Zeros
fprintf('\nClosed loop zeros\n----------------\n');
for i = 1:length(z)
    if imag(z(i)) ~= 0
        fprintf('Zero %d: %.4f + %.4fi\n', i, real(z(i)), imag(z(i)));
    else
        fprintf('Zero %d: %.4f\n', i, real(z(i)));
    end
end

% Gain
fprintf('\nClosed loop gain\n----------------\n');
fprintf('Gain: %.4f\n', real(k(i)));