---
title: "Custom Admin Action Buttons in Django"
date: 2020-04-29T12:06:31-06:00
tags: [django]
---

In this post I will explain how you can add custom action buttons in the admind detail view of for objects in the Django admin.

This is the final result we want to achieve:

![Custom Admin Buttons](/posts/custom-admin-action-buttons-in-django/custom_admin_buttons.png)

These buttons can trigger custom actions we want to perform on these objects.

<!--more-->

## Creating The Template

In order to add these buttons. We need to override the existing admin template that Django provides. For our use case, this template is called `change_form.html`.

The path will depend on the name of the app our model is located in, and the name of our model. So for a `Book` model in a `books` app, the path of the template would be `templates/admin/books/book/change_form.html`.

Go ahead and create that HTML template file with that directory path structure inside your Django **project** directory. Here is an example:

```
myproject/
├── asgi.py
├── __init__.py
├── settings.py
├── templates
│   └── admin
│       └── books
│           └── book
│               └── change_form.html
├── urls.py
└── wsgi.py
```

In order for Django to recognize this template path, add it to your template discovery configuration in `settings.py`:

```python
TEMPLATES = [
    {
        # ...

        'DIRS': ['naughtee/templates'],
    },
]
```

Now open the HTML template file and add the following:

```html
{% extends "admin/change_form.html" %}

{% load i18n admin_urls %}

{% block object-tools-items %}
    <li>
        <a href="{% url opts|admin_urlname:'history' original.pk|admin_urlquote %}" class="historylink">{% trans "History" %}</a>
    </li>
    <li>
        <a href="{% url 'books:bust-cache' original.pk %}?next={% url 'admin:books_book_change' original.id %}" class="historylink">Bust Cache</a>
    </li>
    <li>
        <a href="{% url 'books:schedule-maintenance' original.pk %}?next={% url 'admin:books_book_change' original.id %}" class="historylink">Schedule For Maintenance</a>
    </li>
    {% if has_absolute_url %}
        <li>
            <a href="{% url 'admin:view_on_site' content_type_id original.pk %}" class="viewsitelink">{% trans "View on site" %}</a>
        </li>
    {% endif %}
{% endblock %}
```

This will load the original admin template for this view, but also allows us to add extra content. In our case, two new buttons.

Notice how we are specifying new URLS for the new buttons. This allows us to call custom functions using a `GET` request when the buttons are clicked.

## Creating the Views

We can create simple function-based views to execute our custom business logic:

```python
# books/views.py
from django.contrib.admin.views.decorators import staff_member_required


@staff_member_required
def bust_book_cache(request, book_id):
    pass


@staff_member_required
def schedule_book_maintenance(request, book_id):
    pass
```

It is important that we use the `staff_member_required` decorator for these functions. Since they are supposed to be executed strictly from the Django admin, which means only logged in admins are allowed to trigger these functions.

Now let's go ahead and define the URLs first. In `urls.py` of the `books` app:

```python
from django.urls import path

from . import views

app_name = 'books'

urlpatterns = [
    path(
        '<int:book_id>/bust-cache',
        views.bust_book_cache,
        name='bust-book-cache'
    ),
    path(
        '<int:book_id>/schedule-maintenance',
        views.schedule_book_maintenance,
        name='schedule-maintenance'
    ),
]
```

All done! Now try clicking on the buttons yourself, and your functions should be succesfully called. Nice Django admin custom actions made simple! :tada:
