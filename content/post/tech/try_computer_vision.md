---
title: "[学无止境]之机器视觉"
date: 2016-09-21T16:53:53+08:00
lastmod: 2016-09-21T16:53:53+08:00
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

# Point Process

## Pixel Transforms
* An operator is a function that takes one or more input images and produces an output image.
    $$
    g(x) = h(f(x))
    $$
* Two commonly used point processes are multiplication and addition with a constant
    $$
    g(x) = af(x) + b
    $$
    where a is called gain or contrast and b is called bias or brightness.
## Color Transforms

## Compositing and Matting

## Histogram Equalization

### Linear Filtering
Operator :: An _operator_ H (or system) is linear if two properites hold (f1, and f2 are some functions, a is a constant)

- H(f1 + f2) = H(f1) + H(f2) *Associative*
- H(a * f1) = a * H(f1) *Multiplicative*
- Question: Does the associativity and multiplicativity of H implies associativity and multiplicativity of f1 and f2? Vice Versa? Is an operator a function?

Impulse Function: An _inpulse function_ is an idealized function that is very narrow and very tall so that it has a unit area.
Impulse Response:  An _impulse response_ is an result of operator H on an impulse function.
Correlation: A _cross correlation_
Convolution: A [_convolution_]( http://mathworld.wolfram.com/Convolution.html ) 
Normal Distribution:
$$
G(x) = \frac{1}{\sigma\sqrt{2\pi}}e^{(\frac{-(x-\mu)^2}{2\sigma^2})}
$$

## Matching with Correlation
----
We can use correlation and related methods to find locations in an image that are similar to a template.
1. Measure the similarity between the template and the region of the image with which it is aligned.

We achieve this by measuring the sum of the square of the differences between values in the template and in the image.
$$
\sum_{i=-N}^{N}[F(i) - F(x+i)]^2 = \sum_{i=-N}^{-N}(F^2(i) + I^2(x+i) -2F(i)F(x+i)) = \sum{i=-N}^{N}(F^2(i))+\sum_{i=-N}^{N}(I^2(x+i))-2\sum_{i=-N}^{N}![pic](F(i)I(x+i))
$
Weakness: Correlation can also be high in locations where the image intensity is high even if it doesn't match the template well.
    
2. Normalized correlation by computing

$$
\frac{\sum_{i=-N}^{N}![pic](F(i)I(x+i))}{\sqrt{\sum_{i=-N}^{N}(I(x+i))^2\sqrt{\sum_{x=-N}^{N}(F(i))^2```
$$

## Linear Filter
----
* Linear Filter is an operator such that an output pixel's value is determined as a weighted sum of input pixel values
    $$
    g(i, j) = \sum_k\sum_l f(i+k, j+l)h(k, l)
    $$
    we called it a correlation operator.
* h(k, l) is called a weight kernel or mask
* Convolution Operator
    $$
    g(i, j) = \sum_{k,l}f(i-k, j-l)h(k,l) = \sum_{k,l}f(k,l)h(i-k, j-l)
    $$
    Here h is called the impulse response function because h, convolved with an impulse signal, repreduces itself.
* Both correlation and convolution is _linear shift-invariant_ (LSI) operators.
## Seperability
----
Sometimes we can seperate a filter into convolution of simpler filters.
## Boundary Issues
----
There are four ways to tackle boundary issues where filter falls out of the edge of the image it is applying to:
    1. *clip filter* - we clip the boundary of the image with all black pixels. The resulting image would have a black ribbon around the edge.
    2. *wrap around* - we take the image as a _continuous signal_.
    3. *copy edge* - we extend the pixels around the image along its direction and then apply the filter.
    4. *reflect across edge* - we reflect the image along its edge and then apply the filter.
# More Neighborhood Operators
# Fourier Transform
# Image Pyramid and Wavelets
# Geometric Transformations
# Global Optimization (Bayesian Markov Random Field)

* Building Block of Functions - Impulse Function
    An impulse is an idealized function that is vary narrow and very tall so that it has a unit area
* Impulse Response
* Filtering an impulse signal 
* Correlation vs Convolutionk
