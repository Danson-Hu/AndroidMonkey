#!/usr/bin/python3
# -*- coding: utf-8 -*-
# @Time    : 2021/9/29 21:07
# @Author  : Danson
import yagmail

# 链接邮箱服务器
yag = yagmail.SMTP(user="h18279164409@163.com", password="VAGSZVJLVAYGLXCP", host='smtp.163.com')

# 邮箱正文
contents = ['This is the body, and here is just text']

# 发送邮件
yag.send('1362175426@qq.com', 'subject', contents)
