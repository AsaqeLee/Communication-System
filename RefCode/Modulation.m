function [output, hMod] = Modulation(input, Mode, M, SamplesPerSymbol,Fs, freqSep)
% 输入参数：
% 2:Mode, 取值 1:FSK; 2:GMSK; 3:BPSK; 4:QPSK; 5:OQPSK; 6:16QAM; 7:64QAM;
% 输出参数：
hMod = [];
% 调制
switch Mode
    case 1
        %input = reshape(input, length(input)/log2(M));
        output = fskmod(input, M, freqSep,SamplesPerSymbol,Fs);
    case 2
        hMod = comm.GMSKModulator('BitInput', true, 'InitialPhaseOffset', pi/4,...
            'PulseLength',1,'SamplesPerSymbol',1);
        output=step(hMod, input);
    case 3  % BPSK
        output = pskmod(input, M);
        
    case 4  % QPSK
        input1 = reshape(input,1,length(input));
        input2 = reshape(input1,2,length(input1)/2);
        bit_input = input2(1,:)*2^1 + input2(2,:)*2^0;
        bit_input = reshape(bit_input,length(bit_input),1);
        output = pskmod(bit_input, M);
    case 5 % OQPSK
%         hMod = comm.OQPSKModulator( 'BitInput', true,...
%             'SamplesPerSymbol',SamplesPerSymbol); % OQPSK的SamplesPerSymbol只能为偶数，为什么？
%         output = hMod(input);
        input1 = reshape(input,1,length(input));
        input2 = reshape(input1,2,length(input1)/2);
        input3(1,:) = rectpulse(input2(1,:),2);
        input3(2,:) = rectpulse(input2(2,:),2);
        input3(2,:)  = [input3(2,1), input3(2,1:end-1)]; % 延迟
        dec_input = input3(1,:)*2^1 + input3(2,:)*2^0;
        dec_input = reshape(dec_input,length(dec_input),1);
        output = pskmod(dec_input, M);
    case 6 % 16QAM
        output = qammod(input,M, 'InputType','bit','UnitAveragePower', true);
    case 7 % 64QAM
        output = qammod(input,M, 'InputType','bit','UnitAveragePower', true);        
    otherwise
        error('无效输入');
end
end
