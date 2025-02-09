%% Simple Communication System Simulation without Channel Coding and Interference
% 添加参考代码路径
addpath('RefCode');

clear; clc; close all;

%% 1. 参数设置
totalBits = 10000;  % 总比特数
% 生成随机比特流
bitStream = randi([0, 1], totalBits, 1);

bps = 2;  % 每个符号的比特数 (QPSK)
% 如果比特流长度不能被bps整除，则补零
if mod(length(bitStream), bps) ~= 0
    bitStream = [bitStream; zeros(bps - mod(length(bitStream), bps), 1)];
end

%% 2. 星座映射 (使用 QPSK 调制)
ModulationType = 'QPSK';
modeTypeList = {'FSK', 'GMSK', 'BPSK', 'QPSK', 'OQPSK', '16QAM', '64QAM'};
Mode = find(ismember(modeTypeList, ModulationType) == 1);
M = 4;  % 对于 QPSK 调制

% SamplesPerSymbol, Fs, freqSep 为占位参数（QPSK时并不使用频率间隔）
SamplesPerSymbol = 1; 
Fs = 1; 
freqSep = 2;

% 调用Modulation函数完成调制（参考 RefCode/Modulation.m）
[modSignal, ~] = Modulation(bitStream, Mode, M, SamplesPerSymbol, Fs, freqSep);

%% 3. 上采样及升余弦滤波
sps = 4;  % 每符号采样率
upsampledSignal = upsample(modSignal, sps);

rolloff = 0.22;  % 升余弦滤波器滚降因子
span = 10;       % 滤波器跨度，单位符号
rcosFilter = rcosdesign(rolloff, span, sps);

% 通过滤波器进行脉冲整形
txSignal = filter(rcosFilter, 1, upsampledSignal);

%% 4. 加噪 (AWGN)
SNR = 20;  % 信噪比 (dB)
rxSignal = awgn(txSignal, SNR, 'measured');

%% 5. 接收端匹配滤波和采样
matchedRx = filter(rcosFilter, 1, rxSignal);

% 计算匹配滤波器的时延，rCOS滤波器的群时延为 span*sps/2
delay = span * sps / 2;
rxSamples = matchedRx(delay+1:sps:end);

%% 6. 星座解调
% 使用 pskdemod 进行 QPSK 解调
demodSymbols = pskdemod(rxSamples, M, 0, 'gray');

%% 7. 将符号转换回比特流
rxBitsMatrix = de2bi(demodSymbols, bps, 'left-msb');
rxBitStream = reshape(rxBitsMatrix.', [], 1);
% 截取与发送比特流长度一致的部分
rxBitStream = rxBitStream(1:length(bitStream));

%% 8. 计算误比特率 (BER)
numErrors = sum(bitStream ~= rxBitStream);
BER = numErrors / length(bitStream);
fprintf('最终误比特率 (BER) = %f\n', BER); 