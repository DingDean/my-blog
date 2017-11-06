---
title: 'Numpy概览'
author: '丁科'
date: "2017-10-12T01:14:43.358Z"
tags: ["numpy", "python"]
---

## Numpy是什么

Numpy是用于python的矩阵计算库, 被用来创建矩阵和操作与矩阵相关的各种运算。Numpy非常之高效，是python科学计算栈Scipy Stack的基石。

Numpy的高效体现在两个层面:

一，计算速度的高效，因为绝大部分重要计算是通过预编译的C代码实现的。

二，代码编写的高效, 如下C的代码(有所简略)
``` c
for (i = 0; i < rows; i++): {
  for (j = 0; j < columns; j++): {
    c[i][j] = a[i][j]*b[i][j];
  }
}
```
用numpy编写可以缩略成
``` python
c = a * b
```

上面这行python代码反映出numpy计算的两大特点，那就是向量化(Vectorization)以及[泛化](https://docs.scipy.org/doc/numpy-dev/user/basics.broadcasting.html#module-numpy.doc.broadcasting). 在此先按下不表。

## 用Numpy创建Array:
1. np.array():

``` python
np.array([2,3,4])
np.array([2,3], [4,5])  # [[2,3], [4,5]]
np.array([1,2], [3,4], dtype=complex) # The type of the array can be explicitly specified at creation time
np.array([[1,2],[3,4],[5,6]]) # [[1,2], [3,4], [5,6]]
np.array([1,2], [3,4], [5,6]) # WRONG!! 行数超过二行的矩阵要以完整的矩阵出现，如上
```
2. np.zeros(), np.ones(), np.empty():

``` python
np.zeros((2,2)) # [[0, 0], [0, 0]]
np.ones((2,2), dtype=np.int16) # [[1, 1], [1, 1]] can define dtype
np.empty((2,2)) # [[0.2, 3.8], [23, 90]] random
```
3. np.arange(), np.linspace():

``` python
np.arange(10, 30, 5) # [10, 30) with step 5 -> [10, 15, 20, 25]
np.arange(5) # [0, 5) with step 1 -> [0, 1, 2, 3, 4]
np.arange(0, 2, 0.3) # step can be floating number, but perfer using linspace
np.linespace(0, 2, 9) # 9 numbers from 0 to 2
```

## Numpy基础运算:
由于广播的特性，我们数学中常见的运算在numpy中会被运用到矩阵中的每一个元素。
``` python
a = np.array([20, 30, 40, 50])
b = np.arange(4) # [0, 1, 2, 3])
c = a -b # [20, 29, 38, 47]
b ** 2 # [0, 1, 4, 9]
a < 35 # [True, True, False, False]
```
要想做矩阵乘积，使用dot():
``` python
a = np.array([1, 1], [0, 1])
b = np.array([2, 0], [3, 4])
a * b # [[2, 0], [0, 4]]
a.dot(b) # [[5, 4], [3, 4]]
np.dot(a, b) # [[5, 4], [3, 4]]
```
sum, min, max:
``` python
a = np.array([1, 2], [3, 4])
a.sum() # 10
a.min() # 1
a.max() # 4
a.sum(axis=0) # 每列之和(沿着行一个一个往下走,axis=0) [4, 6]
a.sum(axis=1) # 每行之和(沿着列一个一个往右走,axis=1) [3, 6]
```
Index, Slicing and Iterating

* 一维

``` python
a = np.arange(6) # [0,1,2,3,4,5]
a[2] # 2
a[:2] # [0, 1]
a[:6:2] # [0, 2, 4]
a[:6:2] = 1 # [1,1,1,3,1,5]
a[::-1] # reverse a [5,1,3,1,1,1]
```

* 多维

``` python
a = np.array([[1, 2, 3], [3, 4, 5]])
a[0, :] # 第一行 [1, 2]
a[:, 1] # 第一列 [1, 3]
a[:, 0:2] # 第一到第二列 [[1,2], [3,4]]
a[0:2, :] # 第一到第二行
for row in a:
  print row # [1,2,3], [3,4,5]
for ele in a.flat:
  print ele # 1,2,3,3,4,5
```

## 修改Array的维度
1. A.ravel() 展开矩阵，C style

``` python
a = np.array([1,3], [2, 4])
a.ravel() # [1, 3, 2, 4]
```
2. A.reshape((x,y)) 返回一个指定大小的矩阵，原素从A中提取, C style. 与之相似的是A.resize((x,y)), 不同点在于此方法直接修改A, 而不是返回一个新矩阵

``` python
a = np.array([[1,2], [4,5], [7,8]])
a.reshape((2,3)) # [[1,2,4], [5,7,8]]
```
3. Transpose of Array

``` python
a = np.array([[1,2], [4,5], [7,8]])
a.T # [[1,4,7], [2,5,8]]
```

## 到底复制了没?
上文中的reshape以及resize，一个复制了矩阵，一个直接修改矩阵。类似这样一个方法到底有没有复制矩阵的问题经常给初学者造成困扰，在此有必要理清何时会导致复制的发生。

没有复制:
简单的赋值操作是不会产生复制的
``` python
a = np.arange(12)
b = a # b reference a
b.resize((2, 6))
a.shape # (2,6)
```

浅复制(View):
ndarray.view() 方法相当于产生了一个类C指针的对象。这个对象有独立的Meta信息，如shape等，但底层的数据是和原矩阵共享的。
``` python
a = np.zeros((3,4))
c = a.view()
c.shape = 2,6
a.shape # 不变，依旧为(3,4)
c[0,1] = 1
a[0,1] # 变为1
s = a[:, 1:3] # s是a的一个view
```

深复制copy():
``` python
a = np.empty((3,4))
b = a.copy()
b.base is a # False
b[0,0] = 1
a[0,0] == b[0,0] # False
```
## Numpy基础概览

* 创建矩阵:
  * arange, array, copy, empty, empty_like, eye, fromfile, fromfunctoin, identity, linspace, logspace, mgrid, ogrid, ones, one_like, r, zeros, zeros_like
* 转化:
  * ndarray.astype, atleast_1d, atleast_2d, atleast_3d, mat
* 操纵:
  * array_split, column_stack, concatenate, diagonal, dsplit, dstack, hsplit, hstack, ndarray.item, newaxis, ravel, repeat, reshape, resize, squeeze, swapaxes, take, transpose, vsplit, vstack
* Questions:
  * all, any, nonzero, where
* Ordering:
  * argmax, argmin, argsort, max, min, ptp, searchsorted, sort
* Operations:
  * choose, compress, cumprod, cumsum, inner, ndarray.fill, imag, prod, put, putmask, real, sum
* Basic Statistics:
  * cov, mean, std, var
* Basic Linear Algebra:
  * cross, dot, outer, linalg.svd, vdot
