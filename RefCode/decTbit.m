function bit_dec=decTbit(dec_bit,n,m)
bit_dec=zeros(1,n*m);
time=1;
for i=1:1:n
tem=dec2bin(dec_bit(i),m);  %十进制转变成二进制（注：字符串结构）
bit_d(1+(time-1)*m:(1+(time-1)*m+3))=tem;
time=time+1;
end
for j=1:1:length(bit_d)
     bit_dec(j)=str2num(bit_d(j));
end