function [jamSignal] = combJam(Ts, fs, Pj, f_center, Bw)
% 生成梳状谱干扰信号
% 输入参数：
%   Ts: 信号周期
%   fs: 采样频率
%   Pj: 干扰信号功率
%   f_center: 中心频率
%   Bw: 频率间隔的一半
% 输出参数：
%   jamSignal: 生成的干扰信号

% 参数设置
N = 10;                % 梳状谱的谐波数量（总共2N+1个谐波）
filter_order = 64;     % 滤波器阶数
noise_bw = Bw/10;     % 每个频点的噪声带宽（远小于频点间隔）

% 生成时间向量
dt = 1/fs;
t = 0:dt:(Ts-dt);

% 设计低通滤波器（用于限制基带噪声带宽）
cutoff_freq = noise_bw/(fs/2);
b = fir1(filter_order, cutoff_freq, 'low');

% 初始化干扰信号
jamSignal = zeros(1, length(t));

% 生成每个频点的干扰分量
for i = -N:N
    % 计算当前频点
    fi = f_center + i*2*Bw;
    
    % 确保频率在奈奎斯特频率范围内
    if abs(fi) < fs/2
        % 生成复高斯白噪声
        noise_i = randn(1,length(t)) + 1j*randn(1,length(t));
        
        % 滤波限制噪声带宽
        noise_filtered = filter(b, 1, noise_i);
        
        % 生成随机初始相位
        phi = 2*pi*rand();
        
        % 将带限噪声调制到对应频点
        jamSignal = jamSignal + noise_filtered.*exp(1j*(2*pi*fi*t + phi));
    end
end

% 取实部
jamSignal = real(jamSignal);

% 功率归一化
var_temp = var(jamSignal);
jamSignal = sqrt(Pj)*jamSignal/sqrt(var_temp);

% 确保输出为列向量
jamSignal = jamSignal(:);

end 