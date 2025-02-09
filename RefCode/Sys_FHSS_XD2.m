%% FHSS系统
clc
clear
close all
tic
%% 调制参数
ModulationType = 'QPSK';
modeTypeList = {'FSK', 'GMSK', 'BPSK', 'QPSK', 'OQPSK','16QAM', '64QAM'};
Mode = find(ismember(modeTypeList,ModulationType)==1);
% Mode取值 1:FSK; 2:GMSK; 3:BPSK; 4:QPSK; 5:OQPSK; 6:16QAM; 7:64QAM;
switch Mode
    case 1 % FPSK
        M = 2; K = log2(M); % 2FSK
    case 2 % GMSK
        M = 2; K = log2(M);
    case 3 % BPSK
        M = 2; K = log2(M);
    case 4 % QPSK
        M = 4; K = log2(M);
    case 5 % OQPSK
        M = 4; K = log2(M);
    case 6 % 16QAM
        M = 16; K = log2(M);
    case 7 % 64QAM
        M = 64; K = log2(M);  % constellation size  % bits per symbol
end
SamplesPerSymbol = 2;
%% Parameters 
Ts = 0.01;               % 帧/包 周期
N = 2400;                % number of symbols for per packet,基带信号带宽为200Hz
Rs = N/Ts;               % 原始符号速率
numPkts = 6000;            % number of packets sent
numBits = N*K;           % number of bits per packet
fc = Rs*30;              % 载波频率
freqSep = 10*Rs;         % FSK调制相关参数
up_sample_fs = 100;      % 上采样倍数
fs = Rs*up_sample_fs;    % 采样频率
dt_fs = 1/fs;            % 上采样之后的时间间隔
t_fs = 0:dt_fs:Ts-dt_fs; % 采样之后的时间间隔序列
n_fs = length(t_fs);
%% 跳频参数
fh_seq = [fc-4*Rs, fc-2*Rs, fc, fc+2*Rs, fc+4*Rs]; % spread spectrum sequence
freqLen = length(fh_seq); % length of spread spectrum sequence
%% 干扰信号参数设置
Bw_signal = 10*Rs;               % 被干扰信号带宽
fc_jam = fc;                     % 干扰信号中心频率,与被干扰信号中心频率一致
f0_sp = fc_jam - Bw_signal/2;    % 信号起始频率
fe_sp = fc_jam + Bw_signal/2;    % 信号截止频率
beta = 0.7;                      % 干扰信号功率占比：干扰/(噪声+干扰)；
Jam_type = 'Broadband';
JamTypeList = {'None','SaoPin', 'SingleTone', 'Comb', 'Broadband', 'Follower'};
% None:无干扰；Saopin:扫频干扰；SingleTone:单音干扰；Comb：梳状谱；Broadband：全频带拦阻；Follower：跟踪干扰
JamMode = find(ismember(JamTypeList, Jam_type)==1);

%% SINR
SINR_dB  = 14:2:16;     % multiple SNR values
erTot = zeros(1,length(SINR_dB));
simBer = zeros(1,length(SINR_dB));
totPktEr = zeros(1,length(SINR_dB));
totPktErRate = zeros(1,length(SINR_dB));

%% --------------------------------蒙特卡洛仿真------------------------------------
for ii = 1:length(SINR_dB)
    SINR_dB(ii)
    SINR_de = 10^(SINR_dB(ii)/10);
    nBitErr = zeros(1,numPkts);
    for pktX = 1:numPkts
        bit_sequence = randi([0 1],numBits,1);      % 0,1 bit, column vector 对应 dt_bb
        [modSignal, hMod] = Modulation(bit_sequence, Mode, M, SamplesPerSymbol, fs, freqSep); % 列向量
        data_modu = reshape(modSignal, 1, length(modSignal));
        %基带调制信号的频谱
        %         figure
        %         up_sample_bb = 10;
        %         data_transmit_upsample = rectpulse(modSignal,up_sample_bb); % 上采样  200
        %         n_bb = length(data_transmit_upsample);
        %         fs_bb = N*up_sample_bb;
        %         fft_y = fft(data_transmit_upsample);
        %         lvbo_P1 = abs(fft_y/n_bb);               % 取幅频特性，除以点数
        %         lvbo_P1 = lvbo_P1(1:n_bb/2+1);           % 截取前半段
        %         lvbo_P1(2:end-1) = 2*lvbo_P1(2:end-1); % 单侧频谱非直流分量记得乘以2
        %         f = fs_bb*(0:(n_bb/2))/n_bb;             % 频率，最多到一半（奈奎斯特采样定理）
        %         plot(f,lvbo_P1)
        %         % axis([0 5e6 -100 0])
        %         grid on
        %         xlabel("频率/Hz")
        %         ylabel("幅度/v")
        %         title("信号频域")
        
        %% 发射端脉冲成型
        if Mode == 1 
            up_sample_fs_temp = up_sample_fs/SamplesPerSymbol;
        else
            up_sample_fs_temp = up_sample_fs;
        end
        data_upsample = rectpulse(data_modu,up_sample_fs_temp); % 上采样,矩形脉冲成型
        
        %% 射频载波调制
        fh_index = randi([1,freqLen],1,1);  % 跳频选择        
        fc_current_Pkt = fh_seq(fh_index);       
        data_RF = data_upsample.*exp(1i*2*pi*(fc_current_Pkt)*t_fs);
        SigPower = mean(abs(data_RF).^2);        %射频调制后的频谱
