function [BER, numErrors] = calculateBER(txBits, rxBits)
% 计算误比特率
% 输入：
%   txBits: 发送的比特流
%   rxBits: 接收的比特流
% 输出：
%   BER: 误比特率
%   numErrors: 错误比特数

% 确保比较相同长度
validBits = min(length(txBits), length(rxBits));
txBits = txBits(1:validBits);
rxBits = rxBits(1:validBits);

% 计算错误比特数和误比特率
numErrors = sum(txBits ~= rxBits);
BER = numErrors / validBits;

end 