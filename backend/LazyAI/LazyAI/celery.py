from __future__ import absolute_import, unicode_literals
import os
from celery import Celery

# 设置Django默认配置模块
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'LazyAI.settings')

# 创建Celery实例
app = Celery('LazyAI')

# 从Django设置文件中导入Celery配置
app.config_from_object('django.conf:settings', namespace='CELERY')

# 自动发现所有Django应用中的tasks.py文件
app.autodiscover_tasks()

@app.task(bind=True)
def debug_task(self):
    print(f'Request: {self.request!r}')