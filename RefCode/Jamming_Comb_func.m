function [Jam_Comb] = Jamming_Comb_func(Ts, fs, f_jam_center_freq, Bw_comb, Pj, ratio)
% 生成梳状谱干扰信号
% 输入参数：
% 1.Ts：帧长
% 2.fs：采样频率
% 3.f_jam_centetr_freq 
% 4.Bw_comb：被干扰信号的带宽
% 5.Pj：干扰噪声的功率，W
% 输出参数：
% 1.Jam_Comb
%% 参数设置
dt = 1/fs;                                % 时刻精度
tt_kuan = 0:dt:(Ts - dt);
n = length(tt_kuan);
% var_kuandai = Pj/(2*Bw_comb);               
noise = randn(1,n);                         % 产生噪声
noise_kuan = sqrt(Pj/ratio)*(noise-mean(noise));   % 使均值为0，修正方差
% va = var(noise_kuan);                       % 方差
% mean_nosie2 = mean(noise_kuan);

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
% periodogram(noise_kuan,[ ],length(noise_kuan),f_sample);   % 周期图法估计功率谱密度
% % axis([0 6 -200 0])
%
% figure
% plot(f,10*log10(lvbo_P1.^2))
% grid on
% title('功率谱')
%
% figure
% window = hamming(256);
% spectrogram(noise_kuan,window,'yaxis')      % STFT 时频图谱

%% 梳状滤波器设计
ord = 128;
fs_temp = fs/2;
bnd = [];
for ii=1:length(f_jam_center_freq)
    Wp = (f_jam_center_freq(ii) - 0.5*Bw_comb)/fs_temp;
    Ws = (f_jam_center_freq(ii) + 0.5*Bw_comb)/fs_temp;
    temp = [Wp Ws];
    %     bnd(ii,:) = temp;
    bnd = [bnd temp];
end
bM = fir1(ord,[bnd]);

ss = conv(noise_kuan,bM);     % 保留中心频率
Jam_Comb_temp = ss(ord/2+1:end-ord/2);
var1 = var(Jam_Comb_temp);
Jam_Comb = sqrt(Pj)*Jam_Comb_temp/sqrt(var1);
% JamPower = mean(abs(Jam_Comb).^2);

%% 绘制梳状滤波后的噪声时域和频域
% figure
% subplot(3,1,1)
% plot(tt_kuan((1:n/10)),Jam_Comb(1:n/10))
% grid on
% xlabel("时间/s")
% ylabel("幅度")
% title("宽带高斯噪声时域")
% 
% fft_y = fft(Jam_Comb);
% lvbo_P1 = abs(fft_y/n);               % 取幅频特性，除以点数
% lvbo_P1 = lvbo_P1(1:n/2+1);           % 截取前半段
% lvbo_P1(2:end-1) = 2*lvbo_P1(2:end-1);% 单侧频谱非直流分量记得乘以2
% f = fs*(0:(n/2))/n;             % 频率，最多到一半（奈奎斯特采样定理）
% subplot(3,1,2)
% plot(f,lvbo_P1)
% % axis([0 5e6 -100 0])
% grid on
% xlabel("频率/Hz")
% ylabel("幅度/v")
% title("宽带高斯噪声频域")
% 
% subplot(3,1,3)
% periodogram(Jam_Comb,[ ],length(Jam_Comb),fs);   % 周期图法估计功率谱密度
% % axis([0 6 -200 0])
% 
% figure
% % window = hamming(256);
% spectrogram(Jam_Comb,256,250,256,fs,'yaxis')   % STFT 时频图谱


end

