---
layout: post
title: chipyard Customization
date: 2024-10-21 13:51 +0800
categories: [项目学习, 开源项目]
tags: []
img_path: /assets/img/pj/
---

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

我们先来看constellation的配置文档
