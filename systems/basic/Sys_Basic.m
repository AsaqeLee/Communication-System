%% 基础QPSK通信系统
% 添加路径
addpath('../../src/modulation');
addpath('../../src/utils');

clear; clc; close all;

%% 1. 参数设置
% 基本参数
totalBits = 10000;      % 初始比特数
Fs = 1e6;              % 采样率 1MHz
Ts = 1/Fs;             % 采样周期

% 调制参数
M = 4;                 % QPSK调制阶数
samplesPerSymbol = 8;  % 每个符号的采样点数
span = 6;              % 滤波器符号跨度
rolloff = 0.35;        % 升余弦滤波器滚降系数

% 训练序列参数
trainLength = 100;     % 训练序列长度
trainBits = repmat([1;0;1;0], trainLength/4, 1);  % 训练序列：重复的1010模式

%% 2. 生成比特流（添加训练序列）
bitStream = [trainBits; randi([0, 1], totalBits, 1)];

%% 3. QPSK调制
% 将比特流重塑为2比特一组
bitMatrix = reshape(bitStream, 2, [])';
% 转换为符号索引
symbolIndices = bi2de(bitMatrix, 'left-msb');
% QPSK调制（使用格雷码映射）
modSymbols = pskmod(symbolIndices, M, pi/4, 'gray');  % 添加pi/4相位偏移以提高鲁棒性

%% 4. 脉冲成形
% 上采样
symbolsUp = upsample(modSymbols, samplesPerSymbol);
% 设计升余弦滤波器
raisedCosine = rcosdesign(rolloff, span, samplesPerSymbol);
% 发送滤波
txSymbols = filter(raisedCosine, 1, symbolsUp);
filterDelay = (span*samplesPerSymbol)/2;

%% 5. 通过AWGN信道
SNR = 15;  % 信噪比 (dB)
rxSignal = awgn(txSymbols, SNR, 'measured');

%% 6. 接收端匹配滤波
rxFiltered = filter(raisedCosine, 1, rxSignal);

%% 7. 定时恢复和相位校正
% 计算接收信号的平方以进行时钟恢复
squaredSignal = abs(rxFiltered).^2;
% 对平方信号进行FFT以检测符号速率
N = length(squaredSignal);
freqAxis = (-N/2:N/2-1)*(Fs/N);
squaredFFT = fftshift(fft(squaredSignal));
[~, maxIndex] = max(abs(squaredFFT));
symbolFreq = abs(freqAxis(maxIndex));

% 使用训练序列进行定时同步
trainSymbols = modSymbols(1:trainLength/2);  % 训练序列对应的符号
corrOutput = zeros(samplesPerSymbol, 1);

% 对不同采样相位进行相关
for i = 1:samplesPerSymbol
    sampledSignal = rxFiltered(i:samplesPerSymbol:min(i+trainLength/2*samplesPerSymbol, length(rxFiltered)));
    if length(sampledSignal) >= length(trainSymbols)
        corrOutput(i) = abs(sampledSignal(1:length(trainSymbols))' * trainSymbols);
    end
end

% 选择最佳采样相位
[~, bestSampleOffset] = max(corrOutput);

% 根据最佳采样相位进行抽样
rxDecimated = rxFiltered(bestSampleOffset:samplesPerSymbol:end);
rxDecimated = rxDecimated(1:min(length(rxDecimated), length(modSymbols)));

% 使用训练序列估计相位偏移
trainRx = rxDecimated(1:trainLength/2);
trainTx = modSymbols(1:trainLength/2);
phaseOffset = mean(angle(trainRx .* conj(trainTx)));

% 相位校正
rxCorrected = rxDecimated * exp(-1j*phaseOffset);

%% 8. QPSK解调
% 使用格雷码解调
demodSymbols = pskdemod(rxCorrected, M, pi/4, 'gray');
rxBitsMatrix = de2bi(demodSymbols, 2, 'left-msb');
rxBitStream = reshape(rxBitsMatrix.', [], 1);

%% 9. 去除训练序列并计算BER
% 提取有效数据比特
validTxBits = bitStream(length(trainBits)+1:end);
validRxBits = rxBitStream(length(trainBits)+1:min(length(rxBitStream), length(bitStream)));

% 计算BER
[BER, numErrors] = calculateBER(validTxBits, validRxBits);
fprintf('基础QPSK系统误比特率 (BER) = %f\n', BER);
fprintf('最佳采样相位 = %d\n', bestSampleOffset);
fprintf('估计相位偏移 = %.2f 度\n', phaseOffset*180/pi);

%% 10. 绘制结果
% 时域波形
figure('Name', '时域波形');
tPlot = (0:5*samplesPerSymbol-1)' * Ts * 1e6;  % 显示前5个符号，转换为us

% 发送信号时域波形
subplot(2,1,1);
plot(tPlot, real(txSymbols(1:length(tPlot))), 'b-', 'LineWidth', 1.5);
hold on;
plot(tPlot, imag(txSymbols(1:length(tPlot))), 'r--', 'LineWidth', 1.5);
grid on;
title('发送信号时域波形（前5个符号）');
xlabel('时间 (μs)');
ylabel('幅度');
legend('实部', '虚部');

% 接收信号时域波形
subplot(2,1,2);
plot(tPlot, real(rxSignal(1:length(tPlot))), 'b-', 'LineWidth', 1.5);
hold on;
plot(tPlot, imag(rxSignal(1:length(tPlot))), 'r--', 'LineWidth', 1.5);
grid on;
title(['接收信号时域波形（SNR = ' num2str(SNR) 'dB）']);
xlabel('时间 (μs)');
ylabel('幅度');
legend('实部', '虚部');

% 频谱图
figure('Name', '频谱');
subplot(2,1,1);
plotSpectrum(txSymbols, Fs, '发送信号频谱');

subplot(2,1,2);
plotSpectrum(rxSignal, Fs, ['接收信号频谱 (SNR = ' num2str(SNR) 'dB)']);

% 星座图
figure('Name', '星座图');
subplot(2,2,1);
plotConstellation(modSymbols, '发送端QPSK星座图（原始）');

subplot(2,2,2);
plotConstellation(rxDecimated, '接收端QPSK星座图（相位校正前）');

subplot(2,2,3);
plotConstellation(trainSymbols, '训练序列星座图');

subplot(2,2,4);
plotConstellation(rxCorrected, '接收端QPSK星座图（相位校正后）');

% 定时恢复结果
figure('Name', '定时恢复');
subplot(2,1,1);
plot(abs(squaredFFT));
title('平方信号频谱');
xlabel('频率点');
ylabel('幅度');

subplot(2,1,2);
stem(corrOutput);
title('定时相关输出');
xlabel('采样相位');
ylabel('相关值'); 