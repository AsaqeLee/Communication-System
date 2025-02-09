function [jamSignal] = generateJamming(jamType, Ts, fs, Pj, varargin)
% 生成不同类型的干扰信号
% 输入参数：
%   jamType: 干扰类型 ('SingleTone', 'LinearFreq', 'Comb', 'Broadband')
%   Ts: 信号周期
%   fs: 采样频率
%   Pj: 干扰信号功率
%   varargin: 不同干扰类型的额外参数
% 输出参数：
%   jamSignal: 生成的干扰信号

switch jamType
    case 'SingleTone'
        if length(varargin) < 1
            error('SingleTone jamming requires center frequency parameter');
        end
        fc = varargin{1};
        jamSignal = singleToneJam(fc, Ts, fs, Pj);
        
    case 'LinearFreq'
        if length(varargin) < 2
            error('LinearFreq jamming requires start and end frequency parameters');
        end
        f_start = varargin{1};
        f_end = varargin{2};
        jamSignal = linearFreqJam(Ts, fs, Pj, f_start, f_end);
        
    case 'Comb'
        if length(varargin) < 2
            error('Comb jamming requires center frequency and bandwidth parameters');
        end
        f_center = varargin{1};
        Bw = varargin{2};
        jamSignal = combJam(Ts, fs, Pj, f_center, Bw);
        
    case 'Broadband'
        if length(varargin) < 2
            error('Broadband jamming requires frequency range parameters');
        end
        f0_sp = varargin{1};
        fe_sp = varargin{2};
        jamSignal = broadbandJam(Ts, fs, Pj, f0_sp, fe_sp);
        
    otherwise
        error('Unknown jamming type');
end

end 