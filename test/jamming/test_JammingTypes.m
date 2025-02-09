%% 干扰类型测试脚本
% 添加路径
addpath('../../src/interference');
addpath('../../src/utils');

clear; clc; close all;

%% 参数设置
Fs = 1e6;              % 采样率 1MHz
Ts = 1;                % 信号持续时间
fs = Fs;               % 采样频率
Pj = 1;                % 干扰功率

%% 1. 单音干扰测试
fc_jam = 200e3;        % 干扰中心频率 200kHz
jam_SingleTone = singleToneJam(fc_jam, Ts, fs, Pj);

% 绘制单音干扰
figure('Name', '单音干扰');
% 时域波形
subplot(2,1,1);
t = (0:1/fs:Ts-1/fs)' * 1e6;  % 时间轴（微秒）
plot(t(1:1000), jam_SingleTone(1:1000), 'LineWidth', 1.5);
grid on;
title('单音干扰时域波形');
xlabel('时间 (μs)');
ylabel('幅度');

% 频谱
subplot(2,1,2);
plotSpectrum(jam_SingleTone, fs, '单音干扰频谱');

%% 2. 梳状谱干扰测试
f_center = 200e3;      % 中心频率
Bw = 50e3;             % 频率间隔

jam_Comb = combJam(Ts, fs, Pj, f_center, Bw);

% 绘制梳状谱干扰
figure('Name', '梳状谱干扰');
% 时域波形
subplot(2,1,1);
plot(t(1:1000), jam_Comb(1:1000), 'LineWidth', 1.5);
grid on;
title('梳状谱干扰时域波形');
xlabel('时间 (μs)');
ylabel('幅度');

% 频谱
subplot(2,1,2);
plotSpectrum(jam_Comb, fs, '梳状谱干扰频谱');

%% 3. 噪声调制干扰测试
fc = 200e3;           % 载波频率
bw = 50e3;            % 调制带宽

jam_NoiseModulated = noiseModulatedJam(Ts, fs, Pj, fc, bw);


% 绘制噪声调制干扰
figure('Name', '噪声调制干扰');
% 时域波形
subplot(2,1,1);
plot(t(1:1000), jam_NoiseModulated(1:1000), 'LineWidth', 1.5);
grid on;
title('噪声调制干扰时域波形');
xlabel('时间 (μs)');
ylabel('幅度');

% 频谱
subplot(2,1,2);
plotSpectrum(jam_NoiseModulated, fs, '噪声调制干扰频谱');

%% 4. 多音干扰测试
freqs = [100e3, 200e3, 300e3];  % 干扰频率
amps = [0.5, 1, 0.7];           % 相对幅度
jam_MultiTone = multiToneJam(Ts, fs, Pj, freqs, amps);

% 绘制多音干扰
figure('Name', '多音干扰');
% 时域波形
subplot(2,1,1);
plot(t(1:1000), jam_MultiTone(1:1000), 'LineWidth', 1.5);
grid on;
title('多音干扰时域波形');
xlabel('时间 (μs)');
ylabel('幅度');

% 频谱
subplot(2,1,2);
plotSpectrum(jam_MultiTone, fs, '多音干扰频谱');

%% 5. 部分频带噪声干扰测试
f_center_pb = 200e3;   % 中心频率
bw_pb = 100e3;         % 带宽
jam_PartialBand = partialBandNoiseJam(Ts, fs, Pj, f_center_pb, bw_pb);

% 绘制部分频带噪声干扰
figure('Name', '部分频带噪声干扰');
% 时域波形
subplot(2,1,1);
plot(t(1:1000), jam_PartialBand(1:1000), 'LineWidth', 1.5);
grid on;
title('部分频带噪声干扰时域波形');
xlabel('时间 (μs)');
ylabel('幅度');

% 频谱
subplot(2,1,2);
plotSpectrum(jam_PartialBand, fs, '部分频带噪声干扰频谱');

%% 6. 扫频干扰测试
f_start = 100e3;       % 起始频率
f_end = 300e3;         % 终止频率
sweep_time = Ts/5;     % 扫频周期
jam_Sweep = sweepJam(Ts, fs, Pj, f_start, f_end, sweep_time);

% 绘制扫频干扰
figure('Name', '扫频干扰');
% 时域波形
subplot(2,1,1);
plot(t(1:1000), jam_Sweep(1:1000), 'LineWidth', 1.5);
grid on;
title('扫频干扰时域波形');
xlabel('时间 (μs)');
ylabel('幅度');

% 时频图
subplot(2,1,2);
window = hamming(256);
noverlap = 200;
nfft = 1024;
spectrogram(jam_Sweep, window, noverlap, nfft, fs, 'yaxis');
title('扫频干扰时频图');
ylabel('频率 (Hz)');
xlabel('时间 (s)');

%% 功率验证
fprintf('\n各类干扰信号的实际功率：\n');
fprintf('单音干扰：%.2f W\n', mean(abs(jam_SingleTone).^2));
fprintf('梳状谱干扰：%.2f W\n', mean(abs(jam_Comb).^2));
fprintf('噪声调制干扰：%.2f W\n', mean(abs(jam_NoiseModulated).^2));
fprintf('多音干扰：%.2f W\n', mean(abs(jam_MultiTone).^2));
fprintf('部分频带噪声干扰：%.2f W\n', mean(abs(jam_PartialBand).^2));
fprintf('扫频干扰：%.2f W\n', mean(abs(jam_Sweep).^2)); 