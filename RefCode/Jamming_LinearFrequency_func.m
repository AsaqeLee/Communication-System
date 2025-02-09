function [Jam_saopin] = Jamming_LinearFrequency_func(Ts, fs, Pj, f0_sp, fe_sp)
% 生成线性扫频干扰
%---------------------------------
% 输入参数：
% 1.Ts：单周期时间
% 2.fs：采样频率
% 3.Pj：干扰信号功率,单位：W
% 4.f0_sp：扫频起始频率
% 5.fe_sp：扫频截止频率
% 输出参数：
% 1.Jam_saopin
%---------------------------------
dt = 1/fs;    % 时刻精度
t_saopin = 0:dt:Ts-dt;  % 3对应3个周期，800*(1/fs)为精度
Jam_saopin = chirp(mod(t_saopin,Ts),f0_sp,Ts,fe_sp);
% 第一个参数表示时间长度，第二个参数表示当t=0s时对应的频率，第三个和第四个参数为当t=cirs时对应的频率
% 归一化
norm = mean(abs(Jam_saopin).^2);
Jam_saopin = sqrt(Pj/norm)*Jam_saopin;

% figure
% subplot(3,1,1);
% plot(t_saopin,Jam_saopin);
% title('线性扫频信号波形');xlabel('时间(s)');ylabel('幅度(V)');
% 
% ft = f0_sp+(fe_sp-f0_sp)*mod(t_saopin,Ts)/Ts;
% subplot(3,1,2);
% plot(t_saopin,ft);
% title('线性扫频信号频率-时间图');xlabel('时间(s)');ylabel('频率(Hz)');
% 
% t_saopin_pinpu = 0:dt:Ts-dt;         % 求频谱时不能对多周期的求，对1个周期进行FFT 800*
% delf = 1/dt/length(t_saopin_pinpu);
% f_sp = (0:length(t_saopin_pinpu)-1)*delf;
% x_saopin_pinpu = chirp(t_saopin_pinpu,f0_sp,Ts,fe_sp);
% C1_saopin = fft(x_saopin_pinpu);               % 对载波信号进行傅里叶变换 
% cxf_saopin = abs(C1_saopin);                   % 求绝对值
% cxf_saopin = cxf_saopin/max(cxf_saopin);       % 归一化
% 
% subplot(3,1,3);
% plot(f_sp,cxf_saopin);
% title('线性扫频信号归一化频谱');xlabel('频率(Hz)');ylabel('功率');
% % axis([0e6 40e6 0 1]);
% % periodogram(x_saopin_pinpu,[ ],length(x_saopin_pinpu),fs/800,'onesided');title('线性扫频信号功率谱');
% 
% figure
% spectrogram(Jam_saopin,256,250,256,fs,'yaxis')
end

