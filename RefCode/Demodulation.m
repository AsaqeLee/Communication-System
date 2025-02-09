function [output, hDemod] = Demodulation(input, Mode,M, SamplesPerSymbol, Fs, freqSep)
% 输入参数：
% 2:Mode, 取值 1:FSK; 2:GMSK; 3:BPSK; 4:QPSK; 5:OQPSK; 6:16QAM; 7:64QAM;
% 输出参数：

% 解调
hDemod = [];
switch Mode
    case 1 % FSK      
        output = fskdemod(input,M,freqSep,SamplesPerSymbol,Fs);
    case 2 % GMSK
        hDemod = comm.GMSKDemodulator('BitOutput', true, ...
            'InitialPhaseOffset', pi/4,...
            'PulseLength',1,...
            'SamplesPerSymbol',1);
        output = step(hDemod, input);
    case 3 % BPSK
        output = pskdemod(input,M);
    case 4 % QPSK
        output_dec = pskdemod(input,M);
        output_bit_char = dec2bin(output_dec);
        if size(output_bit_char,2)==1
            output_bit_temp(:,1) = str2num(output_bit_char(:,1));
            output_bit_temp(:,2) = str2num(output_bit_char(:,1)); 
        else
            output_bit_temp(:,1) = str2num(output_bit_char(:,1));
            output_bit_temp(:,2) = str2num(output_bit_char(:,2)); 
        end                    
        output(1:2:length(output_dec)*2-1,1) = output_bit_temp(:,1);
        output(2:2:length(output_dec)*2,1) = output_bit_temp(:,2);                
    case 5 % OQPSK
%         hDemod = comm.OQPSKDemodulator('BitOutput',true,...
%             'SamplesPerSymbol',SamplesPerSymbol);
%         output = hDemod(input);
        output_dec = pskdemod(input,M);
        output_bit_char = dec2bin(output_dec);
        output_bit_temp(:,1) = str2num(output_bit_char(:,1));
        output_bit_temp(:,2) = str2num(output_bit_char(:,2));
        output_bit_dd(:,1) = output_bit_temp(1:2:end-1,1);
        output_bit_dd(:,2) = output_bit_temp(2:2:end,2);
        output(1:2:length(output_bit_dd)*2-1,1) = output_bit_dd(:,1);
        output(2:2:length(output_bit_dd)*2,1) = output_bit_dd(:,2);
    case 6 % 16QAM
        output = qamdemod(input, M, 'OutputType', 'bit', 'UnitAveragePower', true);
    case 7 % 64QAM
        output = qamdemod(input, M, 'OutputType', 'bit', 'UnitAveragePower', true);
    otherwise
        error('无效输入');
end
end