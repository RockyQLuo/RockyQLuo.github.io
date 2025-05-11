
## 1. 容量和带宽
- 2023年：第三代SeDRAM，工艺节点25e（21nm）
	- 4层堆叠共24GB，32TB/s，最小Die size为100
- 2025年：尺寸800，工艺节点1y（≈长鑫16nm）
	- 预计4层堆叠共80GB，40TB/s左右，计划Size有50/100/200

## 2. 接口和功耗
* 接口协议：单bank-MC data为128bit@550MHz，4层堆叠共4096bank，能达到理论带宽的82%， active时间大约13.5ns
* 功耗：0.66 pJ/bit，单层DRAM功耗大约50W（我算的是44.5），四层200w不到（≈178W），logic和顶层DRAM温差1～2度

## 3.附加
* Dram Die不变，如果需要满带宽，堆叠层数/面积和带宽成线性，如果需要容量，可以通过固定带宽来增大容量（MC面积和带宽有关）

* 带高速IP接口的，推荐face2back

* 带有ECC（soft error）和repair（在memory controller中，上电扫一遍或者存在flash）