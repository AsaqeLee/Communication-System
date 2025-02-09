%% Simple FHSS (Frequency Hopping Spread Spectrum) Communication System Simulation
% 本示例实现了跳频系统的基本仿真流程

clear; clc; close all;

%% 1. 参数设置
% 基本参数
totalBits = 10000;      % 初始比特数
bps = 2;               % 每个符号所含比特数 (QPSK)
Fs = 1e6;             % 采样率 1MHz
Ts = 1/Fs;            % 采样周期

% 跳频参数
numFreqs = 8;                     % 跳频频点数量
freqSpacing = Fs/16;             % 频点间隔
freqSet = (-numFreqs/2:numFreqs/2-1) * freqSpacing;  % 可用频点集合
hopDuration = 100;               % 每个跳频周期的采样点数

% 确保比特数能被bps整除
if mod(totalBits, bps) ~= 0
    totalBits = totalBits + (bps - mod(totalBits, bps));
end

%% 2. 生成随机比特流
bitStream = randi([0, 1], totalBits, 1);

%% 3. QPSK调制
% 将比特流重塑为2比特一组
bitMatrix = reshape(bitStream, 2, [])';
% 转换为符号索引
symbolIndices = bi2de(bitMatrix, 'left-msb');
% QPSK调制
M = 4;  % QPSK调制阶数
modSymbols = pskmod(symbolIndices, M, 0, 'gray');

%% 4. 跳频调制
% 对每个符号进行上采样
samplesPerSymbol = hopDuration;
symbolsUpsample = upsample(modSymbols, samplesPerSymbol);

% 添加成形滤波器
span = 6;  % 滤波器符号跨度
raisedCosine = rcosdesign(0.35, span, samplesPerSymbol);
filterDelay = span * samplesPerSymbol / 2;  % 滤波器群延时

% 对发送信号进行滤波
txSymbols = filter(raisedCosine, 1, symbolsUpsample);

% 补偿滤波器延时
txSymbols = [txSymbols(filterDelay+1:end); zeros(filterDelay, 1)];

% 计算需要的跳频次数
numSymbols = length(modSymbols);
numHops = ceil(numSymbols * samplesPerSymbol / hopDuration);

% 补零使信号长度为hopDuration的整数倍
totalLength = numHops * hopDuration;
if length(txSymbols) < totalLength
    txSymbols = [txSymbols; zeros(totalLength - length(txSymbols), 1)];
end

% 生成跳频图案
hopPattern = randi([1, numFreqs], 1, numHops);

% 生成时间向量
t = (0:length(txSymbols)-1)' * Ts;

% 应用跳频
txSignal = zeros(size(txSymbols));
for i = 1:numHops
    startIdx = (i-1)*hopDuration + 1;
    endIdx = min(i*hopDuration, length(txSymbols));
    freq = freqSet(hopPattern(i));
    txSignal(startIdx:endIdx) = txSymbols(startIdx:endIdx) .* exp(1j*2*pi*freq*t(startIdx:endIdx));
end

%% 5. 通过AWGN信道
SNR = 0;  % 信噪比 (dB)
rxSignal = awgn(txSignal, SNR, 'measured');

%% 6. 接收端解跳频
rxSymbols = zeros(size(rxSignal));
for i = 1:numHops
    startIdx = (i-1)*hopDuration + 1;
    endIdx = min(i*hopDuration, length(rxSignal));
    freq = freqSet(hopPattern(i));
    rxSymbols(startIdx:endIdx) = rxSignal(startIdx:endIdx) .* exp(-1j*2*pi*freq*t(startIdx:endIdx));
end

% 匹配滤波
rxFiltered = filter(raisedCosine, 1, rxSymbols);

% 考虑滤波器延时的抽样判决
totalDelay = filterDelay;  % 只考虑接收端滤波器延时
validStart = totalDelay + 1;

% 抽样判决
rxDecimated = rxFiltered(validStart:samplesPerSymbol:end);
rxDecimated = rxDecimated(1:min(length(rxDecimated), length(modSymbols)));

%% 7. QPSK解调
demodSymbols = pskdemod(rxDecimated, M, 0, 'gray');

%% 8. 转换回比特流并对齐
rxBitsMatrix = de2bi(demodSymbols, bps, 'left-msb');
rxBitStream = reshape(rxBitsMatrix.', [], 1);

% 确保接收比特流长度不超过发送比特流长度
validBits = min(length(rxBitStream), length(bitStream));
rxBitStream = rxBitStream(1:validBits);
bitStream = bitStream(1:validBits);

%% 9. 计算误比特率
numErrors = sum(bitStream ~= rxBitStream);
BER = numErrors / validBits;
fprintf('FHSS系统最终误比特率 (BER) = %f\n', BER);

%% 10. 绘制时域和频域波形图
% 时域波形
figure('Name', '时域波形');

% 发送信号时域波形
subplot(2,1,1);
tPlot = t(1:min(5*hopDuration, length(t))) * 1e6;  % 只显示前5个跳频周期，转换为us
sigPlot = txSignal(1:length(tPlot));
plot(tPlot, real(sigPlot), 'b-', 'LineWidth', 1.5);
hold on;
plot(tPlot, imag(sigPlot), 'r--', 'LineWidth', 1.5);
grid on;
title('发送端FHSS信号时域波形（前5个跳频周期）');
xlabel('时间 (μs)');
ylabel('幅度');
legend('实部', '虚部');

% 接收信号时域波形
subplot(2,1,2);
plot(tPlot, real(rxSignal(1:length(tPlot))), 'b-', 'LineWidth', 1.5);
hold on;
plot(tPlot, imag(rxSignal(1:length(tPlot))), 'r--', 'LineWidth', 1.5);
grid on;
title(['接收端FHSS信号时域波形（SNR = ' num2str(SNR) 'dB）']);
xlabel('时间 (μs)');
ylabel('幅度');
legend('实部', '虚部');

% 频域波形
figure('Name', 'FHSS频谱');

% 计算并显示频谱图
window = hamming(hopDuration);
noverlap = hopDuration/2;
nfft = 2048;

% 发送信号频谱图
subplot(2,1,1);
spectrogram(txSignal, window, noverlap, nfft, Fs, 'yaxis');
title('发送端FHSS信号频谱图');
ylabel('频率 (kHz)');
xlabel('时间 (ms)');

% 接收信号频谱图
subplot(2,1,2);
spectrogram(rxSignal, window, noverlap, nfft, Fs, 'yaxis');
title(['接收端FHSS信号频谱图 (SNR = ' num2str(SNR) 'dB)']);
ylabel('频率 (kHz)');
xlabel('时间 (ms)');

% 星座图
figure('Name', '星座图');
subplot(1,2,1);
scatter(real(modSymbols), imag(modSymbols), 'b.');
grid on;
title('发送端QPSK星座图');
xlabel('实部');
ylabel('虚部');
axis([-2 2 -2 2]);

subplot(1,2,2);
scatter(real(rxDecimated), imag(rxDecimated), 'r.');
grid on;
title(['接收端QPSK星座图 (SNR = ' num2str(SNR) 'dB)']);
xlabel('实部');
ylabel('虚部');
axis([-2 2 -2 2]);
