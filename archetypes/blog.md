---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
description: ""
author: ""
tags: []
keywords: []
resources:
  - src: "**.{png,jpg}"
    title: "Image #:counter"
---
