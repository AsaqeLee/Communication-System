%% TDMA系统，使用SINR衡量噪声和干扰
% 若假设各时隙信道状态一样（因为没有考虑小尺度衰落），则没必要划分时隙
clc
clear all
close all
tic

%% 信道编码参数
CodeType = 'RS码';
CodeTypeList = {'RS码', '卷积码'};
Code = find(ismember(CodeTypeList,CodeType)==1);
codeRate = 2/3;
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
ModulationType = '16QAM';
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

%% Parameters,使用基带奈奎斯特采样定理进行仿真，保证fs大于2*fc
Ts = 0.01;              % 帧/包 周期，即单个资源块长度
N = 1200;               % number of symbols for per resource block,对于TDMA即是每个帧传输的符号数
Rs = N/Ts;              % 符号速率
numPkts = 100;          % number of packets
numBits = N*K*codeRate; % number of bits per packet

fc = Rs*30;             % 载波频率
freqSep = Rs;

dt_bb = 1/Rs;           % 原始时间间隔，即码元周期
t_bb = 0:dt_bb:Ts-dt_bb;% 原始时间间隔序列

up_sample_fs = 100;     % 上采样倍数
fs = Rs*up_sample_fs;   % sample frequenct
dt_fs = 1/fs;           % 上采样之后的时间间隔
t_fs = 0:dt_fs:Ts-dt_fs;% 采样之后的时间间隔序列
n_fs = length(t_fs);

%% 数据组帧参数
FrameType = 'HDLC';
FrameTypeList = {'HDLC', 'IP'};
Frame = find(ismember(FrameTypeList,FrameType)==1);

switch Frame
    case 1 % HDLC数据帧
        HDLC_frame_begin = [0 1 1 1 1 1 1 0];     % HDLC帧开始标志
        HDLC_frame_address = [0 1 0 1 0 1 0 1];   % HDLC帧目的地址标志
        HDLC_frame_control = [0 0 0 1 1 0 1 0];   % HDLC帧控制标志，第1位为0，表示为信息帧.第2-4位表示发送帧的帧序号
        % 第5位是轮询位，值为1，第6-8位表示主站接收的下一个帧的序号
        frame_crc_poly = [1 1 0 0 0 0 0 0 0 0 0 0 0 0 1 0 1];  % HDLC帧CRC校验码的生成矩阵
        num_crc_poly = length(frame_crc_poly)-1;               % 信息序列需要左移的位数
        
        HDLC_frame_fcs_bit = [];                  % HDLC帧校验位标志，采用的是16位CRC循环校验
        HDLC_frame_end = [0 1 1 1 1 1 1 0];       % HDLC帧结束标志
        % 有效比特数
        numBits_data = numBits - length(HDLC_frame_begin) - length(HDLC_frame_address) - length(HDLC_frame_control) - num_crc_poly - length(HDLC_frame_end);
        
    case 2  % IP数据帧
        %%%%% IP数据帧用16进制表示前20字节，为
        %%%%  45 00 05 dc 4a cb 20 00 40 01 4B 52 c0 a8 00 27 7c 7f cf 0f
        %%% 本地主机机和远端主机的 IP 地址   源地址 ： 192.168.0.39  目的地址 ： 124.127.207.15
        ip_frame_version = [0 1 0 0];             % IP数据帧版本,占4位,一般的值为0100（IPv4），0110（IPv6）
        ip_frame_IHL = [0 1 0 1];                 % IP数据帧的首部长度，占4位字节，值为5表示无可变部分
        ip_frame_tos = [0 1 0 0 0 0 0 0];                      % IP数据帧的区分服务，占8位，一般不用
        ip_frame_len = [0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 1];      % IP数据帧的总长度，占16位，首部长度加数据长度
        ip_frame_id = [0 1 0 0 1 0 1 0 1 1 0 0 1 1 0 1];       % IP数据帧的标识
        ip_frame_flag = [0 0 1];                               % IP数据帧的标志
        ip_frame_offest = [0 0 0 0 0 0 0 0 0 0 0 0 0];         % IP数据帧的片偏移
        ip_frame_TTL = [0 0 1 0 0 0 0 0];                      % IP数据帧的生存时间
        ip_frame_protocol = [0 0 0 0 0 0 0 1];                 % IP数据帧的协议，1表示ICMP协议
        ip_frame_checksum = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]; % IP数据帧的首部校验和
        ip_frame_src = [1 1 0 0 0 0 0 0 1 0 1 0 1 0 0 0 ...
            0 0 0 0 0 0 0 0 0 0 1 0 0 1 1 1];                  % IP数据帧的本地主机源地址
        ip_frame_dst = [0 1 1 1 1 1 0 0 0 1 1 1 1 1 1 1 ...
            1 1 0 0 1 1 1 1 0 0 0 0 1 1 1 1];                  % IP数据帧的目的主机IP地址
        %ip_frame_optional = [];                               % IP数据帧的可选部分与填充部分，一般不加
        ip_frame_data = [];                                    % IP数据帧的数据部分
        len_ip1 = length(ip_frame_version)+length(ip_frame_IHL)+length(ip_frame_tos)+length(ip_frame_len)+length(ip_frame_id)+length(ip_frame_flag);
        len_ip2 = length(ip_frame_offest)+length(ip_frame_TTL)+length(ip_frame_protocol)+length(ip_frame_checksum)+length(ip_frame_src)+length(ip_frame_dst);
        len_ip = len_ip1+len_ip2;
        ip_frame11 = [ip_frame_version ip_frame_IHL ip_frame_tos];
        ip_frame22 = [ip_frame_id ip_frame_flag ip_frame_offest ip_frame_TTL ip_frame_protocol];
        ip_frame33 = [ip_frame_src ip_frame_dst];
        
        numBits_data = numBits - len_ip;                       % 有效比特数
