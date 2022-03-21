#!/usr/bin/python3
# -*- coding: utf-8 -*-
# @Time    : 2021/9/29 21:07
# @Author  : Danson
import yagmail

# 链接邮箱服务器
yag = yagmail.SMTP(user="xxx@xx.com", password="xxx", host='smtp.163.com')

# 邮箱正文
contents = ['This is the body, and here is just text']

# 发送邮件
yag.send('xxx@xx.com', 'subject', contents)
