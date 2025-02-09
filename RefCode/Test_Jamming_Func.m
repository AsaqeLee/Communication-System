clc
% clear all
% close all
tic
%% 干扰信号参数设置
Bw_signal = 20e6;   % 被干扰信号带宽
fc_jam = 20e6;      % 干扰信号中心频率,与被干扰信号中心频率一致
f0_sp = fc_jam - Bw_signal/2;    % 信号起始频率
fe_sp = fc_jam + Bw_signal/2;    % 信号截止频率
fs = 80e6;          % 采样频率
Ts = 0.01;          % 码元周期
Pjam = 10;          % 干扰信号功率,单位：W

Jam_type = 'SaoPin';
JamTypeList = {'SaoPin', 'SingleTone', 'Comb', 'Broadband', 'Follower'};
JamMode = find(ismember(JamTypeList,Jam_type)==1);
%% 干扰信号生成
switch JamMode
    case 1 % SaoPin        
        [Jam_signal] = Jamming_LinearFrequency_func(Ts, fs, Pjam, f0_sp, fe_sp);
    case 2 % SingleTone
        [Jam_signal] = Jamming_SingleTone_func(fc_jam, Ts, fs, Pjam);
    case 3 % Comb
        num_comb = 3;        % 梳齿数目
        Bw_comb = Bw_signal/(num_comb+1)/2;  % 梳谱宽度
        ratio = num_comb * Bw_comb/Bw_signal;
        f_jam_center_freq_temp = linspace(f0_sp,fe_sp,num_comb+2);
        f_jam_center_freq = f_jam_center_freq_temp(2:end-1);   % 梳谱中心频率
        [Jam_signal] = Jamming_Comb_func(Ts, fs, f_jam_center_freq, Bw_comb, Pjam, ratio);
    case 4 % Broadband
        [Jam_signal] = Jamming_Broadband_func(Bw_signal, Ts, fs, Pjam, f0_sp, fe_sp);
    case 5 % Follower
        num_follower = 4;
        Bw_jam = Bw_signal/(num_follower+1)/2;  % 干扰信号带宽
        f_jam_center_freq_temp = linspace(f0_sp,fe_sp,num_follower+2);
        f_jam_center_freq = f_jam_center_freq_temp(2:end-1);  % 干扰噪声的中心频率集合
        [Jam_signal] = Jamming_Follower_func(Ts,fs, f_jam_center_freq, Bw_jam,Pjam);       
end
meanPower = mean(abs(Jam_signal).^2)


%% 扫频干扰
% [Jam_Saopin] = Jamming_LinearFrequency_func(Ts, fs, Pjam, f0_sp, fe_sp);

%% 单音干扰
% [Jam_SingleTone] = Jamming_SingleTone_func(fc_jam, Ts, fs, Pjam);

%% 梳状谱
% num_comb = 3;        % 梳齿数目
% Bw_comb = Bw_signal/(num_comb+1)/2;  % 梳谱宽度
% f_jam_center_freq_temp = linspace(f0_sp,fe_sp,num_comb+2);
% f_jam_center_freq = f_jam_center_freq_temp(2:end-1);   % 梳谱中心频率
% [Jam_Comb] = Jamming_Comb_func(Ts, fs, f_jam_center_freq, Bw_comb, Pjam);

%% 全频带拦阻
% [Jam_Broadband] = Jamming_Broadband_func(Bw_signal, Ts, fs, Pjam, f0_sp, fe_sp);

%% 跟踪干扰
% num_follower = 4;
% Bw_jam = Bw_signal/(num_follower+1)/2;  % 干扰信号带宽
% f_jam_center_freq_temp = linspace(f0_sp,fe_sp,num_follower+2);
% f_jam_center_freq = f_jam_center_freq_temp(2:end-1);  % 干扰噪声的中心频率集合
% [Jam_Follower] = Jamming_Follower_func(Ts, fs, f_jam_center_freq, Bw_jam, Pjam);

toc