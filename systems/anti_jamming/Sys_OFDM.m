 %% 基础OFDM通信系统（不含干扰）
% 添加路径
addpath('../../src/modulation');
addpath('../../src/utils');

clear; clc; close all;

%% 1. 参数设置
% 基本参数
totalBits = 10000;      % 初始比特数
Fs = 1e6;              % 采样率 1MHz
Ts = 1/Fs;             % 采样周期

% OFDM参数
Nfft = 64;             % FFT大小
Ncp = 16;              % 循环前缀长度
Nsc = 52;              % 有效子载波数量
guardBands = (Nfft-Nsc)/2;  % 两侧保护带宽度

% 调制参数
M = 4;                 % QPSK调制阶数
bps = log2(M);         % 每个符号比特数

%% 2. 生成随机比特流
% 确保比特数能被每个OFDM符号承载的比特数整除
bitsPerSymbol = Nsc * bps;
numSymbols = ceil(totalBits/bitsPerSymbol);
totalBits = numSymbols * bitsPerSymbol;
bitStream = randi([0, 1], totalBits, 1);

%% 3. QPSK调制
% 将比特流重塑为每个子载波调制所需的形式
bitMatrix = reshape(bitStream, bps, [])';
symbolIndices = bi2de(bitMatrix, 'left-msb');
modSymbols = pskmod(symbolIndices, M, 0, 'gray');

%% 4. OFDM调制
% 将调制符号重塑为每个OFDM符号的形式
modMatrix = reshape(modSymbols, Nsc, []);
numOFDMSymbols = size(modMatrix, 2);

% OFDM符号赋值（加入保护带）
ofdmSymbols_freq = zeros(Nfft, numOFDMSymbols);
ofdmSymbols_freq(guardBands+1:guardBands+Nsc/2, :) = modMatrix(1:Nsc/2, :);
ofdmSymbols_freq(end-guardBands-Nsc/2+1:end-guardBands, :) = modMatrix(Nsc/2+1:end, :);

% IFFT生成时域OFDM符号
ofdmSymbols_time = ifft(ofdmSymbols_freq, Nfft, 1);

% 添加循环前缀
ofdmSymbols_withCP = [ofdmSymbols_time(end-Ncp+1:end, :); ofdmSymbols_time];

% 序列化发送信号
txSignal = reshape(ofdmSymbols_withCP, [], 1);

%% 5. 添加单音干扰
% 干扰参数
Pj = 1;               % 干扰功率
fc_jam = 200e3;       % 干扰中心频率 200kHz

% 生成单音干扰
signalDuration = length(txSignal)/Fs;  % 信号持续时间
dt = 1/Fs;
t_jam = 0:dt:(signalDuration-dt);
jamSignal = sqrt(2*Pj) * cos(2*pi*fc_jam*t_jam);  % 生成单音干扰
jamSignal = jamSignal(:);  % 确保为列向量

% 添加干扰
rxSignal_withJam = txSignal + jamSignal;

% 计算信干比
signalPower = mean(abs(txSignal).^2);
jamPower = mean(abs(jamSignal).^2);
SJR = 10*log10(signalPower/jamPower);
fprintf('信干比(SJR) = %.2f dB\n', SJR);

%% 6. 通过AWGN信道
SNR = 15;  % 信噪比 (dB)
rxSignal = awgn(rxSignal_withJam, SNR, 'measured');

%% 7. OFDM解调
% 将接收信号重新分帧
rxMatrix = reshape(rxSignal, Nfft+Ncp, []);

% 去除循环前缀
rxMatrix_noCP = rxMatrix(Ncp+1:end, :);

% FFT变换恢复频域符号
rxSymbols_freq = fft(rxMatrix_noCP, Nfft, 1);

% 提取有效子载波上的符号
rxSymbols = zeros(Nsc, numOFDMSymbols);
rxSymbols(1:Nsc/2, :) = rxSymbols_freq(guardBands+1:guardBands+Nsc/2, :);
rxSymbols(Nsc/2+1:end, :) = rxSymbols_freq(end-guardBands-Nsc/2+1:end-guardBands, :);

% 序列化接收符号
rxSymbols = reshape(rxSymbols, [], 1);

%% 8. QPSK解调
demodSymbols = pskdemod(rxSymbols, M, 0, 'gray');
rxBitsMatrix = de2bi(demodSymbols, bps, 'left-msb');
rxBitStream = reshape(rxBitsMatrix.', [], 1);

%% 9. 计算误比特率
[BER, numErrors] = calculateBER(bitStream, rxBitStream);
fprintf('基础OFDM系统误比特率 (BER) = %f\n', BER);

%% 10. 绘制结果
% 时域波形
figure('Name', '时域波形');
symbolLength = Nfft + Ncp;
tPlot = (0:symbolLength*2-1)' * Ts * 1e6;  % 显示两个OFDM符号，转换为us

% 发送信号时域波形
subplot(2,1,1);
plot(tPlot, real(txSignal(1:length(tPlot))), 'b-', 'LineWidth', 1.5);
hold on;
plot(tPlot, imag(txSignal(1:length(tPlot))), 'r--', 'LineWidth', 1.5);
grid on;
title('发送端OFDM信号时域波形（两个OFDM符号）');
xlabel('时间 (μs)');
ylabel('幅度');
legend('实部', '虚部');

% 接收信号时域波形
subplot(2,1,2);
plot(tPlot, real(rxSignal(1:length(tPlot))), 'b-', 'LineWidth', 1.5);
hold on;
plot(tPlot, imag(rxSignal(1:length(tPlot))), 'r--', 'LineWidth', 1.5);
grid on;
title(['接收端OFDM信号时域波形（SNR = ' num2str(SNR) 'dB）']);
xlabel('时间 (μs)');
ylabel('幅度');
legend('实部', '虚部');

% 频谱图
figure('Name', 'OFDM频谱');
subplot(2,1,1);
plotSpectrum(txSignal, Fs, '发送端OFDM信号频谱');

subplot(2,1,2);
plotSpectrum(rxSignal, Fs, ['接收端OFDM信号频谱 (SNR = ' num2str(SNR) 'dB)']);

% 星座图
figure('Name', '星座图');
subplot(1,2,1);
plotConstellation(modSymbols, '发送端QPSK星座图');

subplot(1,2,2);
plotConstellation(rxSymbols, ['接收端QPSK星座图 (SNR = ' num2str(SNR) 'dB)']); 