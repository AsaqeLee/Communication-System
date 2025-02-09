%% 基础FHSS通信系统（不含干扰）
% 添加路径
addpath('../../src/modulation');
addpath('../../src/utils');

clear; clc; close all;

%% 1. 参数设置
% 基本参数
totalBits = 10000;      % 初始比特数
Fs = 1e6;              % 采样率 1MHz
Ts = 1/Fs;             % 采样周期

% 跳频参数
numFreqs = 8;                     % 跳频频点数量
freqSpacing = Fs/16;             % 频点间隔
freqSet = (-numFreqs/2:numFreqs/2-1) * freqSpacing;  % 可用频点集合
hopDuration = 100;               % 每个跳频周期的采样点数

% 调制参数
M = 4;                 % QPSK调制阶数
samplesPerSymbol = hopDuration;  % 每个符号的采样点数
span = 6;              % 滤波器符号跨度
rolloff = 0.35;        % 升余弦滤波器滚降系数

% 同步参数
syncSequenceLength = 32;          % 同步序列长度
syncBits = randi([0, 1], syncSequenceLength, 1);  % 生成同步比特序列

%% 2. 生成随机比特流（添加同步序列）
bitStream = [syncBits; randi([0, 1], totalBits, 1)];

%% 3. QPSK调制
[modSymbols, ~] = modulateQPSK(bitStream);

%% 4. 脉冲成形
[txSymbols, filterDelay] = pulseShaping(modSymbols, samplesPerSymbol, span, rolloff);

% 补零使信号长度为hopDuration的整数倍
numHops = ceil(length(txSymbols)/hopDuration);
totalLength = numHops * hopDuration;
if length(txSymbols) < totalLength
    txSymbols = [txSymbols; zeros(totalLength - length(txSymbols), 1)];
end

%% 5. 跳频调制
% 生成跳频图案（使用伪随机序列）
rng(42);  % 设置随机种子以确保发射接收使用相同的跳频图案
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

%% 6. 添加单音干扰
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

%% 7. 通过AWGN信道
SNR = 15;  % 信噪比 (dB)
rxSignal = awgn(rxSignal_withJam, SNR, 'measured');

%% 8. 接收端解跳频
rxSymbols = zeros(size(rxSignal));
for i = 1:numHops
    startIdx = (i-1)*hopDuration + 1;
    endIdx = min(i*hopDuration, length(rxSignal));
    freq = freqSet(hopPattern(i));
    rxSymbols(startIdx:endIdx) = rxSignal(startIdx:endIdx) .* exp(-1j*2*pi*freq*t(startIdx:endIdx));
end

%% 9. 匹配滤波
raisedCosine = rcosdesign(rolloff, span, samplesPerSymbol);
rxFiltered = filter(raisedCosine, 1, rxSymbols);

% 考虑滤波器延时的抽样判决
validStart = filterDelay + 1;
rxDecimated = rxFiltered(validStart:samplesPerSymbol:end);
rxDecimated = rxDecimated(1:min(length(rxDecimated), length(modSymbols)));

%% 10. QPSK解调
rxBitStream = demodulateQPSK(rxDecimated);

%% 11. 同步检测和比特流对齐
% 在接收比特流中搜索同步序列
maxCorr = -inf;
bestOffset = 0;
for offset = 0:length(rxBitStream)-syncSequenceLength
    correlation = sum(rxBitStream(offset+1:offset+syncSequenceLength) == syncBits);
    if correlation > maxCorr
        maxCorr = correlation;
        bestOffset = offset;
    end
end

% 提取对齐后的数据比特
alignedRxBits = rxBitStream(bestOffset+syncSequenceLength+1:end);
alignedTxBits = bitStream(syncSequenceLength+1:min(length(alignedRxBits)+syncSequenceLength, end));

%% 12. 计算误比特率
[BER, numErrors] = calculateBER(alignedTxBits, alignedRxBits);
fprintf('基础FHSS系统误比特率 (BER) = %f\n', BER);
fprintf('同步序列检测相关度 = %f%%\n', maxCorr/syncSequenceLength*100);

%% 13. 绘制结果
% 时域波形
figure('Name', '时域波形');
tPlot = t(1:min(5*hopDuration, length(t))) * 1e6;  % 只显示前5个跳频周期，转换为us

% 发送信号时域波形
subplot(2,1,1);
plot(tPlot, real(txSignal(1:length(tPlot))), 'b-', 'LineWidth', 1.5);
hold on;
plot(tPlot, imag(txSignal(1:length(tPlot))), 'r--', 'LineWidth', 1.5);
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

% 频谱图
figure('Name', 'FHSS频谱');
subplot(2,1,1);
plotSpectrum(txSignal, Fs, '发送端FHSS信号频谱');

subplot(2,1,2);
plotSpectrum(rxSignal, Fs, ['接收端FHSS信号频谱 (SNR = ' num2str(SNR) 'dB)']);

% 星座图
figure('Name', '星座图');
subplot(1,2,1);
plotConstellation(modSymbols, '发送端QPSK星座图');

subplot(1,2,2);
plotConstellation(rxDecimated, ['接收端QPSK星座图 (SNR = ' num2str(SNR) 'dB)']);

% 跳频图案
figure('Name', '跳频图案');
stairs(1:numHops, freqSet(hopPattern)/1e3, 'LineWidth', 1.5);
grid on;
title('跳频图案');
xlabel('跳频周期');
ylabel('频率 (kHz)');

% 时频分析
figure('Name', '时频分析');
window = hamming(hopDuration);
noverlap = hopDuration/2;
nfft = 2048;
spectrogram(txSignal, window, noverlap, nfft, Fs, 'yaxis');
title('FHSS信号时频图');
ylabel('频率 (kHz)');
xlabel('时间 (ms)'); 