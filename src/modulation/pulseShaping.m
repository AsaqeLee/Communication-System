function [shapedSignal, filterDelay] = pulseShaping(symbols, samplesPerSymbol, span, rolloff)
% 脉冲成形函数
% 输入：
%   symbols: 输入符号
%   samplesPerSymbol: 每个符号的采样点数
%   span: 滤波器符号跨度
%   rolloff: 升余弦滤波器滚降系数
% 输出：
%   shapedSignal: 成形后的信号
%   filterDelay: 滤波器延时

% 上采样
symbolsUpsample = upsample(symbols, samplesPerSymbol);

% 设计升余弦滤波器
raisedCosine = rcosdesign(rolloff, span, samplesPerSymbol);
filterDelay = span * samplesPerSymbol / 2;  % 滤波器群延时

% 滤波
shapedSignal = filter(raisedCosine, 1, symbolsUpsample);

end 