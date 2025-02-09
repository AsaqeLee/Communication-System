%% 基础FHSS（跳频扩频）通信系统
% FHSS系统的基本原理：
% 1. 载波频率按照预定的跳频图案在多个频点间跳变
% 2. 每个跳频周期内在特定频点上传输数据
% 3. 跳频图案由伪随机序列决定
% 4. 具有抗干扰和抗截获能力

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
numFreqs = 8;                     % 可用频点数量
freqSpacing = Fs/16;             % 相邻频点间隔
freqSet = (-numFreqs/2:numFreqs/2-1) * freqSpacing;  % 频点集合（对称分布）
hopDuration = 100;               % 每个跳频周期的采样点数

% 调制参数（使用QPSK作为基带调制）
M = 4;                 % QPSK调制阶数（每个符号2比特）
samplesPerSymbol = hopDuration;  % 每个符号的采样点数（与跳频周期对齐）
span = 6;              % 升余弦滤波器长度
rolloff = 0.35;        % 升余弦滤波器滚降系数

% 同步参数
syncSequenceLength = 32;          % 同步序列长度
syncBits = randi([0, 1], syncSequenceLength, 1);  % 随机同步序列

%% 2. 生成随机比特流
% 在数据前添加同步序列，用于接收端定时同步
bitStream = [syncBits; randi([0, 1], totalBits, 1)];

%% 3. QPSK调制
% 将比特流每两比特映射为一个QPSK符号
[modSymbols, ~] = modulateQPSK(bitStream);

%% 4. 脉冲成形
% 使用升余弦滤波器进行脉冲成形，减少带外辐射
[txSymbols, filterDelay] = pulseShaping(modSymbols, samplesPerSymbol, span, rolloff);

% 补零使信号长度为跳频周期的整数倍
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

% 按照跳频图案在不同频点上发送信号
txSignal = zeros(size(txSymbols));
for i = 1:numHops
    startIdx = (i-1)*hopDuration + 1;
    endIdx = min(i*hopDuration, length(txSymbols));
    freq = freqSet(hopPattern(i));
    txSignal(startIdx:endIdx) = txSymbols(startIdx:endIdx) .* exp(1j*2*pi*freq*t(startIdx:endIdx));
end

% 计算发射信号功率
txPower = mean(abs(txSignal).^2);
fprintf('发射信号功率 = %.4f W\n', txPower);
fprintf('发射信号功率 = %.2f dBW\n', 10*log10(txPower));
fprintf('发射信号功率 = %.2f dBm\n', 10*log10(txPower*1000));

%% 6. 通过AWGN信道
% 添加高斯白噪声模拟实际信道
SNR = 15;  % 信噪比 (dB)
rxSignal = awgn(txSignal, SNR, 'measured');


%% 7. 接收端解跳频
% 使用相同的跳频图案进行解跳频
rxSymbols = zeros(size(rxSignal));
for i = 1:numHops
    startIdx = (i-1)*hopDuration + 1;
    endIdx = min(i*hopDuration, length(rxSignal));
    freq = freqSet(hopPattern(i));
    rxSymbols(startIdx:endIdx) = rxSignal(startIdx:endIdx) .* exp(-1j*2*pi*freq*t(startIdx:endIdx));
end

%% 8. 匹配滤波
% 使用与发送端相同的升余弦滤波器进行匹配滤波
raisedCosine = rcosdesign(rolloff, span, samplesPerSymbol);
rxFiltered = filter(raisedCosine, 1, rxSymbols);

% 考虑滤波器延时进行抽样判决
validStart = filterDelay + 1;
rxDecimated = rxFiltered(validStart:samplesPerSymbol:end);
rxDecimated = rxDecimated(1:min(length(rxDecimated), length(modSymbols)));

%% 9. QPSK解调
% 将QPSK符号解调为比特流
rxBitStream = demodulateQPSK(rxDecimated);

%% 10. 同步检测和比特流对齐
% 在接收到的比特流中搜索同步序列
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

%% 11. 计算误比特率
% 计算系统性能指标
[BER, numErrors] = calculateBER(alignedTxBits, alignedRxBits);
fprintf('基础FHSS系统误比特率 (BER) = %f\n', BER);
fprintf('同步序列检测相关度 = %f%%\n', maxCorr/syncSequenceLength*100);

%% 12. 绘制结果
% 时域波形
figure('Name', '时域波形');
tPlot = t(1:min(5*hopDuration, length(t))) * 1e6;  % 显示前5个跳频周期

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