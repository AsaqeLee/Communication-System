function [Jam_Follower] = Jamming_Follower_func(Ts,fs, f_jam_center_freq, Bw_jam,Pj)
% 产生跟踪干扰信号
% 输入参数：
% f_jam_center_freq = [100 200 400 600 800];        % 干扰噪声的中心频率集合
% fs = 200e1;          % 最高的采样频率
% Bw_jam = 4e1;              % 干扰噪声的带宽
% 
% Ts = 3;                    % 时间持续长度
% Pj = 4e1;           % 干扰噪声的功率，W
% f0_sp = 0;                 % 被干扰信号的频率起始处
% fe_sp = 100e1;             % 被干扰信号的频率截至处
%% 基本参数设置
             
k = length(f_jam_center_freq);  % 干扰信号的个数
dt = 1/fs;     % 时刻精度
tt_kuan = 0:dt:(Ts - dt);  % 时间序列
n = length(tt_kuan);

%% 根据被干扰信号带宽产生高斯白噪声，并对于均值和方差进行修正，满足定义式
noise = randn(1,n);                                  
noise_kuan = sqrt(Pj)*(noise-mean(noise));  % 使均值为0，修正方差
% va = var(noise_kuan);                       % 方差
% mean_nosie1 = mean(noise_kuan);

%% 绘制滤波前的噪声时域和频域
% figure
% subplot(3,1,1)
% plot(tt_kuan((1:n/10)),noise_kuan(1:n/10))
% grid on
% xlabel("时间/s")
% ylabel("幅度")
% title("宽带高斯噪声时域")
% 
% fft_y = fft(noise_kuan);
% lvbo_P1 = abs(fft_y/n);               % 取幅频特性，除以点数
% lvbo_P1 = lvbo_P1(1:n/2+1);           % 截取前半段
% lvbo_P1(2:end-1) = 2*lvbo_P1(2:end-1);% 单侧频谱非直流分量记得乘以2
% f = f_sample*(0:(n/2))/n;             % 频率，最多到一半（奈奎斯特采样定理）
% subplot(3,1,2)
% plot(f,lvbo_P1)
% % axis([0 5e6 -100 0])
% grid on
% xlabel("频率/Hz")
% ylabel("幅度/v")
% title("宽带高斯噪声频域")
% 
% subplot(3,1,3)
% periodogram(noise_kuan,[ ],length(noise_kuan),f_sample);  % 周期图法估计功率谱密度
% axis([0 1 -200 0])
% 
% figure
% window = hamming(256);
% spectrogram(noise_kuan,window,256/4, 512,f_sample,'yaxis')      % STFT 时频图谱


%% 产生不同时间片的噪声函数，并通过相应的巴特沃斯带通滤波器
Jam_Follower_temp = [];                                      % 过完带通滤波器之后的信号集合
tt = Ts/k;       % 噪声干扰持续时间，假设持续时间相同
num = tt/dt;
f_sample_temp = fs/2;
ord = 128;
for p = 1:k
    
    f_jam_center_freq_current = f_jam_center_freq(p);                    % 干扰噪声中心频率的集合
    noise_current = noise_kuan((p-1)*num+1:p*num);     % 截取干扰信号
    % 设计带通滤波器
    %    Wp = 2*(f_jam(p)-0.5*Bw_jam)/f_sam(p);
    %    Ws = 2*(f_jam(p)+0.5*Bw_jam)/f_sam(p);
    Wp = (f_jam_center_freq_current - 0.5*Bw_jam)/f_sample_temp;
    Ws = (f_jam_center_freq_current + 0.5*Bw_jam)/f_sample_temp;
    
    bp_filter = fir1(ord,[Wp,Ws]); 
    ss = conv(noise_current,bp_filter);     % 保留中心频率
    Y_temp = ss(ord/2+1:end-ord/2);
%     figure  % 带通滤波后的干扰信号时、频域图
%     subplot(3,1,1)
%     plot(tt_kuan((1:len)),Y_temp)
%     grid on
%     xlabel("时间/s")
%     ylabel("幅度")
%     title("宽带高斯噪声时域")
%     
%     fft_y = fft(Y_temp);
%     lvbo_P1 = abs(fft_y/len);               % 取幅频特性，除以点数
%     lvbo_P1 = lvbo_P1(1:len/2+1);           % 截取前半段
%     lvbo_P1(2:end-1) = 2*lvbo_P1(2:end-1);% 单侧频谱非直流分量记得乘以2
%     f = f_sample*(0:(len/2))/len;             % 频率，最多到一半（奈奎斯特采样定理）
%     subplot(3,1,2)
%     plot(f,lvbo_P1)
%     % axis([0 5e6 -100 0])
%     grid on
%     xlabel("频率/Hz")
%     ylabel("幅度/v")
%     title("宽带高斯噪声频域")
%     
%     subplot(3,1,3)
%     periodogram(Y_temp,[ ],length(Y_temp),f_sample);  % 周期图法估计功率谱密度
%     
%     figure  % 带通滤波后的时频图谱
%     window = hamming(256);
%     spectrogram(Y_temp,window,256/4, 512,f_sample,'yaxis')      % STFT 时频图谱
    
%     figure
%     % win = blackman(256, 'periodic');%
%     win = hamming(256);
%     spectrogram(Y_temp, win,'yaxis');    
    Jam_Follower_temp = [Jam_Follower_temp Y_temp];
end
var_temp = var(Jam_Follower_temp);
Jam_Follower = sqrt(Pj)*Jam_Follower_temp/sqrt(var_temp);
% JamPower = mean(abs(Jam_Follower).^2);

% figure
% win = blackman(256, 'periodic');
% spectrogram(Jam_Follower, win, 256-256/4, 512,fs,'yaxis');

end

