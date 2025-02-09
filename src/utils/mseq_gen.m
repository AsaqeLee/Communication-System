function [mseq] = mseq_gen(m)
% 生成m序列
% 输入参数：
%   m: m序列阶数（2 <= m <= 8）
% 输出参数：
%   mseq: 生成的m序列（0,1序列）

% 检查输入参数
if m < 2 || m > 8
    error('m序列阶数必须在2到8之间');
end

% 定义本原多项式（使用8阶及以下的本原多项式）
primitive_polynomials = {
    [2,1],             % m=2: x^2 + x + 1
    [3,1],             % m=3: x^3 + x + 1
    [4,1],             % m=4: x^4 + x + 1
    [5,2],             % m=5: x^5 + x^2 + 1
    [6,1],             % m=6: x^6 + x + 1
    [7,3],             % m=7: x^7 + x^3 + 1
    [8,4,3,2]          % m=8: x^8 + x^4 + x^3 + x^2 + 1
};

% 获取当前阶数的本原多项式
poly = primitive_polynomials{m-1};

% 计算序列长度
N = 2^m - 1;

% 初始化移位寄存器（除最后一位外都为0，最后一位为1）
register = zeros(1, m);
register(end) = 1;

% 生成m序列
mseq = zeros(1, N);
for i = 1:N
    % 保存输出位
    mseq(i) = register(end);
    
    % 计算反馈值
    feedback = 0;
    for j = 1:length(poly)
        feedback = xor(feedback, register(poly(j)));
    end
    
    % 移位
    register = [feedback register(1:end-1)];
end

% 确保输出为列向量
mseq = mseq(:);
end 