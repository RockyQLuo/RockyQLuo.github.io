---
layout: post
title: chipyard Customization
date: 2024-10-21 13:51 +0800
categories: [项目学习, 开源项目]
tags: []
img_path: /assets/img/pj/
---

## 3.1 Rocket Chip
典型 Rocket Chip 系统的详细框图如下所示。

![rocketchip]({{ page.img_path }}rocketchip.png){: width="972" height="589" }

### PTW：page-table walker
使用虚拟地址，就涉及到将虚拟地址转换为物理地址的过程，这需要MMU（Memory Management Unit）和页表（page table）的共同参与。page table是每个进程独有的，是软件实现的，是存储在main memory（比如DDR）中的。

<font color="#d99694">MMU是processer中的一个硬件单元</font>，通常每个核有一个MMU。<font color="#d99694">MMU由两部分组成：TLB(Translation Lookaside Buffer)和table walk unit</font>

为page table设计了一个缓存**TLB**，CPU会首先在TLB中查找。TLB之所以快，一是因为它含有的entries的数目较少，二是TLB是集成进CPU的，它几乎可以按照CPU的速度运行。

TLB miss之后需要查当前进程对应的page table的时候，需要用到组成MMU的另一个部分table walk unit。在CISC和RISC中有不同的处理策略，通过CPU控制或者交给操作系统来处理

---
### 介绍一下 page table

>CPU 中需要有一些寄存器用来存放表单在物理内存中的地址，SATP 寄存器会保存这个地址关系表单，这样，CPU 就可以告诉 MMU，可以从哪找到将虚拟内存地址翻译成物理内存地址的表单。当操作系统将 CPU 从一个应用程序切换到另一个应用程序时，内核会写 SATP 寄存器中的内容。所以，用户应用程序不能通过更新这个寄存器来更换一个地址对应表单，否则的话就会破坏隔离性。所以，只有运行在 kernel mode 的代码可以更新这个寄存器。
{: .prompt-tip}

现在，内存地址的翻译方式略微的不同了。首先对于虚拟内存地址，我们将它划分为两个部分，index 和 offset，index 用来查找 page，offset 对应的是一个 page 中的哪个字节。将 offset 加上 page 的起始地址，就可以得到物理内存地址

>一个page table一般是4KB，在物理内存中连续存在，物理内存是以 4096 为粒度使用的。所以 offset 才是 12bit，这样就足够覆盖 4096 个字节。
>每个物理 page 的 PPN 是 44bit， 12bit 直接从虚拟地址的 12bit offset 继承就可以了
>
>在某些使用的 RSIC-V 处理器上，并不是所有的 64bit 都被使用了，也就是说高 25bit 并没有被使用。这样的结果是限制了虚拟内存地址的数量，虚拟内存地址的数量现在只有 2^39 个（27bit index 12bit offset），大概是 512GB。当然，如果必要的话，最新的处理器或许可以支持更大的地址空间，只需要将未使用的 25bit 拿出来做为虚拟内存地址的一部分即可。在 RISC-V 中，物理内存地址是 56bit（这是由硬件设计人员决定的，预测物理内存在 5 年内不可能超过 2^56 这么大）。所以物理内存可以大于单个虚拟内存地址空间，但是也最多到 2^56。**这样我们可以有多个进程都用光了他们的虚拟内存，但是物理内存还有剩余。**
{: .prompt-tip}

但是这样每个 page table 最多会有 2^27 个条目，进程需要为 page table 消耗大量的内存，并且很快物理内存就会耗尽，实际中，page table 是一个多级的结构。我们之前提到的虚拟内存地址中的 27bit 的 index，实际上是由 3 个 9bit 的数字组成<font color="#d99694">（L2，L1，L0）</font>

定义一个page directory为4KB，Directory 中的一个条目被称为 PTE（Page Table Entry）是 64bits，就像寄存器的大小一样，也就是 8Bytes。所以一个 Directory page 有 512 个条目。

所以实际上，SATP 寄存器会指向最高一级的 page directory 的物理内存地址，之后我们用虚拟内存中 index 的高 9bit 用来索引最高一级的 page directory，这样我们就能得到一个 PPN，也就是物理 page 号。这个 PPN 指向了中间级的 page directory。

当我们在使用中间级的 page directory 时，我们通过虚拟内存地址中的 L1 部分完成索引。接下来会走到最低级的 page directory，我们通过虚拟内存地址中的 L0 部分完成索引。在最低级的 page directory 中，我们可以得到对应于虚拟内存地址的物理内存地址。

