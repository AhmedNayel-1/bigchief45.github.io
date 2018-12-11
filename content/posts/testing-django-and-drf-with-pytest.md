---
date: '2018-02-09'
tags:
- python
- django
- djangorestframework
title: Testing Django and DRF With Pytest
---

[Pytest](https://docs.pytest.org/en/latest/contents.html) has become my favorite Python testing framework. And in this article I want to go over on how I learned to write nice tests for Django and [Django REST Framework](http://www.django-rest-framework.org/).

We will be using the following tools:

- [Pytest](https://docs.pytest.org/en/latest/contents.html): Python testing framework
- [pytest-django](https://pytest-django.readthedocs.io/): Pytest extensions for Django
- [factoryboy](https://factoryboy.readthedocs.io/): Factories for easy test data generation.

<!--more-->

## Setting Up Pytest in a Django Project

There are different ways you can setup pytest in a Django project:

- Use a `pytest.ini` config file at the root of your project.
- Use a `conftest.py` file in your tests directory where you can use Python to define configuration and fixtures.

I will be using the first and simplest approach. You can create a `pytest.ini` file at the root of your project and define where your Django settings module is:

```ini
[pytest]
DJANGO_SETTINGS_MODULE = myproject.settings.dev
```

## Testing Django

I'll first start with Django and then we'll take a look at Django REST Framework. To start, we will want to add some unit tests for our models and integration tests for our views. After that we can take a look on how to test other stuff such as middleware and custom commands.

### Django Tests Structure

Your Django application comes with a default `test.py` file. I usually remove this file and create a `tests/` directory inside every app of my project.

Inside this directory I will place all the different tests I write, in different subdirectories depending on the type of test. This is what I usually use as reference:

- `unit`: The most basic and fastest tests. Usually for models and pieces of code that can be interacted with directly.
- `integration`: Usually for views. These tests usually consists of a factory or client that will perform the request or interaction to the view.

### Model Unit Tests

These are the easiest tests. For illustrative purposes, supppose I have the following model:

```python
class Bank:
    name = models.CharField(_('Name'), max_length=20, unique=True)
    managers = models.ManyToManyField(Manager, blank=True)
    employees = models.ManyToManyField(Employee, blank=True)
    interns = models.ManyToManyField(Intern, blank=True)

    @property
    def people(self):
        return self.managers.all() | self.employees.all() | self.interns.all()
```

I want to test that this model property method indeed returns all the objects from those 3 ManyToMany fields. We will write a unit test that does so.

#### Factories

Before we begin writing the test, let's understand what factories are and how they can help us write better tests.

Factories are defined objects that represent a model in our application. Factories can help us generate an infinite amount of test data and instances that our tests can use.

From the `Bank` model example above, I can go ahead and make a factory for this model. I usually put my factories in a `/tests/factories.py` module:

```python
import factory

from myapp.models import Bank


class BankFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Bank

    name = factory.Sequence(lambda n: 'bank_%d' % n)

    @factory.post_generation
    def managers(self, create, extracted, **kwargs):
        if not create:
            return

        if extracted:
            for manager in extracted:
                self.managers.add(manager)

    # Same for interns and employees
    # ...
```

The `@factory.post_generation` allows us to add more objects to the ManyToMany relation. Assuming we also have factories for those models, we could create a test bank object like this:

```python
bank = BankFactory(
    managers=[ManagerFactory()],
    employees=[EmployeeFactory()],
    interns=[InternFactory()]
)
```

And now we can finally use that in our test:

```python
# tests/unit/test_banks.py

import pytest

from myapp.tests.factories import (
    BankFactory,
    ManagerFactory,
    EmployeeFactory,
    InternFactory
)


class TestBanks:

    @pytest.mark.django_db
    def test_bank_people(self):
        """Tests that we can obtain all people associated with this bank."""
        bank = BankFactory(
            managers=[ManagerFactory()],
            employees=[EmployeeFactory()],
            interns=[InternFactory()]
        )

      assert bank.people.count() == 3
```

Since we are creating 3 people of different type each in our test, this test should pass.

-> `@pytest.mark.django_db` is a decorator provided by pytest-django that gives the test write access to the database.

### View Tests

Now let's take a look at how we can test our views. I will show an example of a **Class Based View**:

```python
from django.http import JsonResponse
from django.views import View


class MyView(View):

    def get(self, request):
        # Some complex processing here.

        return JsonResponse({'result': 'FINISHED'})
```

And it's URL:

```python
url(r'^(?i)myview/$', views.MyView.as_view(), name='myview'),
```

A very simple view. We are going to test 2 things:

1. The response status code
2. The response content

Of course, depending on the complexity of your view you can (and should) test more things, like objects created/remove in the database, etc. etc.

To test this view we will be using the `rf` request factory pytest fixture provided by pytest-django. We only need to add it to the test function's parameters:

```python
# tests/integration/test_myview.py

import json

from django.core.urlresolvers import reverse

from myapp.views import MyView


class TestMyView:

    def test_result_finished(self, rf):
        request = rf.get(reverse('myview'))
        response = MyView.as_view()(request)

        assert response.status_code == 200

        content = json.loads(response.content)
        assert content['result'] == 'FINISHED'
```

And that's it. Keep in mind that this view is not interacting with the database, so I did not include the decorator we saw before. Also, we are not taking into account any authentication in this view. If you need to, then you can assign a user to the `request` object:

```python
request.user = my_user
```

In this case `my_user` can be a user generated by a factory (if you have custom user auth models in your application), or you can use another user fixture provided by pytest-django.

#### Testing View Context Data

If you ever need to test the view's context data you can do so by accessing `response.context_data` dictionary. However if you are like me and prefer setting a CBV's context data using [this method](https://reinout.vanrees.org/weblog/2014/05/19/context.html) (just to show an example):

```python
class MyView(TemplateView):
    template_name = 'mytemplate.html'

    def books(self):
        return Book.objects.filter(library__name=self.request.kwargs['library_name'])

```

You can make the assertion by accessing the `view` object in the dictionary, just like it is done in the template. Like this:

```python
assert len(response.context_data['view'].titulos()) == 2
```

#### Setting Cookies

If you need to set special cookies in your tests to test a view. You can do it using a request factory easily :

```python
request.COOKIES['mycookie'] = 'akdasd090190239091290013asd;'
```


## Testing Django REST Framework

Testing DRF is very similar to testing Django views. However, DRF's views extend Django's class based views and therefore are more complex. Additionally, DRF comes with its own set of test [classes and utilities](http://www.django-rest-framework.org/api-guide/testing/) that we can use to make the process easier.

The `APITestCase` class is a very neat class to use for DRF tests, it comes with its own instance of `APIClient`. However, since `APITestCase` subclasses Django's `TestCase` class, we won't be able to pass Pytest fixtures to our tests. This means that we will have to force authenticate the client and assign it a user in *each* of the tests. Very cumbersome.

This is why I prefer not using `APITestCase` and create a custom fixture that returns a `APIClient` instead. We'll see how this works in the next section.

### Testing Viewsets

[DRF Viewsets](http://www.django-rest-framework.org/api-guide/viewsets/) are extremely handy. Unfortunately the documentation to test them is not very straightforward.

Since Viewsets can handle the usual REST requests (GET, POST, PUT, PATCH, DELETE) in a single viewset class, it is necessary that we understand how to specify which action we want to target in our tests.

For these examples I am going to use the following viewset:

```python
from rest_framework import viewsets


class BankViewSet(viewsets.ModelViewSet):
    queryset = Bank.objects.all()
    serializer_class = BankSerializer
```



#### GET

Like I mentioned previously, we will use a custom fixture that returns an `APIClient` object. We can assign a user and force authentication in the fixture.

## References