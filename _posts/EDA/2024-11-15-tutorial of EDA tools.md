---
layout: post
title: EDA tools
date: 2024-11-15 20:34 +0800
categories: [tools, EDA工具]
tags: []
img_path: /assets/img/learn/
---

## vivado
[AXI VIP的简单使用](https://icode.best/i/36088746158033)






## Verdi

- 要查看二维数组的值，需要在Makefile及仿真的tb中添加
[使用VCS观察Verilog二维数组仿真值的方法](https://zhuanlan.zhihu.com/p/119326286)

```sh
“+v2k（VCS和Verdi中都要加），一个case如下”：
make:clean com sim 
all:clean com sim verdi 
com: 
	vcs -full64 -sverilog -debug_acc+all -timescale=1ns/10ps -f file.list -l coml.log -fsdb +define+FSDB +vc +v2k 
sim: 
	./simv -l sim.log 
verdi: 
	verdi -f file.list -ssf sim.fsdb -nologo +v2k & 
clean: 
	rm -rf crsc *.log *.key *simv* *.vpd *DVE* rm -rf verdilog *.fsdb *.conf

“tb中需要有”： 
initial begin 
$fsdbDumpfile("sim.fsdb"); 
$fsdbDumpvars; 
$fsdbDumpMDA(); //这个要放在最后 
#10000 $finish; 
end
```

- 添加Mark  

你可以shift+m,出现添加mark的窗口，输入mark的名称和时间点，close即可。