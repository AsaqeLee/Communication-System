%% Simple OFDM Communication System Simulation without Channel Coding and Interference
% 本示例实现了OFDM系统的基本仿真流程

clear; clc; close all;

%% 1. 参数设置
% 生成随机比特流
totalBits = 10000;  % 初始比特数（确保能被bps整除）
bps = 2;  % 每个符号所含比特数 (QPSK)
if mod(totalBits, bps) ~= 0
    totalBits = totalBits + (bps - mod(totalBits, bps));
end
bitStream = randi([0, 1], totalBits, 1);

%% 2. QPSK 星座映射
M = 4;  % QPSK
% 将比特流重塑为2比特一组
bitMatrix = reshape(bitStream, 2, [])';
% 将每组比特转换为十进制符号索引（0~3）
symbolIndices = bi2de(bitMatrix, 'left-msb');
% 星座映射（采用灰度编码）
modSymbols = pskmod(symbolIndices, M, 0, 'gray');

%% 3. OFDM 参数设置
Nfft = 64;       % FFT大小
Ncp = 16;        % 循环前缀长度
Fs = 1e6;        % 采样率设为1MHz，用于绘图
df = Fs/Nfft;    % 子载波间隔

% 填充，使得QPSK符号数能被Nfft整除
numSymbols = length(modSymbols);
remainder = mod(numSymbols, Nfft);
if remainder > 0
    paddingSymbols = Nfft - remainder;
    % 使用符号0的映射（对应比特00）进行填充
    modSymbols = [modSymbols; pskmod(0, M, 0, 'gray')*ones(paddingSymbols,1)];
    % 同时填充比特流（便于后续BER计算，仅比较原始比特数部分）
    bitStream = [bitStream; zeros(paddingSymbols * bps, 1)];
end

%% 4. OFDM 发射端
% 将调制后的符号分帧，每帧包含Nfft个符号
numOFDMSymbols = length(modSymbols) / Nfft;
ofdmSymbols_freq = reshape(modSymbols, Nfft, numOFDMSymbols);

% IFFT 生成时域OFDM符号
ofdmSymbols_time = ifft(ofdmSymbols_freq, Nfft, 1);

% 添加循环前缀：在每帧前添加最后Ncp个样本
ofdmSymbols_withCP = [ofdmSymbols_time(end-Ncp+1:end, :); ofdmSymbols_time];

% 序列化发送信号
txSignal = reshape(ofdmSymbols_withCP, [], 1);

%% 5. 通过AWGN信道
SNR = 5;  % 信噪比 (dB)
rxSignal = awgn(txSignal, SNR, 'measured');

%% 6. OFDM 接收端
% 将接收信号重新分帧，每帧长度为 (Nfft + Ncp)
receivedMatrix = reshape(rxSignal, Nfft+Ncp, []);

% 去除循环前缀
received_noCP = receivedMatrix(Ncp+1:end, :);

% FFT变换恢复频域符号
receivedFreq = fft(received_noCP, Nfft, 1);

% 将恢复的符号序列序列化
receivedSymbols = reshape(receivedFreq, [], 1);

%% 7. QPSK 星座解调
demodSymbols = pskdemod(receivedSymbols, M, 0, 'gray');

%% 8. 将解调符号转换回比特流
rxBitsMatrix = de2bi(demodSymbols, bps, 'left-msb');
rxBitStream = reshape(rxBitsMatrix.', [], 1);

% 对齐比特数：仅比较原始比特数部分
expectedBits = length(bitStream);
rxBitStream = rxBitStream(1:expectedBits);

%% 9. 计算误比特率 (BER)
numErrors = sum(bitStream ~= rxBitStream);
BER = numErrors / expectedBits;
fprintf('OFDM系统最终误比特率 (BER) = %f\n', BER);

%% 10. 绘制时域和频域波形图
% 为了更好地显示波形，只显示第一个OFDM符号
figure('Name', '时域波形');

% 时域波形 - 发送信号
subplot(2,1,1);
t = (0:length(ofdmSymbols_withCP(:,1))-1)/Fs * 1e6; % 转换为微秒
plot(t, real(ofdmSymbols_withCP(:,1)), 'b-', 'LineWidth', 1.5);
hold on;
plot(t, imag(ofdmSymbols_withCP(:,1)), 'r--', 'LineWidth', 1.5);
grid on;
title('发送端OFDM符号时域波形（第一个符号）');
xlabel('时间 (μs)');
ylabel('幅度');
legend('实部', '虚部');

% 时域波形 - 接收信号
subplot(2,1,2);
plot(t, real(receivedMatrix(:,1)), 'b-', 'LineWidth', 1.5);
hold on;
plot(t, imag(receivedMatrix(:,1)), 'r--', 'LineWidth', 1.5);
grid on;
title(['接收端OFDM符号时域波形（第一个符号，SNR = ' num2str(SNR) 'dB）']);
xlabel('时间 (μs)');
ylabel('幅度');
legend('实部', '虚部');

% 频域波形
figure('Name', 'OFDM频谱');

% 计算发送信号频谱
Tx_fft = fftshift(fft(ofdmSymbols_time(:,1), Nfft));
Tx_spectrum = 20*log10(abs(Tx_fft)/max(abs(Tx_fft)));  % 归一化为dB
f = (-Nfft/2:Nfft/2-1)*Fs/Nfft/1e3;  % 频率轴（kHz）

% 计算接收信号频谱
Rx_fft = fftshift(fft(received_noCP(:,1), Nfft));
Rx_spectrum = 20*log10(abs(Rx_fft)/max(abs(Rx_fft)));  % 归一化为dB

% 绘制发送信号频谱
subplot(2,1,1);
plot(f, Tx_spectrum, 'b-', 'LineWidth', 1.5);
grid on;
title('发送端OFDM符号频谱');
xlabel('频率 (kHz)');
ylabel('幅度 (dB)');
ylim([-40 5]);
xlim([-Fs/2e3 Fs/2e3]);

% 绘制接收信号频谱
subplot(2,1,2);
plot(f, Rx_spectrum, 'r-', 'LineWidth', 1.5);
grid on;
title(['接收端OFDM符号频谱 (SNR = ' num2str(SNR) 'dB)']);
xlabel('频率 (kHz)');
ylabel('幅度 (dB)');
ylim([-40 5]);
xlim([-Fs/2e3 Fs/2e3]);

% 绘制星座图
figure('Name', '星座图');
subplot(1,2,1);
scatter(real(modSymbols(1:Nfft)), imag(modSymbols(1:Nfft)), 'b.');
grid on;
title('发送端QPSK星座图');
xlabel('实部');
ylabel('虚部');
axis([-2 2 -2 2]);

subplot(1,2,2);
scatter(real(receivedSymbols(1:Nfft)), imag(receivedSymbols(1:Nfft)), 'r.');
grid on;
title(['接收端QPSK星座图 (SNR = ' num2str(SNR) 'dB)']);
xlabel('实部');
ylabel('虚部');
axis([-2 2 -2 2]); 