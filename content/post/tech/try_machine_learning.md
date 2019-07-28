---
title: "[学无止境]之机器学习"
date: 2018-03-21T16:53:53+08:00
lastmod: 2018-03-22T16:53:53+08:00
draft: true
keywords: ["NodeJS", "源码探秘", "启动流程"]
description: "NodeJS是时下非常流行的服务器语言, 这个系列将着重研究NodeJS的源码，以期为之做出贡献。这篇文章将详细记录和解释NodeJS启动的全流程。"
tags: ["NodeJS", "C++", "V8", "libuv", "NodeJS源码探秘"]
categories: ["技术"]
author: "丁科"
# you can close something for this content if you open it in config.toml.
# comment: false
# toc: false
# you can define another contentCopyright. e.g. contentCopyright: "This is an another copyright."
# contentCopyright: false
# reward: false
# mathjax: false
---

# Contents
    - [Machine Learning Nanodegree Udacity](#Machine Learning Nanodegree Udacity.md)
        - [模型评估与验证 Model Analysis and Validation](#Machine Learning Nanodegree Udacity#模型评估与验证 Model Analysis and Validation.md)
            - [分类指标](#Machine Learning Nanodegree Udacity#模型评估与验证 Model Analysis and Validation#分类指标.md)
                - [混淆矩阵 Confusion Matrix](#Machine Learning Nanodegree Udacity#模型评估与验证 Model Analysis and Validation#分类指标#混淆矩阵 Confusion Matrix.md)
                - [精准率和召回率 Recall and Precision](#Machine Learning Nanodegree Udacity#模型评估与验证 Model Analysis and Validation#分类指标#精准率和召回率 Recall and Precision.md)
                - [F1 分数](#Machine Learning Nanodegree Udacity#模型评估与验证 Model Analysis and Validation#分类指标#F1 分数.md)
            - [回归指标](#Machine Learning Nanodegree Udacity#模型评估与验证 Model Analysis and Validation#回归指标.md)
                - [平均绝对误差](#Machine Learning Nanodegree Udacity#模型评估与验证 Model Analysis and Validation#回归指标#平均绝对误差.md)
                - [R2分数](#Machine Learning Nanodegree Udacity#模型评估与验证 Model Analysis and Validation#回归指标#R2分数.md)
                - [可释方差分数](#Machine Learning Nanodegree Udacity#模型评估与验证 Model Analysis and Validation#回归指标#可释方差分数.md)
            - [误差](#Machine Learning Nanodegree Udacity#模型评估与验证 Model Analysis and Validation#误差.md)
                - [偏差造成的误差](#Machine Learning Nanodegree Udacity#模型评估与验证 Model Analysis and Validation#误差#偏差造成的误差.md)
                - [方差造成的误差](#Machine Learning Nanodegree Udacity#模型评估与验证 Model Analysis and Validation#误差#方差造成的误差.md)
                - [改进模型的有效性](#Machine Learning Nanodegree Udacity#模型评估与验证 Model Analysis and Validation#误差#改进模型的有效性.md)
            - [数据与建模的本质](#Machine Learning Nanodegree Udacity#模型评估与验证 Model Analysis and Validation#数据与建模的本质.md)
                - [数据类型](#Machine Learning Nanodegree Udacity#模型评估与验证 Model Analysis and Validation#数据与建模的本质#数据类型.md)
            - [交叉验证 Cross Validation](#Machine Learning Nanodegree Udacity#模型评估与验证 Model Analysis and Validation#交叉验证 Cross Validation.md)
            - [纬度灾难 Curse of Dimensionality](#Machine Learning Nanodegree Udacity#模型评估与验证 Model Analysis and Validation#纬度灾难 Curse of Dimensionality.md)
        - [监督学习 Supervised Learning](#Machine Learning Nanodegree Udacity#监督学习 Supervised Learning.md)
            - [分类与回归 Classification and Regression](#Machine Learning Nanodegree Udacity#监督学习 Supervised Learning#分类与回归 Classification and Regression.md)
            - [人工神经网络 Artificial Neural Network](#Machine Learning Nanodegree Udacity#监督学习 Supervised Learning#人工神经网络 Artificial Neural Network.md)
                - [感知器 Perceptron](#Machine Learning Nanodegree Udacity#监督学习 Supervised Learning#人工神经网络 Artificial Neural Network#感知器 Perceptron.md)
            - [支持向量机 Supporting Vector Machine](#Machine Learning Nanodegree Udacity#监督学习 Supervised Learning#支持向量机 Supporting Vector Machine.md)
                - [实用链接 Useful Links](#Machine Learning Nanodegree Udacity#监督学习 Supervised Learning#支持向量机 Supporting Vector Machine#实用链接 Useful Links.md)
                - [梗要 Abstract](#Machine Learning Nanodegree Udacity#监督学习 Supervised Learning#支持向量机 Supporting Vector Machine#梗要 Abstract.md)
                - [定义 Definition](#Machine Learning Nanodegree Udacity#监督学习 Supervised Learning#支持向量机 Supporting Vector Machine#定义 Definition.md)
                - [Parameters in SVM](#Machine Learning Nanodegree Udacity#监督学习 Supervised Learning#支持向量机 Supporting Vector Machine#Parameters in SVM.md)
            - [基于实例的学习 Instance Based Learning](#Machine Learning Nanodegree Udacity#监督学习 Supervised Learning#基于实例的学习 Instance Based Learning.md)
                - [定义 Definition](#Machine Learning Nanodegree Udacity#监督学习 Supervised Learning#基于实例的学习 Instance Based Learning#定义 Definition.md)
            - [贝叶斯 Bayes](#Machine Learning Nanodegree Udacity#监督学习 Supervised Learning#贝叶斯 Bayes.md)
                - [定义 Definition](#Machine Learning Nanodegree Udacity#监督学习 Supervised Learning#贝叶斯 Bayes#定义 Definition.md)
                - [贝叶斯规则 Bayes Rule](#Machine Learning Nanodegree Udacity#监督学习 Supervised Learning#贝叶斯 Bayes#贝叶斯规则 Bayes Rule.md)
                - [使用贝叶斯规则 Thought Process when using Bayes Rule](#Machine Learning Nanodegree Udacity#监督学习 Supervised Learning#贝叶斯 Bayes#使用贝叶斯规则 Thought Process when using Bayes Rule.md)
                - [贝叶斯学习](#Machine Learning Nanodegree Udacity#监督学习 Supervised Learning#贝叶斯 Bayes#贝叶斯学习.md)
                    - [计算最大似然](#Machine Learning Nanodegree Udacity#监督学习 Supervised Learning#贝叶斯 Bayes#贝叶斯学习#计算最大似然.md)
                    - [挑选最佳假设](#Machine Learning Nanodegree Udacity#监督学习 Supervised Learning#贝叶斯 Bayes#贝叶斯学习#挑选最佳假设.md)
                - [贝叶斯最佳分类器](#Machine Learning Nanodegree Udacity#监督学习 Supervised Learning#贝叶斯 Bayes#贝叶斯最佳分类器.md)
                - [朴素贝叶斯](#Machine Learning Nanodegree Udacity#监督学习 Supervised Learning#贝叶斯 Bayes#朴素贝叶斯.md)

# Machine Learning Nanodegree Udacity
## 模型评估与验证 Model Analysis and Validation

### 分类指标

#### 混淆矩阵 Confusion Matrix
True Positive TP ::
False Positive FP ::
True Negative TN ::
False Negative FN ::

#### 精准率和召回率 Recall and Precision
精准率 Precision P ::
A measure of result relevancy. Precision (P) is defined as the number of true positives over the number of true positives plus the number of false positives:
{{$
P = \frac{T_p}{T_p+F_p}
}}$
精准率是针对我们的这一次
所谓的精准率，就是我们对于一个目标做的真判断中，值得依靠(即符合真实情况)的比例。

召回率 Recall R :: 
我对召回率的这个翻译有疑问
A measure of how many truly relevant results are returned. Recall (R) is defined as the number of true positives over the number of true positives plus the number of false negatives.
{{$
R = \frac{T_p}{T_p + F_n}
}}$
召回率，则是对于一个目标所对应的所有实际真判断中，我们对同一目标的真判断所占的比例。

#### F1 分数
F1 分数 ::
{{$
F1 = 2*\frac{P * R}{P + R}
}}$
### 回归指标

#### 平均绝对误差
#### R2分数
#### 可释方差分数
### 误差
在模型预测中，误差主要来自两个来源：
* 模型无法表示基本数据的复杂度而造成的偏差(Bias)
* 模型对训练它所用的有限数据过度敏感而造成的方差(Variance)
### 偏差造成的误差
欠拟合 :: 

#### 方差造成的误差

方差用来测量预测结果对于任何给定的测试样本会出现多大的变化
过度拟合 ::

#### 改进模型的有效性
### 数据与建模的本质

##### 数据类型
* 数值数据 Numeric Data
* 分类数据 Categorical Data
* 时间序列数据 Time-Series Data

### 交叉验证 Cross Validation
Problems with splitting into trianing and test set, we have problem of proportion of test and trainig set.

K-fold Cross Validation, we split data set into K folds with equal cardinality. We pick on fold as test set and others as training set. We do this to every fold.
===纬度灾难 Curse of Dimensionality===
As the number of features or dimensions grows the amount of data we need to generarize grows exponentially.

==监督学习 Supervised Learning==
什么是监督学习？
监督学习的目的，方法，有效性，实用性，缺点

监督学习首先是用来帮助作出判断的。什么判断呢？比如什么样的西瓜是好瓜，或明天下雨的概率是多少？我们希望机器学习得到的工具可以帮助我们又快又好的回答上述问题。我们人类在回答
上述问题时，会先结合我们记忆中对问题的经验做出判断。比如，我们会想起以前买西瓜的时候，根蒂葱绿的西瓜会是好瓜，然后在看到当前的西瓜根蒂也是葱绿的，我们会认为这个西瓜会是好瓜。
监督学习模拟的就是上述的思考过程。首先，我们搜集到一个数据集
===分类与回归 Classification and Regression===
分类和回归是什么？两者有什么联系？

机器学习所要回答的问题在于如何根据已有数据，预测未来的数据
===人工神经网络 Artificial Neural Network===
====感知器 Perceptron====
===支持向量机 Supporting Vector Machine===
====实用链接 Useful Links====
[www.svms.org]( http://www.svms.org )
====梗要 Abstract====
支持向量机要解决什么问题？
是如何解决的？
为什么要采用支持向量机?优缺点？适用范围？难易度?
====定义 Definition====
间隔 Margin :: 两个异类支持向量到超平面的距离之和 The distance between the line and the nearest data point 
超平面 Hyperplane :: 
核函数 Kernel Function :: helps you find additional feautre to describe and classify datas
拉格朗日乘子法 :: 
凸二次规划 Convex Quadratic Programming :: 
SMO Sequential Minimal Optimization :: 
Mercer Condition :: 
====Parameters in SVM====
* Kernel
* C :: C 越大，支持向量机划分得更准确 controls tradeoff between smooth decison boundary and classifying training points correctly
* Gamma
===基于实例的学习 Instance Based Learning===
====定义 Definition====
KNN ::
===贝叶斯 Bayes===
====定义 Definition====
贝叶斯规则 Bayes Rule :: 
    Learn the best hypothesis given data and some domain knowledge
    {{$
    Pr(h|D) = \frac{Pr(D|h)Pr(h)}{Pr(D)}
    }}$
    
先验概率 Prior Probability :: 
    Bayes Rule中的Pr(h)被称为Prior Probability
    
后验概率 Posterior Probability :: 
    Bayes Rule中的Pr(h|D)被称为Posterior Probability
    
似然 Likelihood Function :: 
    Pr(D|h)，通常来说，Likelihood Function是很容易计算的
    
最大后验概率 Maximum a Posteriori :: 
    {{$
    h_{MAP}=argmax_{h}P(h|D), \forall h \in H
    }}$
    
最大似然 Maximum Likelihood ::
    {{$
    h_{ML} = argmax_{h}P(D|h), \forall h \in H
    }}$
    
贝叶斯最佳分类器 Bayes Optimal Classifier ::
    {{$
        argmax_{v_j \in V}\sum_{h_i \in H}P(v_j|h_i)P(h_i|D)
    }}$
    where $v_j$'s come from the set of possible classifications assigned by H
    
贝叶斯网 Bayesian Network ::
    贝叶斯网又称为信念网(Belief Network).
    Given a set of random variables $Y_1, Y_2, \cdots, Y_n$, a network is called belief network if the joint probability distribution of the n-tuple $(Y1, \cdots, Y_n)$ can be written as 
    {{$
        P(Y_1, \cdots, Y_n) = \prod_{i=1}^{n}P(Y_i | Parents(Y_i))
    }}$

朴素贝叶斯 Naive Bayes :: 

条件独立性 Conditional Independence :: 
    令X, Y和Z为三个离散值随机变量。当给定Z值时，X服从的概率分布独立于Y的值，则X在给定Z时条件独立于Y, 用公式表达为：
    {{$
        P(x|y,z) = P(x|z)
    }}$
    
评分函数 Score Function :: 

最小描述长度 Minimal Description Length :: 
    {{$
        h_{MDL} = argmin_{h\in H}L_{C_1}(h) + L_{C_2}(D|h) where
    }}$
    L_{C}(x)代表在编码格式C下，用于x的描述长度
吉布斯采样 Gibbs Sampling :: 一种随机采样方法
随机漫步 Random Walk ::
马尔可夫链 Markov Chain :: 
平稳分布 Stationary Distribution :: 
隐变量 Latent Variable :: 未观测变量
边际似然 Marginal Likelihood :: 
EM 算法 Expectation-Maximization :: 用来估计参数隐变量
    
#### 贝叶斯规则 Bayes Rule
==== 使用贝叶斯规则 Thought Process when using Bayes Rule====
    1. 首先确定先验概率 Determine the prior probabilities
    2. 其次找到目标后验概率的表达式 Determine the equation to compute posterior probability
    3. 根据贝叶斯规则带入先验概率算出后验概率 Use the Bayes Rule and the priors to compute posterior
    
#### 贝叶斯学习
在已知一个训练集时，我们可以根据此训练集获得每个假设的后验概率，然后挑选出拥有最大后验概率(MAP)的假设，这就是使用贝叶斯规则训练分类器的基本思路.
计算最大似然的方法有很多，但在通常情况下，我们可以将其简化为计算最大似然,即$ Pr(D|h) $.
很显然，这个过程涉及到两个大过程，一为计算最大似然，二为基于先前得到的最大似然挑选最佳假设, 下面将对两大过程提供详细描述.
##### 计算最大似然
        
##### 挑选最佳假设
在挑选最佳假设的时候，我们希望挑选简单但预测准确的假设，我们可以将简单这个指标量化为最小描述长度.
#### 贝叶斯最佳分类器
通过贝叶斯学习法学得的假设不一定能让我们正确分类一个变量，比如?????
为了能正确分类，我们需要用到贝叶斯最佳分类器
贝叶斯最佳分类器的缺点在于速度太慢
#### 朴素贝叶斯
为了获得更快的计算速度，我们可以使用朴素贝叶斯分类器来替代贝叶斯分类器
