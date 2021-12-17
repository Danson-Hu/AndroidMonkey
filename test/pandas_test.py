#!/usr/bin/python3
# -*- coding: utf-8 -*-
# @Time    : 2021/7/11 4:07 下午
# @Author  : Danson

L = []


def my_func(x):
    return x ** 2


for i in range(5):
    L.append(my_func(i))

print(L)


print([my_func(i) for i in range(5)])

