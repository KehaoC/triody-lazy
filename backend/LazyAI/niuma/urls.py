from django.urls import path
from niuma.views import *
urlpatterns = [
    path("get_all_niuma/", get_all_niuma),
    path("create_basic_niuma/", create_basic_niuma),
    path("get_niuma_detail/", get_niuma_detail),
    path("assign_niuma_to_task/", assign_niuma_to_task),
    path("remove_niuma_from_task/", remove_niuma_from_task),
]