> 实际的索引是由 3 步，优点是节省了巨大的条目空间。举个例子，如果你的地址空间只使用了一个 page，4096Bytes。除此之外，你没有使用任何其他的地址，在最高级，你需要一个 page directory。在这个 page directory 中，你需要一个数字是 0 的 PTE，指向中间级 page directory。所以在中间级，你也需要一个 page directory，里面也是一个数字 0 的 PTE，指向最低级 page directory。所以这里总共需要 3 个 page directory（也就是 3 * 512 个条目）。
{: .prompt-info}





## 6.1 定义core

```scala
class DualLargeBoomAndSingleRocketConfig extends Config(
  new boom.v3.common.WithNLargeBooms(2) ++             // add 2 boom cores
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++  // add 1 rocket core(first ID)
  new chipyard.config.WithSystemBusWidth(128) ++
  new chipyard.config.AbstractConfig)
```
{: file='chipyard/src/main/scala/config/HeteroConfigs.scala'}

## 6.2 SoCs with NoC-based Interconnects
将片上网络集成到 Chipyard SoC 的主要方法是将标准 TileLink 基于交叉开关的总线之一（系统总线、内存总线、控制总线等）映射到 Constellation 生成的 NoC。

### 6.2.1 Private Interconnects
私有NoC的参数化，以及TileLink代理和物理NoC节点之间的映射

```scala
class MultiNoCConfig extends Config(
  new constellation.soc.WithCbusNoC(constellation.protocol.SimpleTLNoCParams(
    constellation.protocol.DiplomaticNetworkNodeMapping(
      inNodeMapping = ListMap(
        "serial_tl" -> 0),
      outNodeMapping = ListMap(
        "error" -> 1, "ctrls[0]" -> 2, "pbus" -> 3, "plic" -> 4,
        "clint" -> 5, "dmInner" -> 6, "bootrom" -> 7, "clock" -> 8)),
    NoCParams(
      topology = TerminalRouter(BidirectionalLine(9)),
      channelParamGen = (a, b) => UserChannelParams(Seq.fill(5) { UserVirtualChannelParams(4) }),//5个VC，bufferSize为4
      routingRelation = NonblockingVirtualSubnetworksRouting(TerminalRouterRouting(BidirectionalLineRouting()), 5, 1))//Virtual Network=5，为每个虚拟网络专用的虚拟通道数量为1
  )) ++
  new constellation.soc.WithMbusNoC(constellation.protocol.SimpleTLNoCParams(
    constellation.protocol.DiplomaticNetworkNodeMapping(
      inNodeMapping = ListMap(
        "L2 InclusiveCache[0]" -> 1, "L2 InclusiveCache[1]" -> 2,
        "L2 InclusiveCache[2]" -> 5, "L2 InclusiveCache[3]" -> 6),
      outNodeMapping = ListMap(
        "system[0]" -> 0, "system[1]" -> 3,  "system[2]" -> 4 , "system[3]" -> 7,
        "ram[0]" -> 0)),
    NoCParams(
      topology        = TerminalRouter(BidirectionalTorus1D(8)),
      channelParamGen = (a, b) => UserChannelParams(Seq.fill(10) { UserVirtualChannelParams(4) }),
      routingRelation = BlockingVirtualSubnetworksRouting(TerminalRouterRouting(BidirectionalTorus1DShortestRouting()), 5, 2))
  )) ++
  new constellation.soc.WithSbusNoC(constellation.protocol.SimpleTLNoCParams(
    constellation.protocol.DiplomaticNetworkNodeMapping(
      inNodeMapping = ListMap(
        "Core 0" -> 1, "Core 1" -> 2,  "Core 2" -> 4 , "Core 3" -> 7,
        "Core 4" -> 8, "Core 5" -> 11, "Core 6" -> 13, "Core 7" -> 14,
        "serial_tl" -> 0),
      outNodeMapping = ListMap(
        "system[0]" -> 5, "system[1]" -> 6, "system[2]" -> 9, "system[3]" -> 10,
        "pbus" -> 3)),
    NoCParams(
      topology        = TerminalRouter(Mesh2D(4, 4)),
      channelParamGen = (a, b) => UserChannelParams(Seq.fill(8) { UserVirtualChannelParams(4) }),
      routingRelation = BlockingVirtualSubnetworksRouting(TerminalRouterRouting(Mesh2DEscapeRouting()), 5, 1))
  )) ++
  new freechips.rocketchip.rocket.WithNHugeCores(8) ++
  new freechips.rocketchip.subsystem.WithNBanks(4) ++
  new freechips.rocketchip.subsystem.WithNMemoryChannels(4) ++
  new chipyard.config.AbstractConfig
)
```
{: file='generators/chipyard/src/main/scala/config/NoCConfigs.scala.'}

###  6.2.2 Shared Global Interconnect
配置片段仅提供 TileLink 代理和物理 NoC 节点之间的映射，while a separate fragement provides the configuration for the global interconnect.