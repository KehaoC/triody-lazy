# 文件路径: database.py

from django.apps import apps
from django.db import models

class Database:
    @staticmethod
    def get_model(table_name: str) -> models.Model:
        """
        获取Django模型类
        :param table_name: 表的名字
        :return: Django模型类
        """
        try:
            model = apps.get_model('team', table_name)
            return model
        except LookupError:
            raise ValueError(f"表名 {table_name} 无效，请检查模型是否存在。")

    @staticmethod
    def insert(table_name: str, **kwargs) -> models.Model:
        """
        插入一条记录
        :param table_name: 表的名字
        :param kwargs: 要插入的字段和值
        :return: 新创建的模型实例
        """
        model = Database.get_model(table_name)
        instance = model.objects.create(**kwargs)
        return instance

    @staticmethod
    def select(table_name: str, **filters) -> models.QuerySet:
        """
        查询记录
        :param table_name: 表的名字
        :param filters: 查询条件
        :return: 查询结果集
        """
        model = Database.get_model(table_name)
        return model.objects.filter(**filters)

    @staticmethod
    def update(table_name: str, filters: dict, updates: dict) -> int:
        """
        更新记录
        :param table_name: 表的名字
        :param filters: 筛选条件
        :param updates: 更新的字段和值
        :return: 受影响的记录数
        """
        model = Database.get_model(table_name)
        queryset = model.objects.filter(**filters)
        affected_rows = queryset.update(**updates)
        return affected_rows

    @staticmethod
    def delete(table_name: str, **filters) -> int:
        """
        删除记录
        :param table_name: 表的名字
        :param filters: 删除条件
        :return: 被删除的记录数
        """
        model = Database.get_model(table_name)
        queryset = model.objects.filter(**filters)
        deleted_count, _ = queryset.delete()
        return deleted_count


##使用示例
# Database.insert("User", name="John Doe", email="john@example.com", password="securepassword123")
# users = Database.select("User", name="John Doe")
# for user in users:
#     print(user.email)
# Database.update("User", {"name": "John Doe"}, {"email": "newemail@example.com"})
# Database.delete("User", name="John Doe")
