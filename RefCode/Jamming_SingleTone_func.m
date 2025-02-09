function [Uc_danyin] = Jamming_SingleTone_func(fc_jam, Ts, fs, Pj)
% 生成单音干扰信号
% 输入参数：
% 1.fc_jam：干扰信号中心频率
% 2.Ts: 码元周期
% 3.fs：采样频率
% 4.Pj：干扰信号功率,单位：W

dt = 1/fs;    % 时刻精度
tt = 0:dt:(Ts - dt);

Uc_danyin = cos(2*pi*fc_jam*tt);     %载波信号
norm = mean(abs(Uc_danyin).^2);
Uc_danyin = sqrt(Pj/norm)*Uc_danyin;

% figure
% subplot(2,1,1);
% plot(tt,Uc_danyin);
% title('单音干扰信号波形');
% xlabel('时间(s)');ylabel('幅度(V)');title('单音干扰信号波形');
% %xlim([0 160*(1/fs)]);%axis([0,160*(1/fs),-1.5,1.5]);%;axis([0 0.009 -1 1]);
% 
% subplot(2,1,2);
% periodogram(Uc_danyin,[ ],length(Uc_danyin),fs,'onesided');
% title('单音干扰信号功率谱');

end

