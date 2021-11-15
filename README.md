## 本系列脚本旨在实现自动化搭建FFmpeg转码环境，以及转码性能测试对比

### 环境搭建脚本

* setup-cpu.sh： 基于 AWS EC2 C5/C6g (x86/Graviton2) 机型搭建 FFmpeg 转码环境
* setup-nvidia.sh: 基于 AWS EC2 G4dn 机型搭建 FFmpeg 转码环境
* setup-xilinx.sh: 基于 AWS EC2 VT1 机型搭建 FFmpeg 转码环境

### 转码性能测试脚本

* 264to264_benchmark_cpu.sh: C5/C6g FFmpeg h.264 转码性能 Benchmark
* 264to264_benchmark_nvdia.sh: G4dn FFmpeg h.264 加速转码性能 Benchmark
* 264to264_benchmark_xilinx.sh: VT1 FFmpeg h.264 加速转码性能 Benchmark
* 265to265_benchmark_cpu.sh: C5/C6g FFmpeg h.265 转码性能 Benchmark
* 265to265_benchmark_nvida.sh: G4dn FFmpeg h.265 加速转码性能 Benchmark
* 265to265_benchmark_xilinx.sh: VT1 FFmpeg h.265 加速转码性能 Benchmark

### 测试内容生成

* benchmark_content_cpu.sh
* benchmark_content_nvdia.sh
* benchmark_content_xilinx.sh

### vmaf质量评估

* benchmark_vmaf.sh

### 1080p转码性能对比

![alt text](https://github.com/zhixueli/vt1benchmark/blob/main/result/HD.png?raw=true)

### 4K转码性能对比

![alt text](https://github.com/zhixueli/vt1benchmark/blob/main/result/4K.png?raw=true)

### 结论

对于1080p转码，V1.3xl 实例的性价比比 C5a.4xl 高 60.4%，比 C6g.4xl 实例的 H.264 编码性价比高 70.1%，比 G4dn 高 38.2% 的性价比