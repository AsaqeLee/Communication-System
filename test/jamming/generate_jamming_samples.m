%% 生成干扰信号样本
% 添加路径
addpath('../../src/interference');
addpath('../../src/utils');

clear; clc; close all;

%% 参数设置
% 基本参数
Fs = 1e6;              % 采样率 1MHz
Ts = 1e-3;             % 每个样本的持续时间 1ms
num_samples = 1000;    % 每类干扰的样本数
snr_range = 15:1:20;  % SNR变化范围
power_range = 0.1:0.3:2;  % 功率变化范围

% 创建保存文件夹
main_dir = 'jamming_dataset';
if ~exist(main_dir, 'dir')
    mkdir(main_dir);
end

% 创建子文件夹
jam_types = {'single_tone', 'comb', 'noise_mod', 'multi_tone', 'partial_band', 'sweep'};
for i = 1:length(jam_types)
    sub_dir = fullfile(main_dir, jam_types{i});
    if ~exist(sub_dir, 'dir')
        mkdir(sub_dir);
    end
end

% 创建README文件
readme_file = fullfile(main_dir, 'README.txt');
fid = fopen(readme_file, 'w');
fprintf(fid, '干扰信号数据集说明\n\n');
fprintf(fid, '1. 数据集结构：\n');
fprintf(fid, '   - single_tone/: 单音干扰\n');
fprintf(fid, '   - comb/: 梳状谱干扰\n');
fprintf(fid, '   - noise_mod/: 噪声调制干扰\n');
fprintf(fid, '   - multi_tone/: 多音干扰\n');
fprintf(fid, '   - partial_band/: 部分频带噪声干扰\n');
fprintf(fid, '   - sweep/: 扫频干扰\n\n');
fprintf(fid, '2. 文件格式：\n');
fprintf(fid, '   - 每个样本保存为单独的CSV文件\n');
fprintf(fid, '   - 文件名格式：sample_XXXX.csv\n');
fprintf(fid, '   - 第一行：参数信息\n');
fprintf(fid, '   - 后续行：信号数据（实部和虚部）\n');
fclose(fid);

%% 生成样本
fprintf('开始生成干扰信号样本...\n');

% 进度条
h = waitbar(0, '生成样本中...');

for sample_idx = 1:num_samples
    waitbar(sample_idx/num_samples, h);
    
    % 随机选择SNR和功率
    snr = snr_range(randi(length(snr_range)));
    power = power_range(randi(length(power_range)));
    
    % 1. 单音干扰
    fc = randi([100e3, 400e3]);  % 随机选择载波频率
    signal = singleToneJam(fc, Ts, Fs, power);
    signal = awgn(signal, snr, 'measured');
    
    filename = fullfile(main_dir, 'single_tone', sprintf('sample_%04d.csv', sample_idx));
    signal_matrix = [real(signal(:)), imag(signal(:))];  % 确保为列向量
    param_row = [fc, power, snr];
    dlmwrite(filename, param_row, 'precision', '%.6f');
    dlmwrite(filename, signal_matrix, '-append', 'precision', '%.6f');
    
    % 2. 梳状谱干扰
    f_center = randi([200e3, 300e3]);
    bw = randi([20e3, 100e3]);
    signal = combJam(Ts, Fs, power, f_center, bw);
    signal = awgn(signal, snr, 'measured');
    
    filename = fullfile(main_dir, 'comb', sprintf('sample_%04d.csv', sample_idx));
    signal_matrix = [real(signal(:)), imag(signal(:))];  % 确保为列向量
    param_row = [f_center, bw, power, snr];
    dlmwrite(filename, param_row, 'precision', '%.6f');
    dlmwrite(filename, signal_matrix, '-append', 'precision', '%.6f');
    
    % 3. 噪声调制干扰
    fc = randi([100e3, 400e3]);
    bw = randi([20e3, 100e3]);
    signal = noiseModulatedJam(Ts, Fs, power, fc, bw);
    signal = awgn(signal, snr, 'measured');
    
    filename = fullfile(main_dir, 'noise_mod', sprintf('sample_%04d.csv', sample_idx));
    signal_matrix = [real(signal(:)), imag(signal(:))];  % 确保为列向量
    param_row = [fc, bw, power, snr];
    dlmwrite(filename, param_row, 'precision', '%.6f');
    dlmwrite(filename, signal_matrix, '-append', 'precision', '%.6f');
    
    % 4. 多音干扰
    num_tones = randi([2, 5]);
    freqs = sort(randi([100e3, 400e3], 1, num_tones));
    amps = rand(1, num_tones);
    signal = multiToneJam(Ts, Fs, power, freqs, amps);
    signal = awgn(signal, snr, 'measured');
    
    filename = fullfile(main_dir, 'multi_tone', sprintf('sample_%04d.csv', sample_idx));
    signal_matrix = [real(signal(:)), imag(signal(:))];  % 确保为列向量
    param_row = [num_tones, freqs(1:min(num_tones,5)), zeros(1, 5-num_tones), power, snr];
    dlmwrite(filename, param_row, 'precision', '%.6f');
    dlmwrite(filename, signal_matrix, '-append', 'precision', '%.6f');
    
    % 5. 部分频带噪声干扰
    f_center = randi([200e3, 300e3]);
    bw = randi([20e3, 100e3]);
    signal = partialBandNoiseJam(Ts, Fs, power, f_center, bw);
    signal = awgn(signal, snr, 'measured');
    
    filename = fullfile(main_dir, 'partial_band', sprintf('sample_%04d.csv', sample_idx));
    signal_matrix = [real(signal(:)), imag(signal(:))];  % 确保为列向量
    param_row = [f_center, bw, power, snr];
    dlmwrite(filename, param_row, 'precision', '%.6f');
    dlmwrite(filename, signal_matrix, '-append', 'precision', '%.6f');
    
    % 6. 扫频干扰
    f_start = randi([100e3, 200e3]);
    f_end = randi([300e3, 400e3]);
    sweep_time = Ts/randi([2, 5]);
    signal = sweepJam(Ts, Fs, power, f_start, f_end, sweep_time);
    signal = awgn(signal, snr, 'measured');
    
    filename = fullfile(main_dir, 'sweep', sprintf('sample_%04d.csv', sample_idx));
    signal_matrix = [real(signal(:)), imag(signal(:))];  % 确保为列向量
    param_row = [f_start, f_end, sweep_time, power, snr];
    dlmwrite(filename, param_row, 'precision', '%.6f');
    dlmwrite(filename, signal_matrix, '-append', 'precision', '%.6f');
end

close(h);
fprintf('样本生成完成！\n');
fprintf('总共生成了 %d 个样本\n', num_samples * 6);
fprintf('数据保存在 %s 文件夹中\n', main_dir); 