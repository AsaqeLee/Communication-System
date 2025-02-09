function [msg4] = rs_code(source_sg, numBits, m, n_rs, k_rs, gen_poly)
% 参数：
% source_sg:原序列
% numBits:码长
% K:gf(2^m)域
% k_rs:信息长度
source_sg = reshape(source_sg, 1, numBits);
msg1 = bitTdec(source_sg,numBits,m);   % 每m个比特转换成十进制
msg2 = (reshape(msg1,k_rs,length(msg1)/k_rs))'; % 将原信号每K个一组
msg = gf(msg2,m);                      % 信息序列转换到GF(2^m)中
code = rsenc(msg,n_rs,k_rs);
% 将编码后的序列准换成二进制
msg3 = gf2dec(code',m,gen_poly);
msg4 = decTbit(msg3,length(msg3),m); % 比特化
%发送
end




