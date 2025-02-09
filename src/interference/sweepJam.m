function [jamSignal] = sweepJam(Ts, fs, Pj, f_start, f_end, sweep_time)
% 生成扫频干扰信号
% 输入参数：
%   Ts: 信号周期
%   fs: 采样频率
%   Pj: 干扰信号功率
%   f_start: 起始频率
%   f_end: 终止频率
%   sweep_time: 扫频周期（可选，默认为Ts）
% 输出参数：
%   jamSignal: 生成的干扰信号

% 如果未指定扫频周期，使用信号周期
if nargin < 6
    sweep_time = Ts;
end

% 生成时间向量
dt = 1/fs;
t = 0:dt:Ts-dt;

% 生成扫频信号
sweep_phase = 2*pi*((f_end-f_start)/(2*sweep_time)*mod(t,sweep_time).^2 + f_start*mod(t,sweep_time));
jamSignal = cos(sweep_phase);

% 功率归一化
norm = mean(abs(jamSignal).^2);
jamSignal = sqrt(Pj/norm)*jamSignal;

end 