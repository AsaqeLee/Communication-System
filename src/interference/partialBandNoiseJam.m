function [jamSignal] = partialBandNoiseJam(Ts, fs, Pj, f_center, bw)
% 生成部分频带噪声干扰信号
% 输入参数：
%   Ts: 信号周期
%   fs: 采样频率
%   Pj: 干扰信号功率
%   f_center: 中心频率
%   bw: 干扰带宽
% 输出参数：
%   jamSignal: 生成的干扰信号

% 生成时间向量
dt = 1/fs;
t = 0:dt:Ts-dt;

% 生成复高斯白噪声
noise = (randn(1,length(t)) + 1j*randn(1,length(t)))/sqrt(2);

% 设计带通滤波器
ord = 128;
f1 = (f_center - bw/2)/(fs/2);  % 下边界频率
f2 = (f_center + bw/2)/(fs/2);  % 上边界频率

% 确保频率边界在有效范围内
f1 = max(0, min(1, f1));
f2 = max(0, min(1, f2));

% 使用带通滤波器
b = fir1(ord, [f1 f2], 'bandpass');
jamSignal = filter(b, 1, noise);

% 取实部并归一化功率
jamSignal = real(jamSignal);
norm = mean(abs(jamSignal).^2);
jamSignal = sqrt(Pj/norm)*jamSignal;

% 确保输出为列向量
jamSignal = jamSignal(:);

end 