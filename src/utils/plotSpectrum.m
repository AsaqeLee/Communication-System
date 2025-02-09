function plotSpectrum(signal, Fs, plotTitle)
% 绘制信号频谱
% 输入：
%   signal: 输入信号
%   Fs: 采样频率
%   plotTitle: 图标题

% FFT参数
nfft = 2048;
f = (-nfft/2:nfft/2-1)*Fs/nfft/1e3;  % 频率轴（kHz）

% 计算频谱
Signal_fft = fftshift(fft(signal, nfft));
Signal_spectrum = 20*log10(abs(Signal_fft)/max(abs(Signal_fft)));

% 绘制频谱
plot(f, Signal_spectrum, 'LineWidth', 1.5);
grid on;
title(plotTitle);
xlabel('频率 (kHz)');
ylabel('幅度 (dB)');
ylim([-60 5]);

end 