import unittest
from LazyAI.celery import debug_task
from unittest.mock import patch, MagicMock

class TestCeleryTasks(unittest.TestCase):
    def test_debug_task(self):
        # 创建一个模拟请求对象
        mock_request = MagicMock()
        mock_request.id = 'test_id'
        mock_request.retries = 0

        # 使用 patch.object 替换 request 属性
        with patch.object(debug_task, 'request', mock_request):
            # 捕获输出
            with self.assertLogs() as log:
                debug_task()
                # 检查输出是否包含预期的请求信息
                self.assertIn("Request: <MagicMock", log.output[0])

if __name__ == '__main__':
    unittest.main()

