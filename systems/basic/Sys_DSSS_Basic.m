%% 基础DSSS通信系统（不含干扰）
% 添加路径
addpath('../../src/modulation');
addpath('../../src/utils');

clear; clc; close all;

%% 1. 参数设置
% 基本参数
totalBits = 10000;      % 初始比特数
Fs = 1e6;              % 采样率 1MHz
Ts = 1/Fs;             % 采样周期

% 扩频参数
m = 5;                 % m序列阶数
mseq = mseq_gen(m);    % 生成m序列
spreadingFactor = length(mseq);  % 扩频因子为m序列长度（31）
pnSequence = 2*mseq - 1;        % 转换为±1序列

% 调制参数
M = 4;                 % QPSK调制阶数
samplesPerSymbol = 4;  % 每个符号的采样点数（降低以减少处理延时）
span = 6;              % 滤波器符号跨度
rolloff = 0.35;        % 升余弦滤波器滚降系数

% 同步参数
syncSequenceLength = 64;          % 同步序列长度
syncBits = [ones(syncSequenceLength/2,1); zeros(syncSequenceLength/2,1)];  % 使用固定的同步序列模式

%% 2. 生成随机比特流（添加同步序列）
bitStream = [syncBits; randi([0, 1], totalBits, 1)];

%% 3. QPSK调制
[modSymbols, ~] = modulateQPSK(bitStream);

%% 4. 脉冲成形
[txSymbols, filterDelay] = pulseShaping(modSymbols, samplesPerSymbol, span, rolloff);

%% 5. 扩频调制
% 对每个码片进行上采样，以匹配信号采样率
pnUpsampled = repelem(pnSequence, samplesPerSymbol);

% 扩频处理
spreadSignal = zeros(size(txSymbols));
for i = 1:length(txSymbols)
    pnIndex = mod(i-1, length(pnUpsampled)) + 1;
    spreadSignal(i) = txSymbols(i) * pnUpsampled(pnIndex);
end

% 计算发射信号功率
txPower = mean(abs(spreadSignal).^2);
fprintf('发射信号功率 = %.4f W\n', txPower);
fprintf('发射信号功率 = %.2f dBW\n', 10*log10(txPower));
fprintf('发射信号功率 = %.2f dBm\n', 10*log10(txPower*1000));

%% 6. 通过AWGN信道
SNR = 15;  % 信噪比 (dB)
rxSignal = awgn(spreadSignal, SNR, 'measured');

%% 7. 解扩
% 解扩处理
despreadSignal = zeros(size(rxSignal));
for i = 1:length(rxSignal)
    pnIndex = mod(i-1, length(pnUpsampled)) + 1;
    despreadSignal(i) = rxSignal(i) * pnUpsampled(pnIndex);
end

%% 8. 匹配滤波
raisedCosine = rcosdesign(rolloff, span, samplesPerSymbol);
rxFiltered = filter(raisedCosine, 1, despreadSignal);

% 考虑滤波器延时的抽样判决
validStart = filterDelay + 1;
rxDecimated = rxFiltered(validStart:samplesPerSymbol:end);
rxDecimated = rxDecimated(1:min(length(rxDecimated), length(modSymbols)));

%% 9. QPSK解调
rxBitStream = demodulateQPSK(rxDecimated);

%% 10. 同步检测和比特流对齐
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

%% 11. 计算误比特率
[BER, numErrors] = calculateBER(alignedTxBits, alignedRxBits);
fprintf('基础DSSS系统误比特率 (BER) = %f\n', BER);
fprintf('同步序列检测相关度 = %f%%\n', maxCorr/syncSequenceLength*100);
fprintf('扩频因子 = %d\n', spreadingFactor);

%% 12. 绘制结果
% 时域波形
figure('Name', '时域波形');
tPlot = (0:5*spreadingFactor*samplesPerSymbol-1)' * Ts * 1e6;  % 显示前5个扩频周期，转换为us

% 发送信号时域波形
subplot(2,1,1);
plot(tPlot, real(spreadSignal(1:length(tPlot))), 'b-', 'LineWidth', 1.5);
hold on;
plot(tPlot, imag(spreadSignal(1:length(tPlot))), 'r--', 'LineWidth', 1.5);
grid on;
title('发送端DSSS信号时域波形（前5个扩频周期）');
xlabel('时间 (μs)');
ylabel('幅度');
legend('实部', '虚部');

% 接收信号时域波形
subplot(2,1,2);
plot(tPlot, real(rxSignal(1:length(tPlot))), 'b-', 'LineWidth', 1.5);
hold on;
plot(tPlot, imag(rxSignal(1:length(tPlot))), 'r--', 'LineWidth', 1.5);
grid on;
title(['接收端DSSS信号时域波形（SNR = ' num2str(SNR) 'dB）']);
xlabel('时间 (μs)');
ylabel('幅度');
legend('实部', '虚部');

% 频谱图
figure('Name', 'DSSS频谱');
subplot(2,1,1);
plotSpectrum(spreadSignal, Fs, '发送端DSSS信号频谱');

subplot(2,1,2);
plotSpectrum(rxSignal, Fs, ['接收端DSSS信号频谱 (SNR = ' num2str(SNR) 'dB)']);

% 星座图
figure('Name', '星座图');
subplot(1,2,1);
plotConstellation(modSymbols, '发送端QPSK星座图');

subplot(1,2,2);
plotConstellation(rxDecimated, ['接收端QPSK星座图 (SNR = ' num2str(SNR) 'dB)']);

% % PN序列自相关
% figure('Name', 'PN序列特性');
% [acf, lags] = xcorr(pnSequence, 'coeff');
% subplot(2,1,1);
% plot(lags, acf, 'LineWidth', 1.5);
% grid on;
% title('PN序列自相关特性');
% xlabel('时延');
% ylabel('相关系数');
% 
% % PN序列频谱
% subplot(2,1,2);
% plotSpectrum(pnSequence, Fs/spreadingFactor, 'PN序列频谱'); 