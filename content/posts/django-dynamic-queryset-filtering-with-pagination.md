---
date: '2018-01-17'
tags:
- django
title: Django Dynamic Queryset Filtering With Pagination
---

[This blog article](https://simpleisbetterthancomplex.com/tutorial/2016/11/28/how-to-filter-querysets-dynamically.html) does a very good job at explaining how to setup dynamic queryset filtering in Django. However, it doesn't go into paginating the filtered queryset results.

I had a very hard time trying to implement this pagination feature using **class based views**. More specifically, using the `FilterView` that comes with the [django-filter](https://github.com/carltongibson/django-filter) package.

In the end it turned out to be very simple. The [documentation](https://django-filter.readthedocs.io/en/master/guide/usage.html#generic-view-configuration) was a bit misleading on this so it took a while to understand and find the solution.

<!--more-->

## Enabling Pagination

We can enable pagination by adding a `paginate_by` attribute in a `FilterView`, just like when we do so in a Django `ListView`:

```python
class CanalAdvancedSearch(FilterView):
    filterset_class = BookFilter
    template_name = 'advanced_search.html'
    paginate_by = 10
```

This is because `FilterView` inherits from a `BaseFilterView`, which in turn inherits from Django's `MultipleObjectMixin` which [allows pagination](https://docs.djangoproject.com/en/2.0/ref/class-based-views/mixins-multiple-object/#multipleobjectmixin) capabilities. [See source code](https://github.com/carltongibson/django-filter/blob/master/django_filters/views.py#L82)

The trick though is that in the template we no longer iterate over `form.qs` as [specified in the documentation](https://django-filter.readthedocs.io/en/master/guide/usage.html#the-template), as this will make the template show the _whole_ queryset.

Instead, we must iterate over `object_list` in the template, like so:

```liquid
{% for book in object_list %}
  <h4>{{ book.title }}</h4>
{% empty %}
  <p>No results!</p>
{% endfor %}

{% include '_partials/_pagination.html' %}
```

And we can include the typical pagination partial at the end. For completeness, here is a snippet of that:

```liquid
{% if is_paginated %}
  <div class="row">
    <div class="col-md-12">
      <div>
        {% if page_obj.has_previous %}
          <a href="?page={{ page_obj.previous_page_number }}"><span class="pg-arrow_left"></span></a>
        {% endif %}

        <span class="small">Page {{ page_obj.number }} of {{ page_obj.paginator.num_pages }}</span>

        {% if page_obj.has_next %}
          <a href="?page={{ page_obj.next_page_number }}"><span class="pg-arrow_right"></span></a>
        {% endif %}
      </div>
    </div>
  </div>
{% endif %}
```

With this we are now able to show the _**filtered**_ results paginated nicely.

## Filter Form Widgets

If we wanted to show each field in the template separately instead of using `{{ filter.form.as_p }}`, so that we can add CSS classes and layouting to the form, we can specify a widget to each filter inside the `FilterSet` object:

```python
class BookFilter(django_filters.FilterSet):
  title = django_filters.CharFilter(
      lookup_expr='icontains',
      widget=forms.TextInput(attrs={'class': 'form-control'})
  )
```

In the template we can then show it like this:

```html
<div class="form-group">
  <label>{{ filter.form.title.label_tag }}</label>
  {{ filter.form.title }}
</div>
```

## References

1. [How to Filter QuerySets Dynamically](https://simpleisbetterthancomplex.com/tutorial/2016/11/28/how-to-filter-querysets-dynamically.html)
2. https://stackoverflow.com/questions/46961826/how-to-add-pagination-to-filterview
3. https://django-filter.readthedocs.io/en/master/index.html