function [modSymbols, symbolIndices] = modulateQPSK(bitStream)
% QPSK调制函数
% 输入：
%   bitStream: 输入比特流
% 输出：
%   modSymbols: QPSK调制后的符号
%   symbolIndices: 符号索引

% 确保比特数为偶数
if mod(length(bitStream), 2) ~= 0
    bitStream = [bitStream; 0];
end

% 将比特流重塑为2比特一组
bitMatrix = reshape(bitStream, 2, [])';

% 转换为符号索引
symbolIndices = bi2de(bitMatrix, 'left-msb');

% QPSK调制（使用格雷码映射）
modSymbols = pskmod(symbolIndices, 4, 0, 'gray');

end 