%% OFDM 系用户的多径信道仍有问题，需要再检查
clc
% clear all
% close all
tic

%% 信道编码参数
CodeType = '卷积码';
CodeTypeList = {'RS码', '卷积码'};
Code = find(ismember(CodeTypeList,CodeType)==1);
codeRate = 1/2;
switch Code
    case 1 % RS码
        m = 4;
        if( codeRate == 1/2)
            n_rs = 12;
            k_rs = 6;  % 信息组长度
            codeRateStr = '1/2';
        elseif (codeRate == 2/3)
            n_rs = 12;
            k_rs = 8;  % 信息组长度   
            codeRateStr = '2/3';
        end
        gen_poly = 19; % 生成多项式
        
    case 2 % 卷积码
        constrain_len = 8;   % 约束长度
        if(codeRate == 1/2)
            puncpat = [1,1]; codeRateStr = '1/2';
        elseif(codeRate == 2/3)
            puncpat = [1,1,1,0]; codeRateStr = '2/3';
        elseif(codeRate == 3/4)
            puncpat = [1,1,1,0,1,0]; codeRateStr = '3/4';
        end
end
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
        M = 4; K = 1;
    case 6 % 16QAM
        M = 16; K = log2(M);
    case 7 % 64QAM
        M = 64; K = log2(M);  % constellation size  % bits per symbol
end

SamplesPerSymbol = 2;

%% OFDM参数
N_sc = 64;                   % IFFT数=子载波数, N_sc个并行的符号
LenCP = N_sc/4;              % CP
numBits_PerOFDM = N_sc*K*codeRate; % number of bits per ofdm symbol

Ts_ofdm = 4e-3;              % ofdm 符号周期，数据+CP
numOFDMSyms = 30;            % number of ofdm symbols per frame/packet
Ts_Pkt = Ts_ofdm*numOFDMSyms;% 帧周期
Ts = Ts_Pkt;
numBits_PerPkt = numBits_PerOFDM*numOFDMSyms;

Ts_ofdm_data = Ts_ofdm*(N_sc/(LenCP+N_sc)); % ofdm 符号周期，数据
f_sub = 1/Ts_ofdm_data;      % 子载波宽度
B = f_sub*N_sc;
freqSep = f_sub/3;

dt_bb = Ts_ofdm/(N_sc+LenCP);
t_bb = 0:dt_bb:Ts_Pkt-dt_bb; 

fc = B*30;                   % 载波频率

up_sample_fs = 100;
fs = B*up_sample_fs;         % sample frequenct
dt_fs = 1/fs;                % 上采样之后的时间间隔
t_fs = 0:dt_fs:Ts_Pkt-dt_fs; % 采样之后的时间间隔序列
n_fs = length(t_fs);

numPkts = 1000;               % number of packets sent

%% 信道参数
ChannelType = '高斯白噪声信道';
ChannelTypeList = {'高斯白噪声信道', '多径信道', '频移相移信道'};
Channel = find(ismember(ChannelTypeList,ChannelType)==1);
% 前两种信道情况下不考虑多普勒频移
switch Channel
    case 1  % 高斯白噪声信道，单径
        numPath = 1;
        Path_delay = 0;
        Path_delay_index = 0;
        fD = 0;
        fD_est = fD;
    case 2  % 多径信道
        numPath = 2;  % 3个径
        Path_delay = [0*dt_fs  2*dt_fs];    % 将多径时延和信道功率设置为固定值
        Path_delay_index = floor(Path_delay/dt_fs);
        P_path = [8 2];
        Path_gain = P_path/sum(P_path);        % 多径各路径的平均信道增益
        fD = 0;                        % 最大多普勒频移
        fD_est = fD;
    case 3  % 频移/相移信道，单径
        numPath = 1;
        Path_delay = 0;
        Path_delay_index = 0;
        velocity = 30;        % 单位：m/s
        c = 3e8;              % 光速，单位：m/s
        fD = fc*velocity/c;   % 多普勒频移
        fD_est = 0.99*fD;     % 假设多普勒估计值
end

%% 干扰信号参数设置
Bw_signal = 2*B;   % 被干扰信号带宽
fc_jam = fc;      % 干扰信号中心频率,与被干扰信号中心频率一致
f0_sp = fc_jam - Bw_signal/2;    % 信号起始频率
fe_sp = fc_jam + Bw_signal/2;    % 信号截止频率
% Pjam = 10;            % 干扰信号功率,单位：W
beta = 0.7;   % 干扰信号功率占比：干扰/(噪声+干扰)；
Jam_type = 'SaoPin';
JamTypeList = {'None','SaoPin', 'SingleTone', 'Comb', 'Broadband', 'Follower'};
% None:无干扰；Saopin:扫频干扰；SingleTone:单音干扰；Comb：梳状谱；Broadband：全频带拦阻；Follower：跟踪干扰
JamMode = find(ismember(JamTypeList, Jam_type)==1);

