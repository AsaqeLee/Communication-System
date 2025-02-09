# 通信系统仿真项目结构

## 目录结构
/Project_20
    /src                    # 源代码目录
        /modulation         # 调制解调相关函数
        /interference       # 干扰相关函数
        /utils             # 工具函数
    /systems               # 系统实现
        /basic             # 基础通信系统
        /anti_jamming      # 抗干扰通信系统
    /test                  # 测试脚本
        /jamming           # 干扰测试
        /systems           # 系统测试
    /docs                  # 文档
    README.md             # 项目说明

## 具体文件说明

1. 基础通信系统 (/systems/basic/)
   - Sys_Basic.m          # 基础通信系统（QPSK）
   - Sys_OFDM_Basic.m     # 基础OFDM系统
   - Sys_DSSS_Basic.m     # 基础DSSS系统
   - Sys_FHSS_Basic.m     # 基础FHSS系统

2. 抗干扰通信系统 (/systems/anti_jamming/)
   - Sys_OFDM.m          # 抗干扰OFDM系统
   - Sys_DSSS.m          # 抗干扰DSSS系统
   - Sys_FHSS.m          # 抗干扰FHSS系统

3. 干扰模块 (/src/interference/)
   - singleToneJam.m      # 单音干扰
   - linearFreqJam.m      # 线性调频干扰
   - combJam.m            # 梳状谱干扰
   - broadbandJam.m       # 宽带干扰
   - noiseModulatedJam.m  # 噪声调制干扰
   - multiToneJam.m       # 多音干扰
   - partialBandNoiseJam.m # 部分频带噪声干扰
   - sweepJam.m           # 扫频干扰
   - generateJamming.m    # 干扰生成主函数

4. 调制解调模块 (/src/modulation/)
   - modulateQPSK.m       # QPSK调制
   - demodulateQPSK.m     # QPSK解调
   - pulseShaping.m       # 脉冲成形

5. 工具函数 (/src/utils/)
   - calculateBER.m       # 误比特率计算
   - plotSpectrum.m       # 频谱绘制
   - plotConstellation.m  # 星座图绘制

6. 测试脚本 (/test/)
   /jamming
      - test_JammingTypes.m    # 干扰类型测试
   /systems
      - test_BasicSystems.m    # 基础系统测试
      - test_AntiJamming.m     # 抗干扰系统测试 