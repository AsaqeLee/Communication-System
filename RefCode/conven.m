function [code, trel, tblen] = conven(source, puncpat, m)
% 函数说明：
% 输入：
% source：原序列，msg数据的长度要是k的整数倍
% rate：码率
% m：约束长度 取值范围（2、4、8）
if (m == 2)
    g = [7 5];
    L = 3;
elseif(m == 4)
    g = [23 35];
    L = 5;
elseif(m == 8)
    g = [561 753];
    L = 9;
end

trel = poly2trellis(L,g); % 卷积码生成多项式
tblen = 6*L;         % 回溯深度
code = convenc(source,trel,puncpat); % 编码
end