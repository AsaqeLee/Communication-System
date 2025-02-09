function [ y3 ] = dec_rs(bit_Demodulated, m, n_rs, k_rs, gen_poly)
% 参数说明
% bit_Demodulated:接收到信号
% m:gf(2^m)域
% n:编码后长度
bit_Demodulated = reshape(bit_Demodulated, 1, length(bit_Demodulated));
msg1_1 = bitTdec(bit_Demodulated,length(bit_Demodulated),m); % 每m个比特转换成十进制
msg2_2 = (reshape(msg1_1,n_rs,length(msg1_1)/n_rs))'; % 将信号每n个一组
msg_1 = gf(msg2_2,m);              % 信息序列转换到GF(2^m)中
decoded = rsdec(msg_1,n_rs,k_rs);
% 将编码后的序列转换成二进制
y2 = gf2dec(decoded',m,gen_poly);
y3 = decTbit(y2,length(y2),m); %比特化
end