end

%% 信道参数
ChannelType = '多径信道';
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
        numPath = 3;  % 3个径
        Path_delay = [dt_fs 15*dt_fs 22*dt_fs];    % 将多径时延和信道功率设置为固定值
        Path_delay_index = floor(Path_delay/dt_fs);
        P_path = [5 3 2];
        Path_gain = P_path/sum(P_path);        % 多径各路径的平均信道增益
        fD = 0;                        % 最大多普勒频移
        fD_est = fD;
    case 3  % 频移/相移信道，单径
        numPath = 1;
        Path_delay = 0;
        Path_delay_index = 0;
        velocity = 100;        % 单位：m/s
        c = 3e8;              % 光速，单位：m/s
        fD = fc*velocity/c;   % 多普勒频移
        fD_est = 0*fD;     % 假设多普勒估计值
end

%% 干扰信号参数设置
Bw_signal = 2*Rs;   % 被干扰信号带宽
fc_jam = fc;      % 干扰信号中心频率,与被干扰信号中心频率一致
f0_sp = fc_jam - Bw_signal/2;    % 信号起始频率
fe_sp = fc_jam + Bw_signal/2;    % 信号截止频率
beta = 0.7;   % 干扰信号功率占比：干扰/(噪声+干扰)；
Jam_type = 'SaoPin';
JamTypeList = {'None','SaoPin', 'SingleTone', 'Comb', 'Broadband', 'Follower'};
% None:无干扰；Saopin:扫频干扰；SingleTone:单音干扰；Comb：梳状谱；Broadband：全频带拦阻；Follower：跟踪干扰
JamMode = find(ismember(JamTypeList, Jam_type)==1);

