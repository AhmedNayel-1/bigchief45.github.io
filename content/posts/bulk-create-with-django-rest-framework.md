---
date: '2017-11-27'
tags:
- python
- djangorestframework
title: Bulk Create With Django REST Framework
---

In this quick post I will go over how to create an endpoint that allows bulk creation of a resource using [Django REST Framework](http://www.django-rest-framework.org/).

## The Serializer

Let's assume that we will be working with an existing `Book` model in our Django application. We will create a serializer for this model using Django REST's [ModelSerializer](http://www.django-rest-framework.org/api-guide/serializers/#modelserializer) helper class:

```python
# serializers.py
from myapp.models import Book
from rest_framework import serializers


class BookSerializer(serializers.ModelSerializer):
    class Meta:
        model = Book
        fields = '__all__'
```

The `"__all__"` string indicates that we want to serialize **all** of the model's fields.

<!--more-->

## The View

Before creating the view, we will first need to create a mixin that will allow the view to handle an array of JSON objects in the request so that the actual view can process and create new objects in a bulk fashion:

```python
class CreateListMixin:
    """Allows bulk creation of a resource."""
    def get_serializer(self, *args, **kwargs):
        if isinstance(kwargs.get('data', {}), list):
            kwargs['many'] = True

        return super().get_serializer(*args, **kwargs)
```

This mixin overwrites the `get_serializer` method and makes it check if the incoming body is a list. If it is, it proceeds to assign a boolean value for the `many` key in the kwargs.

=> Adding the `CreateList` prefix to the mixin class name is a good naming practice that quickly allows us to know that this is a mixin for bulk creation. Additionally, you will probably want to place this mixin in its own module (i.e `views/mixins/rest.py`)

We can now create this view and make it use the mixin. We will make use of Django REST's [ModelViewSet](http://www.django-rest-framework.org/api-guide/viewsets/#modelviewset) to simplyify things:

```python
from rest_framework import viewsets

from myapp.serializers import BoookSerializer
from myapp.views.mixins.rest import CreateListMixin
from myapp.models import Book


class BookViewSet(CreateListMixin, viewsets.ModelViewSet):
    queryset = Book.objects.all()
    serializer_class = BookSerializer
```

## Setting the URL

Lastly we need to set a URL to make the request to. We can use a Django REST router to easily set this endpoint up:

```python
# urls.py
from django.conf.urls import url, include
from rest_framework import routers

from views import BookViewSet


router = routers.DefaultRouter()
router.register(r'books', BookViewSet)

```

And that's pretty much it!