%         figure
%         fft_y = fft(data_RF(1:n_fs));
%         lvbo_P1 = abs(fft_y/n_fs);               % 取幅频特性，除以点数
%         lvbo_P1 = lvbo_P1(1:n_fs/2+1);           % 截取前半段
%         lvbo_P1(2:end-1) = 2*lvbo_P1(2:end-1); % 单侧频谱非直流分量记得乘以2
%         f = fs*(0:(n_fs/2))/n_fs;             % 频率，最多到一半（奈奎斯特采样定理）
%         plot(f,lvbo_P1)
%         % axis([0 5e6 -100 0])
%         grid on
%         xlabel("频率/Hz")
%         ylabel("幅度/v")
%         title("信号频域")
        
        % 加干扰
        JamPower = beta * SigPower/SINR_de; % jam power
        switch JamMode
            case 1
                Jam_signal = 0;
                beta = 0;  % 认为全是白噪声
            case 2 % SaoPin
                [Jam_signal] = Jamming_LinearFrequency_func(Ts, fs, JamPower, f0_sp, fe_sp);
            case 3 % SingleTone
                [Jam_signal] = Jamming_SingleTone_func(fc_jam, Ts, fs, JamPower);
            case 4 % Comb
                num_comb = 3;        % 梳齿数目
                Bw_comb = Bw_signal/(num_comb+1)/7;  % 梳谱宽度
                ratio = num_comb * Bw_comb/Bw_signal;
                f_jam_center_freq_temp = linspace(f0_sp,fe_sp,num_comb+2);
                f_jam_center_freq = f_jam_center_freq_temp(2:end-1);   % 梳谱中心频率
                [Jam_signal] = Jamming_Comb_func(Ts, fs, f_jam_center_freq, Bw_comb, JamPower, ratio);
            case 5 % Broadband
                [Jam_signal] = Jamming_Broadband_func(Ts, fs, JamPower, f0_sp, fe_sp);
            case 6 % Follower
                num_follower = 4;
                Bw_jam = Bw_signal/(num_follower+1)/4;  % 干扰信号带宽
                f_jam_center_freq_temp = linspace(f0_sp,fe_sp,num_follower+2);
                f_jam_center_freq = f_jam_center_freq_temp(2:end-1);  % 干扰噪声的中心频率集合
                [Jam_signal] = Jamming_Follower_func(Ts,fs, f_jam_center_freq, Bw_jam, JamPower);
        end
%         JamPower_cal = mean(abs(Jam_signal).^2);  % 计算干扰信号功率
        
        % white Noise
        NoisePower = (1 - beta) * SigPower/SINR_de;     % noise power
        noise_seq = sqrt(NoisePower/2) *(randn(1,length(data_RF)) + 1i*randn(1,length(data_RF))); % white guassian noise, 0dB variance
%         NoisePower_cal = mean(abs(noise_seq).^2); % 计算噪声信号功率
        
        y_channel_all = data_RF + Jam_signal + noise_seq;  % add jam signal and additive white gaussian noise        
%         figure
%         fft_y = fft(y_channel_all);
%         lvbo_P1 = abs(fft_y/n_fs);               % 取幅频特性，除以点数
%         lvbo_P1 = lvbo_P1(1:n_fs/2+1);           % 截取前半段
%         lvbo_P1(2:end-1) = 2*lvbo_P1(2:end-1); % 单侧频谱非直流分量记得乘以2
%         f = fs*(0:(n_fs/2))/n_fs;             % 频率，最多到一半（奈奎斯特采样定理）
%         plot(f,lvbo_P1)
%         % axis([0 5e6 -100 0])
%         grid on
%         xlabel("频率/Hz")
%         ylabel("幅度/v")
%         title("信号频域")

        %% 下变频
        data_receiver = y_channel_all.*exp(-1i*2*pi*(fc_current_Pkt)*t_fs);
%         figure
%         fft_y = fft(data_receiver(1:n_fs));
%         lvbo_P1 = abs(fft_y/n_fs);               % 取幅频特性，除以点数
%         lvbo_P1 = lvbo_P1(1:n_fs/2+1);           % 截取前半段
%         lvbo_P1(2:end-1) = 2*lvbo_P1(2:end-1); % 单侧频谱非直流分量记得乘以2
%         f = fs*(0:(n_fs/2))/n_fs;             % 频率，最多到一半（奈奎斯特采样定理）
%         plot(f,lvbo_P1)
%         % axis([0 5e6 -100 0])
%         grid on
%         xlabel("频率/Hz")
%         ylabel("幅度/v")
%         title("信号频域")
        
        %% 接收端脉冲成型
        data_downsample = downsample(data_receiver, up_sample_fs_temp, up_sample_fs_temp/2);
        
        %% 解调
        data_downsample = reshape(data_downsample, length(data_downsample), 1);
        [bit_demodu, hDemod] = Demodulation(data_downsample, Mode, M, SamplesPerSymbol, fs, freqSep);
        if Mode==2
            bit_demodu = [bit_demodu(16+1:end); zeros(16,1)];
        end
         
        %% counting errors for real and imaginary
        nBitErr(pktX) = size(find(bit_demodu(1:end-16) - bit_sequence(1:end-16)),1);
    end

    erTot(ii) = sum(nBitErr);                % total errors in all packets
    simBer(ii) = erTot(ii)/(numBits*numPkts);    % bit error rate
end

%% 绘图
figure
semilogy(SINR_dB,simBer,'x-','LineWidth',2);
hold on
axis([14 16 10^-7 1])
grid on; box on;
legend('BER', 'Location','southwest');
xlabel('SINR (dB)')
ylabel('Bit Error Rate')

% figure
% % window = hamming(256);
% spectrogram(signal_Trasmit(1:2000000),256,250,256,fs,'yaxis')   % STFT 时频图谱

toc
