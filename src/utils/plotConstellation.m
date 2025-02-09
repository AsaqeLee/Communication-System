function plotConstellation(symbols, plotTitle)
% 绘制星座图
% 输入：
%   symbols: 复数符号
%   plotTitle: 图标题

scatter(real(symbols), imag(symbols), '.');
grid on;
title(plotTitle);
xlabel('实部');
ylabel('虚部');
axis([-2 2 -2 2]);

end 