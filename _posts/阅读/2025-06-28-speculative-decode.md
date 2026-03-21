---
layout: post
title: speculative-decode
date: 2025-06-28 14:22 +0800
categories: [读书笔记, 资料检索]
tags: []
math: true
img_path: /assets/img/learn/
---


## 1. 整体结构

`samd_model.generate` ：
1. prefill，draft.update



## 2. 零散部件

### 1.1 SAM自动后缀机

[理解后缀自动机 SAM](https://www.bilibili.com/video/BV1ED4y1U7aU/?spm_id_from=333.337.search-card.all.click&vd_source=aaf91522adc6826d87c67900ed8b01d9)

1. 最多`2n-1个点` `3n-4 边` ，`endpos`代表字符串出现的不同位置
2. 后缀链接`link`：第一个断开的后缀，比如ababc  状态存在babc，不存在abc，那么link连向abc状态

![SAM]({{ page.img_path }}SAM.png){: width="400" height="auto" }



```

```python
#draft.update
sam_dyn.add_tokens(tokens_list)
sam_static.transfer_tokens(tokens_list)
tree_model.update
#后缀自动机(SAM)的构建算法，
##- 每个状态代表一组具有相同后缀集合的子串
##- link：指向当前状态所代表子串的最长真后缀对应的状态
initial：add "abca"
states[0]: length=0, link=-1, last = 0, max_length = 0
-> 添加'a'
states[0]: length=0, link=-1, next={a: 1}
states[1]: length=1, link=0, next={}
-> 添加'b'
states[0]: length=0, link=-1, next={a: 1, b: 2}
states[1]: length=1, link=0, next={b: 2}
states[2]: length=2, link=0, next={}
-> 添加'c'
-> 添加'a'
states[0]: length=0, next={'a':1, 'b':2, 'c':3}
states[1]: length=1, next={'b':2}, link=0
states[2]: length=2, next={'c':3}, link=0
states[3]: length=3, next={'a':4}, link=0
states[4]: length=4, link=1
```
