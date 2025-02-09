function [jamSignal] = multiToneJam(Ts, fs, Pj, freqs, amps)
% 生成多音干扰信号
% 输入参数：
%   Ts: 信号周期
%   fs: 采样频率
%   Pj: 干扰信号总功率
%   freqs: 干扰频率数组
%   amps: 各频率分量的相对幅度（可选，默认相等）
% 输出参数：
%   jamSignal: 生成的干扰信号

% 生成时间向量
dt = 1/fs;
t = 0:dt:Ts-dt;

% 如果未指定幅度，则平均分配功率
if nargin < 5
    amps = ones(1, length(freqs))/sqrt(length(freqs));
end

% 生成多音信号
jamSignal = zeros(1, length(t));
for i = 1:length(freqs)
    jamSignal = jamSignal + amps(i)*cos(2*pi*freqs(i)*t);
end

% 功率归一化
norm = mean(abs(jamSignal).^2);
jamSignal = sqrt(Pj/norm)*jamSignal;

end 