%% SINR
SINR_dB  = -6:2:14;     % multiple SNR values
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
        % pktX
        %% generation bit sequence
        bit_source_sequence = randi([0 1],numBits_PerPkt,1);      % 0,1 bit, column vector 对应 dt1
        
        %% 信道编码模块
        switch Code
            case 1 % 线性分组码
                bit_code_sequence = rs_code(bit_source_sequence, numBits_PerPkt, m, n_rs, k_rs, gen_poly)';
            case 2 % 卷积码
                [bit_code_sequence, trel, tblen] = conven(bit_source_sequence, puncpat, constrain_len); % 列向量
        end
        %% 调制
        [modSignal, hMod] = Modulation(bit_code_sequence, Mode, M, SamplesPerSymbol, fs, freqSep); % 列向量
        
        % 基带调制信号的频谱
%         figure
%         up_sample_bb = 10;
%         data_transmit_upsample = rectpulse(modSignal,up_sample_bb); % 上采样  200
%         n_bb = length(data_transmit_upsample);
%         fs_bb = N_ofdmSym*up_sample_bb;
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
        %% ifft、添加CP
        data_ifft_pre = reshape(modSignal, N_sc, []);       % 串并转换
        data_ifft = ifft(data_ifft_pre)*sqrt(N_sc);
        data_CP = [data_ifft(N_sc-LenCP+1:end,:); data_ifft]; % 添加CP

        s2 = reshape(data_CP,1,[]);       
        Signal_mean_power = mean(abs(s2).^2);       % 信号平均功率
        
        % OFDM调制后的频谱
%         figure
%         up_sample_ofdm = 10;
%         data_transmit_upsample = rectpulse(s2,up_sample_ofdm); % 上采样
%         fs_ofdm_bb = 1/(dt_bb/up_sample_ofdm);
%         n_ofdm_bb = length(data_transmit_upsample);
%         fft_y = fft(data_transmit_upsample);
%         lvbo_P1 = abs(fft_y/n_ofdm_bb);               % 取幅频特性，除以点数
%         lvbo_P1 = lvbo_P1(1:n_ofdm_bb/2+1);           % 截取前半段
%         lvbo_P1(2:end-1) = 2*lvbo_P1(2:end-1); % 单侧频谱非直流分量记得乘以2
%         f = fs_ofdm_bb*(0:(n_ofdm_bb/2))/n_ofdm_bb;             % 频率，最多到一半（奈奎斯特采样定理）
%         plot(f,lvbo_P1)
%         % axis([0 5e6 -100 0])
%         grid on
%         xlabel("频率/Hz")
%         ylabel("幅度/v")
%         title("信号频域")

        %% 发射端脉冲成型,上采样      
        if Mode == 1 
            up_sample_fs_temp = up_sample_fs/SamplesPerSymbol;
        else
            up_sample_fs_temp = up_sample_fs;
        end
        data_transmit_upsample = rectpulse(s2,up_sample_fs_temp); % 上采样,矩形脉冲成型
        %% 射频载波调制
        data_transmit_RF = data_transmit_upsample.*exp(1i*2*pi*(fc+fD)*t_fs);
        % Signal_mean_power = mean(abs(data_transmit).^2);       % 信号平均功率
        % 射频调制后的频谱
