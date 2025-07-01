% Mark s as a transfer function variable
s = tf('s');

% Controller Parameters
%K = 4; % Controller's Gain
c = 0.1; % Controller's Zero

% Emerging System
A = K*(s+c) / s*((s+0.1) * (s+10));

% Plot the root locus of the open loop system
figure;
rlocus(A);
title('Root Locus of A = Gc * H');

% Closed loop transfer function
cloop = feedback(A, 1, -1);
[z, p, k] = zpkdata(cloop, 'v');

% Poles
fprintf('Root Locus Poles\n----------------\n');
for i = 1:length(p)
    if imag(p(i)) ~= 0
        fprintf('Pole %d: %.4f + %.4fi\n', i, real(p(i)), imag(p(i)));
    else
        fprintf('Pole %d: %.4f\n', i, real(p(i)));
    end
end

% Zeros
fprintf('\nRoot Locus Zeros\n----------------\n');
for i = 1:length(z)
    if imag(z(i)) ~= 0
        fprintf('Zero %d: %.4f + %.4fi\n', i, real(z(i)), imag(z(i)));
    else
        fprintf('Zero %d: %.4f\n', i, real(z(i)));
    end
end

% Gain
fprintf('\nRoot Locus Gain\n----------------\n');
fprintf('Gain: %.4f\n', real(k(i)));