function [jamSignal] = noiseModulatedJam(Ts, fs, Pj, fc, bw)
% 生成噪声调制干扰信号
% 输入参数：
%   Ts: 信号周期
%   fs: 采样频率
%   Pj: 干扰信号功率
%   fc: 载波频率
%   bw: 调制带宽
% 输出参数：
%   jamSignal: 生成的干扰信号

% 生成时间向量
dt = 1/fs;
t = 0:dt:Ts-dt;

% 生成基带高斯白噪声
noise = randn(1, length(t));

% 设计低通滤波器限制调制带宽
ord = 128;
wn = bw/(fs/2);
b = fir1(ord, wn, 'low');

% 对噪声进行滤波得到调制信号
mod_signal = filter(b, 1, noise);
mod_signal = mod_signal - mean(mod_signal); % 去除直流分量

% 调制到载波频率（双边带调制）
carrier = cos(2*pi*fc*t);
jamSignal = (1 + 0.8*mod_signal) .* carrier; % 添加调制深度控制

% 功率归一化
norm = mean(abs(jamSignal).^2);
jamSignal = sqrt(Pj/norm)*jamSignal;

% 确保输出为列向量
jamSignal = jamSignal(:);

end 