%                 figure
%                 fft_y = fft(data_transmit);
%                 lvbo_P1 = abs(fft_y/n_fs);               % 取幅频特性，除以点数
%                 lvbo_P1 = lvbo_P1(1:n_fs/2+1);           % 截取前半段
%                 lvbo_P1(2:end-1) = 2*lvbo_P1(2:end-1); % 单侧频谱非直流分量记得乘以2
%                 f = fs*(0:(n_fs/2))/n_fs;             % 频率，最多到一半（奈奎斯特采样定理）
%                 plot(f,lvbo_P1)
%                 % axis([0 5e6 -100 0])
%                 grid on
%                 xlabel("频率/Hz")
%                 ylabel("幅度/v")
%                 title("信号频域")

        %% Channel+Jam+Noise
        % 1. Channel
        switch Channel
            case 1 % 仅考虑加性高斯白噪声
                data_transmit = data_transmit_RF;
            case 2 % 多径信道
                data_transmit_MP = zeros(numPath,length(data_transmit_RF));
                for pp = 1:numPath
                    tau = Path_delay_index(pp);
                    if  tau == 0
                        data_transmit_MP(pp,:) = data_transmit_RF;
                    else
                        data_transmit_MP(pp,:) = [zeros(1,tau)  data_transmit_RF(1:end-tau)];
                    end
                end
                data_transmit = sqrt(Signal_mean_power*Path_gain)*data_transmit_MP;
                
            case 3 % 频移/相移信道
                data_transmit = data_transmit_RF;   % 在射频部分体现
        end
        Signal_mean_power_channel = mean(abs(data_transmit).^2);
        
        % 2. Jam
        JamPower = beta * Signal_mean_power_channel/SINR_de; % jam power
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
                Bw_comb = Bw_signal/(num_comb+1)/3;  % 梳谱宽度
                ratio = num_comb * Bw_comb/Bw_signal;% 干扰带宽占总带宽的比例
                f_jam_center_freq_temp = linspace(f0_sp,fe_sp,num_comb+2);
                f_jam_center_freq = f_jam_center_freq_temp(2:end-1);   % 梳谱中心频率
                [Jam_signal] = Jamming_Comb_func(Ts, fs, f_jam_center_freq, Bw_comb, JamPower, ratio);
            case 5 % Broadband
                [Jam_signal] = Jamming_Broadband_func(Bw_signal, Ts, fs, JamPower, f0_sp, fe_sp);
            case 6 % Follower
                num_follower = 4;
                Bw_jam = Bw_signal/(num_follower+1)/4;  % 干扰信号带宽
                f_jam_center_freq_temp = linspace(f0_sp,fe_sp,num_follower+2);
                f_jam_center_freq = f_jam_center_freq_temp(2:end-1);  % 干扰噪声的中心频率集合
                [Jam_signal] = Jamming_Follower_func(Ts,fs, f_jam_center_freq, Bw_jam,JamPower);
        end
        meanJamPower = mean(abs(Jam_signal).^2);  % 计算干扰信号功率
        
        % 3. white Noise
        %stanDevNoise = sqrt(Signal_mean_power_channel/SINR_de)*sqrt(seqLen)/sqrt(2);     % noise amplitude
        NoisePower = (1 - beta) * Signal_mean_power_channel/SINR_de;     % noise power
        noise_seq = sqrt(NoisePower/2) *(randn(1,length(data_transmit)) + 1i*randn(1,length(data_transmit))); % white guassian noise, 0dB variance
        meanNoisePower = mean(abs(noise_seq).^2); % 计算噪声信号功率
        
        y_channel_all = data_transmit + Jam_signal + noise_seq;  % add jam signal and additive white gaussian noise
                        
        %% 下变频
        data_receiver = y_channel_all.*exp(-1i*2*pi*(fc+fD_est)*t_fs);
        %         figure
        %         fft_y = fft(data_receiver);
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
        data_receiver_ds = downsample(data_receiver, up_sample_fs_temp, up_sample_fs_temp/2);
       
        %% 去CP、fft
        y1 = reshape(data_receiver_ds, N_sc+LenCP, []);
        y2 = y1(LenCP+1:end,:);
        y_fft = fft(y2)/sqrt(N_sc);
        
        %% 解调
        y_Demod_Pre = reshape(y_fft, [], 1);
        [bit_Demodulated, hDemod] = Demodulation(y_Demod_Pre, Mode, M, SamplesPerSymbol, fs, freqSep);
        if Mode==2
            bit_Demodulated = [bit_Demodulated(16+1:end); zeros(16,1)];
        end
        %% 接收机解码模块
        switch Code
            case 1 % RS码解码 
                bit_decode = dec_rs(bit_Demodulated, m, n_rs, k_rs, gen_poly); 
                bit_decode = reshape(bit_decode, length(bit_decode),1); % 转换为列向量
            case 2 % 卷积码解码
                bit_decode = vitdec(bit_Demodulated, trel, tblen, 'trunc', 'hard', puncpat);
        end
        %% counting errors for real and imaginary
        nBitErr(pktX) = size(find([bit_decode(1:end-16) - bit_source_sequence(1:end-16)]),1);
    end
    pktInEr = nBitErr>0;  % returns 1 if current packet has an error in
    erTot(ii) = sum(nBitErr);                % total errors in all packets
    simBer(ii) = erTot(ii)/(numBits_PerPkt*numPkts);    % bit error rate
    
    totPktEr(ii) = sum(pktInEr);             % total packets in error
    totPktErRate(ii) = totPktEr(ii)/numPkts; % packet error rate
end

%% 绘图
figure
semilogy(SINR_dB,simBer,'mx-','LineWidth',2);
hold on
semilogy(SINR_dB,totPktErRate,'bx-','LineWidth',2);
% axis([0 20 10^-5 1])
axis([-6 14 10^-5 1])
grid on; box on;
legend('BER', 'PER','Location','southwest');
xlabel('SINR(dB)')
ylabel('Bit Error Rate')
str_temp = ['OFDM',', ',CodeType,', ', codeRateStr,', ', ModulationType,', ', ChannelType,', ', Jam_type];
title(str_temp)
toc
