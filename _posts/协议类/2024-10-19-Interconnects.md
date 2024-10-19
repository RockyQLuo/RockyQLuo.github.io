---
layout: post
title: 《interconnect》
date: 2024-10-19 12:40 +0800
categories: [读书笔记, NOC]
tags: []
math: true
img_path: /assets/img/paper/
---

## Routing Mechanism
- Arithmetic Routing：例如每个节点根据其坐标来决定如何将数据包从源节点路由到目的节点。
- Source Based Routing：数据包的源节点在发送时确定数据包的每一跳要经过的输出端口，简化了交换机的设计（感觉每个包都要决定好自己怎么走，很鸡肋，也浪费带宽）
- 查表路由机制 (Table Lookup Based Routing)：每个节点根据数据包的目的地址在查表中找到对应的输出端口。

## Flow Control Methods
- bufferless参考[paper：A Case for Bufferless Routing in On-Chip Networks](https://rockyqluo.github.io/posts/A-Case-for-Bufferless-Routing-in-On-Chip-Networks/)
- Store and Forward：每一个路由需要收到完整的包才可以发送到下一个路由
- Cut-Through：收到了头及资源分配就可以发出去了（buffer和带宽还是full packets，数据包太大就会有问题，这时候见虫洞）
- wormhole（虫洞）：body 跟随头flit
> 存在一个问题：虫洞会受头部阻塞影响， 由于queue的先入先出，红色包必须要等待蓝色释放。可以用VC来解决这个问题
{: .prompt-warning }
![head_blocking issue]({{ page.img_path }}head_blocking.png){: width="972" height="589" }
![VC]({{ page.img_path }}VC.png){: width="972" height="589" }

## 防止死锁
- 协议级：防止由于不同的包的混合而产生循环，例如把数据和地址的包分开始用不同的VC传输
剩余的可以参见[《NOC学习记录》](https://rockyqluo.github.io/posts/noc/)

## 上下级buffer可用性的信息传递（communicating buffer availability）
Round trip delay：buffer清空到下一个flit可以被处理的时间间隔
![credit]({{ page.img_path }}credit.png){: width="972" height="589" }


ideal 的latency有一个计算公式：$T_{ideal}=\frac{D}{v}+\frac{L}{b}$
和曼哈顿距离(D)，传播速度(v)，包大小(L)以及带宽(b)有关，实际还要考虑一些contention

![latence_inject]({{ page.img_path }}latence_inject.png){: width="972" height="589" }

两种cache coherence的methods：
* Snoopy Bus
* Directory