%% SNR
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
        bit_source_sequence = randi([0 1],numBits_data,1);      % 0,1 bit, column vector 对应 dt_bb
        
        %% 数据组帧
        switch Frame
            case 1 % HDLC数据帧
                bit_zuoyi = [bit_source_sequence' zeros(1,num_crc_poly)]; % 将数据进行左移一位
                [q_crc,r_crc] = deconv(bit_zuoyi, frame_crc_poly);         % 用多项式除法求CRC校验码，q_crc为商，r_crc为余数
                r_crc = mod(abs(r_crc),2);                                % 进行模二处理
                HDLC_frame_fcs_bit = r_crc(numBits_data+1:end);             % CRC校验码
                bit_frame_sequence = [HDLC_frame_begin HDLC_frame_address HDLC_frame_control bit_source_sequence' HDLC_frame_fcs_bit HDLC_frame_end]';
                
            case 2 % IP数据帧
                ip_frame_lenz1 = dec2bin(numBits_data+5,16);     % 计算数据的长度，在IP数据帧用二进制表示
                ip_frame_lenz = double(boolean(ip_frame_lenz1-'0'));% 十进制转化为二进制是char型，需要进行强制转化
                ip_frame_data = bit_source_sequence';
                ip_sum = 0; % 计算首部校验和，初始校验和值全为0
                for counti = 1:(len_ip/16)
                    ip_frame1 = [ip_frame11 ip_frame_lenz ip_frame22 ip_frame_checksum ip_frame33];
                    ip_pian1 = ip_frame1(1,1+16*(counti-1):16*counti);
                    ip_zhong = num2str(ip_pian1);
                    ip_zhuan1 = bin2dec(ip_zhong);
                    ip_sum = ip_sum+ip_zhuan1; % 计算过程中，首先是二进制转为十进制然后再相加
                end
                ip_sumz = dec2bin(ip_sum,20); % 将十进制转化为二进制，20位是为了防止溢出
                ip_frame_checksumz1 = double(boolean(ip_sumz-'0'));
                ip_frame_checksumz2 = ~ip_frame_checksumz1;
                ip_frame_chz1 = ip_frame_checksumz2(1,5:end);
                ip_frame_chz2 = ip_frame_checksumz2(1,1:4);
                ip_frame_ce1 = bin2dec(num2str(ip_frame_chz1))+bin2dec(num2str(ip_frame_chz2)); % 将溢出后的值再转换到低位进行相加
                ip_frame_ce2 =dec2bin(ip_frame_ce1,16);
                ip_frame_checksumz = double(boolean(ip_frame_ce2-'0'));    % 将最后相加为16位的二进制数值作为首部校验和
                bit_frame_sequence = [ip_frame11 ip_frame_lenz ip_frame22 ip_frame_checksumz ip_frame33 ip_frame_data]';
        end
        
        %% 信道编码模块
        switch Code
            case 1 % 线性分组码
                bit_code_sequence = rs_code(bit_frame_sequence, numBits, m, n_rs, k_rs, gen_poly)';
            case 2 % 卷积码
                [bit_code_sequence, trel, tblen] = conven(bit_frame_sequence, puncpat, constrain_len); % 列向量
        end
        
        %% 调制
        [modSignal, hMod] = Modulation(bit_code_sequence, Mode, M, SamplesPerSymbol, fs, freqSep); % 列向量
        s2 = reshape(modSignal, 1, length(modSignal));
        Signal_mean_power = mean(abs(s2).^2);       % 信号平均功率
        % 基带调制信号的频谱
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
        if Mode==1 
            up_sample_fs_temp = up_sample_fs/SamplesPerSymbol;
        else
            up_sample_fs_temp = up_sample_fs;
        end
        data_transmit_upsample = rectpulse(s2,up_sample_fs_temp); % 上采样,矩形脉冲成型
        
        %% 射频载波调制,多普勒频移
        data_transmit_RF = data_transmit_upsample.*exp(1i*2*pi*(fc+fD)*t_fs);
        % 射频调制后的频谱
        %         figure
        %         fft_y = fft(data_transmit);
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
                ratio = num_comb * Bw_comb/Bw_signal;
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
        % 查看过信道后的频谱图
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
        %% 下变频,多普勒频移
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

        %% 接收端脉冲成型,下采样
        data_receiver_ds = downsample(data_receiver,up_sample_fs_temp, up_sample_fs_temp/2);      

        %% 解调
        data_receiver_ds = reshape(data_receiver_ds, length(data_receiver_ds), 1);
        [bit_Demodulated, hDemod] = Demodulation(data_receiver_ds, Mode, M, SamplesPerSymbol, fs, freqSep);
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
        nBitErr(pktX) = size(find([bit_decode(1:end-16) - bit_frame_sequence(1:end-16)]),1);
        
        %% 组帧分解
        switch Frame
            case 1 % HDLC数据帧
                %CRC校验
                bit_decode_len = length(bit_decode); % 求出解码后序列的长度
                HDLC_frame_flen = length(HDLC_frame_begin)+length(HDLC_frame_address)+length(HDLC_frame_control);% HDLC帧信息帧前的长度
                HDLC_frame_blen = length(HDLC_frame_end);% HDLC帧信息帧后的长度
                %bit_deframe = bit_decode(HDLC_frame_flen+1:1:(bit_decode_len-HDLC_frame_blen-num_crc_poly)); % 去掉帧结构的数据
                r_crc = 0;
                [q1_crc,r1_crc] = deconv(bit_decode(HDLC_frame_flen+1:1:(bit_decode_len-HDLC_frame_blen)),frame_crc_poly);
                r_crc = r_crc + mod(abs(r1_crc),2);
            case 2 % IP数据帧
                % 接收端的首部校验和计算  与发送端同理
                ip_frame_re0 = bit_decode';
                ip_frame_re1 = ip_frame_re0(1,1:len_ip); % 将解码后的数据中的IP数据帧的部分进行提取
                ip_resum = 0;
                % 16个二进制数字为一组，对首部校验和进行计算
                for conti = 1:(len_ip/16)
                    ip_repian1 = ip_frame_re1(1,1+16*(counti-1):16*counti);
                    ip_rezhong = num2str(ip_repian1);
                    ip_rezhuan = bin2dec(ip_rezhong);
                    ip_resum = ip_resum+ip_rezhuan;
                end
                ip_resumz1 = dec2bin(ip_resum,20);
                ip_re_checksumz1 = double(boolean(ip_resumz1-'0'));
                ip_re_checksumz2 = ~ip_re_checksumz1;
                ip_re_chz1 = ip_re_checksumz2(1,5:end);
                ip_re_chz2 = ip_re_checksumz2(1,1:4);
                ip_re_ce1 = bin2dec(num2str(ip_re_chz1))+bin2dec(num2str(ip_re_chz2));
                ip_re_ce2 =dec2bin(ip_re_ce1,16);
                ip_re_checksumz = double(boolean(ip_re_ce2-'0'));
        end        
    end   
    pktInEr = nBitErr>0;  % returns 1 if current packet has an error in
    erTot(ii) = sum(nBitErr);                % total errors in all packets
    simBer(ii) = erTot(ii)/(numBits*numPkts);    % bit error rate
    
    totPktEr(ii) = sum(pktInEr);             % total packets in error
    totPktErRate(ii) = totPktEr(ii)/numPkts; % packet error rate  
end

%% 绘图
figure
semilogy(SINR_dB,simBer,'mx-','LineWidth',2);
hold on
semilogy(SINR_dB,totPktErRate,'bx-','LineWidth',2);
axis([-6 14 10^-5 1])
grid on; box on;
legend('BER', 'PER','Location','southwest');
xlabel('SNR(dB)')
ylabel('Bit Error Rate')
% str_temp = ['Sig: ', 'DSSS',', Code: ',CodeType,', CR: ',codeRateStr,', Mo: ',ModulationType,', Chan: ',ChannelType,', Jam: ',Jam_type];
str_temp = ['TDMA',', ',CodeType,', ', codeRateStr,', ', ModulationType,', ', ChannelType,', ', Jam_type];
title(str_temp)

toc
