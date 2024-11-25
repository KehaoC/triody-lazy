# triody-lazy
Triody's first product - LazyAI. 
*Build because your time deserves better.*
*让人回归于人。*

## Setup
Frontend - SwiftUI: https://developer.apple.com/xcode/swiftui/
Backend - Django: https://docs.djangoproject.com/en/5.1/topics/install/
Database - Supabase: https://supabase.com/docs/guides/getting-started/quickstart

```bash
conda env create -f environment.yml
```

## DevFlow with Git

Attention:
1. 数据库在AWS上，所以需要VPN。
2. 数据库已经配置好，使用 Django 的 ORM 操作数据库而不是Supabase 的REST API。

```bash
# Step 1: 创建功能分支 （尤其注意： 开发前pull develop 减少冲突）
git checkout develop
git pull origin develop
git checkout -b feature/frontend/login-page

# Step 2: 开发和提交代码
git add .
git commit -m "[前端新增] 完成登录页面的布局和基本功能"

# Step 3: 推送功能分支
git push origin feature/frontend/login-page

# Step 4: 创建 Pull Request
# - 登录 GitHub，填写标题和描述，选择目标分支为 develop

# Step 5: 修改代码（会议后现场完成）
git add .
git commit -m "根据审查意见优化登录逻辑"
git push origin feature/frontend/login-page

# Step 6: 合并 PR 后，删除本地和远端分支
git branch -d feature/frontend/login-page
git push origin --delete feature/frontend/login-page
```

hi