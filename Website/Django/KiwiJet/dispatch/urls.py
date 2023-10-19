from django.urls import path
from . import views

urlpatterns = [
    path('dispatch/', views.dispatch, name='dispatch'),
]