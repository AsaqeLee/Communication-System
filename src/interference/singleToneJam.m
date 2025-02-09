function [jamSignal] = singleToneJam(fc_jam, Ts, fs, Pj)
% 生成单音干扰信号
% 输入参数：
%   fc_jam: 干扰信号中心频率
%   Ts: 信号周期
%   fs: 采样频率
%   Pj: 干扰信号功率(W)
% 输出参数：
%   jamSignal: 生成的干扰信号

% 生成时间向量
dt = 1/fs;
tt = 0:dt:(Ts - dt);

% 生成单音信号
jamSignal = cos(2*pi*fc_jam*tt);

% 功率归一化
norm = mean(abs(jamSignal).^2);
jamSignal = sqrt(Pj/norm)*jamSignal;

end 