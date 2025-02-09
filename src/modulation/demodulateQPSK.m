function [rxBitStream] = demodulateQPSK(rxSymbols)
% QPSK解调函数
% 输入：
%   rxSymbols: 接收的QPSK符号
% 输出：
%   rxBitStream: 解调后的比特流

% QPSK解调（使用格雷码映射）
demodSymbols = pskdemod(rxSymbols, 4, 0, 'gray');

% 转换为比特
rxBitsMatrix = de2bi(demodSymbols, 2, 'left-msb');
rxBitStream = reshape(rxBitsMatrix.', [], 1);

end 