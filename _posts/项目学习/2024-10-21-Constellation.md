---
layout: post
title: Constellation
date: 2024-10-21 22:19 +0800
categories: [项目学习, 开源项目]
tags: []
img_path: /assets/img/pj/
---

[refrence — Constellation文档 ](https://constellation.readthedocs.io/en/latest/Configuration/Topologies.html#terminal-router-topologies)

NoC 的物理规格本身分为五个部分：topology、Channels、ingresses、egresses、routerParams

## 物理spec
### topology
`PhysicalTopology`是一个描述有向图的案例类，其中节点表示路由器，边表示单向通道。

```scala
trait PhysicalTopology {
  // Number of nodes in this physical topology
  val nNodes: Int

  /** Method that describes the particular topology represented by the concrete
    * class. Returns true if the two nodes SRC and DST can be connected via a
    * directed channel in this topology and false if they cannot.
    *
    *  @param src source point
    *  @param dst destination point
    */
  def topo(src: Int, dst: Int): Boolean //为1代表有向连接

  /** Plotter from TopologyPlotters.scala.
    * Helps construct diagram of a concrete topology. */
  val plotter: PhysicalTopologyPlotter
}
```
{: file='constellation/src/main/scala/topology/topologies.scala'}

- Terminal Router Topologies在原有路由基础上包装进一步拓扑,`TerminalRouter`拓扑必须与`TerminalRouting`路由关系包装器一起使用

![terminal_topology]({{ page.img_path }}terminal.png){: width="972" height="589" }<span id="terminal"></span>


- Hierarchical分层拓扑,`HierarchicalTopology`拓扑必须与`HierarchicalRouting`路由关系包装器一起使用

![Hierarchical]({{ page.img_path }}Hierarchical.png){: width="972" height="589" }<span id="Hierarchical"></span>

### Channels

PhysicalTopology指向的每条edge都会调用函数来确定通道参数

```scala
case class UserChannelParams(
  virtualChannelParams: Seq[UserVirtualChannelParams] =
    Seq(UserVirtualChannelParams()),
  channelGen: Parameters => ChannelOutwardNode => ChannelOutwardNode =
    p => u => u,
  crossingType: ClockCrossingType = NoCrossing,//Currently unsupported
  useOutputQueues: Boolean = true,
  srcSpeedup: Int = 1,
  destSpeedup: Int = 1
) {
  val nVirtualChannels = virtualChannelParams.size
}

case class UserVirtualChannelParams(
  bufferSize: Int = 1
)
```
{: file='constellation/src/main/scala/channel/parameters.scala'}

<font color="#d99694">virtualChannelParams</font>包含一个对象的列表，其中的每一个元素代表一个虚拟通道，并且该对象保存该虚拟通道的缓冲区条目数

<font color="#d99694">channelGen</font>仅用于指定在通道中添加额外的pipeline buffers

<font color="#d99694">srcSpeedup</font>表示一个周期内可能进入通道的flits数量。当`srcSpeedup` > 1 时，发生器将有效增加通道的输入带宽。

<font color="#d99694">destSpeedup</font>表示一个循环中可能退出通道的 flits 数量。增加这个压力会给目的路由器的路由资源和交换机带来压力。

### Terminals
 `UserIngressParams`和`UserEgressParams`案例类指定入口和出口终端的位置

还可以显示指定负载，Constellation 将自动生成宽度转换器以进一步分段或合并 flits。
```scala
ingresses = Seq(UserIngressParams(0), payloadBits=128)),
egresses  = Seq( UserEgressParams(1), payloadBits=128)),
routers   = (i) => UserRouterParams(payloadBits=64),

//可以指定其内部的payloadWidth，宽度需要是彼此的倍数
 routerParams = (i) => UserRouterParams(payloadWidth =
    if (i == 1 or i == 2) 128 else 64),
)
```

![payload]({{ page.img_path }}payload.png){: width="972" height="589" }

前提是终端有效负载宽度是路由器有效负载宽度的倍数或因子。谨慎使用有效负载宽度转换器。例如，<font color="#d99694">每片 64 位的 3 片数据包，如果放大为每片 128 位的 2 片数据包，则将被缩小为每片 64 位的 4 片数据包</font>

### Routers
`RouteComputer`对应RC阶段

`VirtualChannelAllocator`对应VA阶段

Flits 在SA阶段向`SwitchAllocator`请求访问路由器中的crossbar switch。该阶段还检查下一个虚拟通道是否有一个空的缓冲区槽来容纳该 flit。

A flit traverses（遍历） the crossbar switch in the ST stage.

流量控制是基于信用的，离开`InputUnit` flit 将信用向后发送到其源路由器上的`OutputUnit` 。

---

>终端 Ingress 和 Egress 点视为`InputUnits`和`OutputUnits`的特殊instances
{: .prompt-tip }

当启用`coupleSAVA`时，释放的虚拟通道将在同一周期立即可用。然而，<font color="#d99694"> `coupleSAVA`可以在高基数路由器上引入长组合路径</font>

![coupleSAVA]({{ page.img_path }}coupleSAVA.png){: width="972" height="589" }

[Virtual Channel Allocator请查阅](https://constellation.readthedocs.io/en/latest/Configuration/Routers.html)

- `PIMMultiVCAllocator`为可分离分配器实现并行迭代匹配

- `ISLIPMultiVCAllocator`实现可分离分配器的 ISLIP 策略

- `RotatingSingleVCAllocator`在传入请求之间轮换

- `PrioritizingSingleVCAllocator`根据路由关系给出的优先级，将某些 VC 优先于其他 VC


## Flows Specification

```scala
  // (blocker, blockee) => bool
  // If true, then blocker must be able to proceed when blockee is blocked
  vNetBlocking: (Int, Int) => Boolean = (_, _) => true,
  flows: Seq[FlowParams] = Nil,
```
{: file='constellation/src/main/scala/NOC/Parameters.scala'}

`NoCParams`的`flows`是`classes FlowParams`的一个列表，每个flowuniquely identifies its source ingress terminal, destination egress terminal, and the virtual subnetwork identifier.


Virtual subnetworks are used to delineate between different channels of a actual messaging protocol, and is necessary for avoiding protocol-deadlock.`vNetId`字段可用于指定flow的虚拟子网标识符

`vNetBlocking`功能指示哪些虚拟子网必须在某些其他虚拟子网被阻止时进行转发。如果`vNetBlocking(x, y) == true` ，则来自子网`x`的数据包必须继续转发，而子网`y`的数据包则停滞。


## Routing Configuration

```scala
abstract class RoutingRelation(topo: PhysicalTopology) {
  // Child classes must implement these
  def rel       (srcC: ChannelRoutingInfo,
                 nxtC: ChannelRoutingInfo,
                 flow: FlowRoutingInfo): Boolean

  def isEscape  (c: ChannelRoutingInfo,
                 vNetId: Int): Boolean = true

  def getNPrios (src: ChannelRoutingInfo): Int = 1

  def getPrio   (srcC: ChannelRoutingInfo,
                 nxtC: ChannelRoutingInfo,
                 flow: FlowRoutingInfo): Int = 0
```
{: file='constellation/src/main/scala/routing/RoutingRelations.scala'}

<font color="#d99694">ChannelRoutingInfo</font>唯一标识
```scala
case class ChannelRoutingInfo(
  src: Int,//channel的source physical node，如果这是入口通道，则该值为-1
  dst: Int,
  vc: Int,//virtual channel index within the channel
  n_vc: Int//该物理通道中可用的虚拟通道的数量
) {
```
{: file='constellation/src/main/scala/routing/Types.scala'}

> In the current implementations, packets arriving at the egress physical node are always directed to the egress. Thus, `ChannelRoutingInfo` for the egress channels are not used.到达出口物理节点的数据包总是被定向到出口，这种限制阻碍了偏转路由算法的实现
 {: .prompt-tip }

<font color="#d99694">Flow Identifier</font>唯一标识可能穿过 NoC 的potential flow, or packet

```scala
case class FlowRoutingInfo(
  ingressId: Int,//ingress index of the flow
  egressId: Int,
  vNetId: Int,//virtual subnetwork identifier of this flow
  ingressNode: Int,//the physical node of the ingress of this flow.
  ingressNodeId: Int,//物理节点上所有入口中入口的索引
  egressNode: Int,
  egressNodeId: Int,
  fifo: Boolean
) {
```
{: file='constellation/src/main/scala/routing/Types.scala'}

![flowrouting]({{ page.img_path }}flowrouting.png){: width="972" height="589" }

这里我没有怎么看懂他的例子

### 组合路由
在`constellation/src/main/scala/routing/RoutingRelations.scala`中有多种routing relations，为所包含的拓扑生成器提供无死锁路由，这里面有组合路由，可以这样用：

```scala
//a Mesh2DEscapeRouting algorithm with two escape channels using dimension-orderd routing
EscapeChannelRouting(
  escapeRouter    = Mesh2DDimensionOrderedRouting(),
  normalRouter    = Mesh2DMinimalRouting(),
  nEscapeChannels = 2
)
```
{: file='constellation/src/main/scala/routing/RoutingRelations.scala'}

### Terminal Router Routing

```scala
topolog = TerminalRouter(BidirectionalLine(4)) //Terminal Router Topologies
routing = TerminalRouterRouting(BidirectionalLineRouting())//`TerminalRouterRouting`路由关系
```
{: file='constellation/src/main/scala/routing/RoutingRelations.scala'}

![TerminalRouterRouting]({{ page.img_path }}TerminalRouterRouting.png){: width="972" height="589" }


[terminal的topo描述](#terminal)

### Hierarchical Topology Routing

![Hierarchicalrouting]({{ page.img_path }}Hierarchicalrouting.png){: width="972" height="589" }

[Hierarchical的topo描述](#Hierarchical)

虚拟子网路由关系--看不懂



## Protocol

### Abstract Protocol Interface

```scala
trait ProtocolParams {
  val minPayloadWidth: Int// flits 传输此协议所需的最小有效负载宽度
  val ingressNodes: Seq[Int]//所有入口终端的物理节点目的地的有序列表
  val egressNodes: Seq[Int]
  val nVirtualNetworks: Int//该协议中虚拟子网的数量，通常是协议通道的数量
  val vNetBlocking: (Int, Int) => Boolean//该协议中虚拟子网之间的阻塞/非阻塞关系
  val flows: Seq[FlowParams]// possible flows for the protocol
  def genIO()(implicit p: Parameters): Data//返回整个互连的协议级 IO
  def interface(
    terminals: NoCTerminalIO,//为NoC 提供接口
    ingressOffset: Int,
    egressOffset: Int,
    protocol: Data)(implicit p: Parameters)//为协议提供接口
}
```
{: file='constellation/src/main/scala/protocal/Protocol.scala'}

### Standalone Protocol NoC

```scala
case class ProtocolNoCParams(
  nocParams: NoCParams,//参数化network
  protocolParams: Seq[ProtocolParams]//参数化协议接口
)
class ProtocolNoC(params: ProtocolNoCParams)(implicit p: Parameters) extends Module {
  val io = IO(new Bundle {
    val ctrl = if (params.nocParams.hasCtrl) Vec(params.nocParams.topology.nNodes, new RouterCtrlBundle) else Nil
    val protocol = MixedVec(params.protocolParams.map { u => u.genIO() })
  })
```
{: file='constellation/src/main/scala/protocal/Protocol.scala'}

> 通过将多个`ProtocolParams`传递给`protocolParams`可以在共享互连上支持多个协议
{: .prompt-tip }

### AXI4

```scala
case class AXI4ProtocolParams(
  edgesIn: Seq[AXI4EdgeParameters],
  edgesOut: Seq[AXI4EdgeParameters],
  edgeInNodes: Seq[Int],
  edgeOutNodes: Seq[Int],
  awQueueDepth: Int
) extends ProtocolParams {
//AXI4EdgeParameters类的定义可以在 Rocketchip 中找到。
// edgesIn和edgesOut是向内和向外 AXI-4 边缘的有序列表（分别来自主设备和从设备）
// edgeInNodes和edgeOutNodes将主节点和从节点映射到物理节点索引
```
{: file='constellation/src/main/scala/protocal/AXI4.scala'}

### Diplomatic Protocol
没看懂。待定

NoC 集成的示例可以在 Chipyard 的`MultiNoCConfig`中的`NoCConfigs.scala`文件中找到

 Constellation 还支持无死锁的共享全局互连。追求这种集成风格的配置应该设置`GlobalNoCParams`字段 `constellation.soc.WithGlobalNoC` 。

全局共享 NoC 配置的一个示例是 Chipyard 中`NoCConfigs.scala`中的`SharedNoCConfig` 。
