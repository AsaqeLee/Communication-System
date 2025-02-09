function dec_bit=bitTdec(bit_source,N,m) %参数依次为（源信号，数据长度，每个符号的比特数）
time = 1; %记录循环次数
dec_bit = zeros(1,N/m); 
for i = 1:m:N
      tem = num2str(bit_source(i:i+m-1));
      dec_bit(time) = bin2dec(tem);
      time = time+1;
end