function [Jam_Broadband] = Jamming_Broadband_func(Ts, fs, Pj, f0_sp, fe_sp)
% 生成全频带拦阻干扰信号
% 输入参数：
% Bw_signal:被干扰信号的带宽
% fs:采样频率
% Ts:
% Pj: 干扰噪声的功率，W
% f0_sp:被干扰信号的频率起始处
% fe_sp:被干扰信号的频率截至处

%% 全频带干扰从非0KHz开始,被干扰信号的带宽为 signal_bb
dt = 1/fs;   % 时刻精度
tt_kuan = 0:dt:(Ts - dt);
n = length(tt_kuan);
% var_kuandai = Pj/(2*Bw_signal);
noise = randn(1,n);                                    % 产生噪声
% mean_nosie = mean(noise);
noise_kuan = sqrt(Pj)*(noise-mean(noise));  % 使均值为0，修正方差
% va2 = var(noise_kuan);                                  % 方差
% mean_nosie22 = mean(noise_kuan);

%% 根据被干扰信号的带宽设计带通滤波器，采用巴特沃斯带通滤波器，阶数为30
% Wp = 2*f0_sp/fs;
% Ws = 2*fe_sp/fs;
% [b2,a2] = butter(30,[Wp,Ws]);
% Jam_Broadband_temp = filter(b2,a2,noise_kuan);

ord = 128;
fs_temp = fs/2;

Wp = f0_sp/fs_temp;
Ws = fe_sp/fs_temp;
temp = [Wp Ws];

bM = fir1(ord,[temp]);

ss = conv(noise_kuan,bM);     % 保留中心频率
Jam_Broadband_temp = ss(ord/2+1:end-ord/2);

var_temp = var(Jam_Broadband_temp);                         % 方差
Jam_Broadband = sqrt(Pj)*Jam_Broadband_temp/sqrt(var_temp);
% JamPower = mean(abs(Jam_Broadband).^2);
%% 绘制相关图像
% figure
% subplot(3,1,1)
% plot(tt_kuan,Jam_Broadband)
% xlabel("时间/s")
% ylabel("幅度")
% title("宽带高斯噪声时域")
% 
% fft_y2 = fft(Jam_Broadband);
% lvbo_P2 = abs(fft_y2/n);              % 取幅频特性，除以点数
% lvbo_P2 = lvbo_P2(1:n/2+1);           % 截取前半段
% lvbo_P2(2:end-1) = 2*lvbo_P2(2:end-1); % 单侧频谱非直流分量记得乘以2
% f2 = fs*(0:(n/2))/n;          % 频率，最多到一半（奈奎斯特采样定理）
% subplot(3,1,2)
% plot(f2,lvbo_P2)
% xlabel("频率/Hz")
% ylabel("幅度/v")
% title("宽带高斯噪声频域")
% 
% subplot(3,1,3)
% periodogram(Jam_Broadband,[ ],length(Jam_Broadband),fs);   % 周期图法估计功率谱密度
% axis([0 6 -200 0])
% 
% figure
% % window2 = hamming(256);
% spectrogram(Jam_Broadband,256,250,256,fs,'yaxis')             % 频谱图

end

