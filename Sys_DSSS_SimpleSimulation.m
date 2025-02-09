%% Simple DSSS (Direct Sequence Spread Spectrum) Communication System Simulation
% 本示例实现了直接序列扩频系统的基本仿真流程

clear; clc; close all;

%% 1. 参数设置
% 基本参数
totalBits = 10000;      % 初始比特数
bps = 2;               % 每个符号所含比特数 (QPSK)
Fs = 1e6;             % 采样率 1MHz
Ts = 1/Fs;            % 采样周期

% 扩频参数
spreadingFactor = 31;                  % 扩频因子
pnSequence = 2*randi([0,1], spreadingFactor, 1) - 1;  % 生成PN序列 (-1,1)

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

%% 4. 扩频调制
% 对每个符号进行上采样
samplesPerSymbol = spreadingFactor;
symbolsUpsample = upsample(modSymbols, samplesPerSymbol);

% 添加成形滤波器
span = 6;  % 滤波器符号跨度
raisedCosine = rcosdesign(0.35, span, samplesPerSymbol);
filterDelay = span * samplesPerSymbol / 2;  % 滤波器群延时

% 对发送信号进行滤波
txSymbols = filter(raisedCosine, 1, symbolsUpsample);

% 补偿滤波器延时
txSymbols = [txSymbols(filterDelay+1:end); zeros(filterDelay, 1)];

% 扩频处理
spreadSignal = zeros(size(txSymbols));
for i = 1:length(modSymbols)
    startIdx = (i-1)*spreadingFactor + 1;
    endIdx = min(i*spreadingFactor, length(txSymbols));
    if endIdx > startIdx
        spreadSignal(startIdx:endIdx) = txSymbols(startIdx:endIdx) .* pnSequence(1:endIdx-startIdx+1);
    end
end

%% 5. 通过AWGN信道
SNR = 20;  % 信噪比 (dB)
rxSignal = awgn(spreadSignal, SNR, 'measured');

%% 6. 接收端解扩
% 解扩处理
despreadSignal = zeros(size(rxSignal));
for i = 1:length(modSymbols)
    startIdx = (i-1)*spreadingFactor + 1;
    endIdx = min(i*spreadingFactor, length(rxSignal));
    if endIdx > startIdx
        despreadSignal(startIdx:endIdx) = rxSignal(startIdx:endIdx) .* pnSequence(1:endIdx-startIdx+1);
    end
end

% 匹配滤波
rxFiltered = filter(raisedCosine, 1, despreadSignal);

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
fprintf('DSSS系统最终误比特率 (BER) = %f\n', BER);

%% 10. 绘制时域和频域波形图
% 时域波形
figure('Name', '时域波形');

% 发送信号时域波形
subplot(2,1,1);
t = (0:length(spreadSignal)-1)*Ts;
tPlot = t(1:min(5*spreadingFactor, length(t))) * 1e6;  % 只显示前5个码片周期，转换为us
sigPlot = spreadSignal(1:length(tPlot));
plot(tPlot, real(sigPlot), 'b-', 'LineWidth', 1.5);
hold on;
plot(tPlot, imag(sigPlot), 'r--', 'LineWidth', 1.5);
grid on;
title('发送端DSSS信号时域波形（前5个码片周期）');
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

% 频域波形
figure('Name', 'DSSS频谱');

% 计算并显示频谱
nfft = 2048;
f = (-nfft/2:nfft/2-1)*Fs/nfft/1e3;  % 频率轴（kHz）

% 发送信号频谱
Tx_fft = fftshift(fft(spreadSignal, nfft));
Tx_spectrum = 20*log10(abs(Tx_fft)/max(abs(Tx_fft)));

subplot(2,1,1);
plot(f, Tx_spectrum, 'b-', 'LineWidth', 1.5);
grid on;
title('发送端DSSS信号频谱');
xlabel('频率 (kHz)');
ylabel('幅度 (dB)');
ylim([-60 5]);

% 接收信号频谱
Rx_fft = fftshift(fft(rxSignal, nfft));
Rx_spectrum = 20*log10(abs(Rx_fft)/max(abs(Rx_fft)));

subplot(2,1,2);
plot(f, Rx_spectrum, 'r-', 'LineWidth', 1.5);
grid on;
title(['接收端DSSS信号频谱 (SNR = ' num2str(SNR) 'dB)']);
xlabel('频率 (kHz)');
ylabel('幅度 (dB)');
ylim([-60 5]);

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