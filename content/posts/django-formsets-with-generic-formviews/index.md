---
date: '2018-04-19'
tags:
- django
title: Django Formsets with Generic FormViews
---

[Django Formsets](https://docs.djangoproject.com/en/2.0/topics/forms/formsets/) is an extremely handy feature for handling multiple clones of forms in a single view. In this post I will go over how to implement them using one of Django's built-in generic class based views, the [FormView](https://docs.djangoproject.com/en/2.0/ref/class-based-views/generic-editing/#django.views.generic.edit.FormView).

## The Scenario

To add some context to this tutorial, let's say we want to implement one of those kind of nested searches you see on some sites. Where you can select a field from a dropdown, and type in a search value for each field. Fields can be added and removed dynamically using JavaScript. Something like this:

![Nested Search Example](/posts/django-formsets-with-generic-formviews/nested_search_example.png)

For this tutorial, we will use the following model as an example:

```python
class Book(models.Model):
    title = models.CharField()
    author = models.ForeignKey(Author)
    isbn = models.CharField()
    editorial = models.ForeignKey(Editorial)
```

## Creating the Form

We will begin by creating the form that will be cloned. That is, the form that will represent **one** search query out of the many that will/could be nested together.

For our case, the form will only contain 3 fields:

1. The query field: Indicates which field of the model we will query.
2. The lookup type: Indicates which [lookup](https://docs.djangoproject.com/en/2.0/topics/db/queries/#field-lookups) is going to be used to make the query.
3. The query value: Indicates what we want to actually search for (i.e *Harry Potter* for the book title.)

<!--more-->

And this is how we implement it:

```python
class SearchQueryForm(forms.Form):
    """
    Search query form that will be used inside a formset.
    """
    query_field = forms.ChoiceField(
        choices=(
            ('title', 'Title'),
            ('author__name', 'Author'),
            ('isbn', 'ISBN'),
            ('editorial__name', 'Editorial')
        ),
        widget=forms.Select()
    )

    lookup = forms.ChoiceField(
        choices=(
            ('iexact', 'Equals'),
            ('icontains', 'Contains')
        ),
        widget=forms.Select()
    )

    query = forms.CharField(widget=forms.TextInput())
```

Notice how we are supplying which fields we provide for querying in the `query_field` field, using tuples. The left part of the tuple should equal to the actual model field name, and the right part of the tuple is the display string that will show in the select box in the template. Moreover, pay attention to how we can access relationship fields in the query. For example, we can query the book's author's name using `author__name`.

For the lookups I am only inluding two types: `iexact` for exact matches, and `icontains` for `LIKE` type matches. Both case insensitive.

## Creating the FormView

Now that the form is ready, we will create a `FormView` where we will use a Formset as the view's _"form"_:

```python
from django.db.models import Q
from django.forms import formset_factory

from myapp.forms import SearchQueryForm


class NestedSearch(FormView):
    form_class = formset_factory(SearchQueryForm)
    template_name = 'my_search_template.html'
    success_url = ''

    def form_valid(self, form):
        # Build the query chain
        qs = []
        for form_query in form.cleaned_data:
            q = {'{0}__{1}'.format(form_query['query_field'], form_query['lookup']): form_query['query']}
            qs.append(Q(**q))

        results = Book.objects.filter(*qs)

        return self.render_to_response(self.get_context_data(results=results, form=form))
```

A bit of a mouthful. Let's go over it.

We are using Django's `formset_factory`  to create a simple Formset that will contain an infinite amount of `SearchQueryForm` forms. Since we are going to redirect to the same view to display the results, we do not need to specify a real `success_url`.

After the user submits the form, if the form is valid, the `form.cleaned_data` will be an array of dictionaries. Each dictionary in the array will represent each `SearchQueryForm` and will contain 3 keys with their respective values.

We will build the full query chain using [Django Q Objects](https://docs.djangoproject.com/en/2.0/topics/db/queries/#complex-lookups-with-q-objects). Basically, we will make a Q object per `SearchQueryForm`, and we will send all those Q objects to the usual `filter()` method on the `Book` model.

Notice that since we are assigning dynamic field, lookup, and query value to the Q object, we build the query manually and send it to the Q object as keyword arguments. It is a dynamic way of doing this:

```python
Q(author__name__icontains='Rowling')
```

We store all these Q objects in an array so that we can easily pass them to the `filter()` method using the splat (`*`) operator.

Lastly we redirect to the same view while at the same time adding those results to the context so that it will be available to the template.

## The Template

The template implementation could vary. But here's the basic idea:

```liquid
<form action="" method="POST">
  {% csrf_token %}

  <div class="row">
    <div class="col-md-12">
      <div>
        {% for f in form %}
          <div class="form-group">
            <div class="col-md-2">
              {{ f.query_field }}
            </div>
            <div class="col-md-1">
              {{ f.lookup }}
            </div>
            <div class="col-md-9">
              {{ f.query }}
              <label class="error">{{ f.query.errors }}</label>
            </div>
          </div>
        {% endfor %}
      </div>

      <br>

      <button type="submit" class="btn btn-primary">Search</button>
      {{ form.management_form }}
    </div>
  </div>
</form>
```

Keep in mind that `form` here is actually the _formset_, and `f` would actually be each form _in_ the formset.

We can add the display of results right below the forms:

```liquid
{% if results %}
  <hr>
  <h2>Results</h2>

  {% for result in results %}
    {% include '_my_result_partial.html' with book=result %}
  {% endfor %}
{% endif %}
```

And obviously that means you would have some partial that displays each item using an object with the name `book`.

### Spicying It Up With Some JavaScript

The above approach does not allow us to add or remove forms dynamically. We can use some Javascript to solve this. More specifically, we can use the [django-dynamic-formset](https://github.com/elo80ka/django-dynamic-formset) JQuery plugin to handle this for us.

After you have included the Javascript file in your static assets. You can then add the following JQuery code at the end of your template file:

```html
<script src="{% static 'path/to/plugin/' %}"></script>
<script>
$('.nested-query-formset').formset({
  addText: 'add',
  deleteText: 'remove'
});
</script>
```

The selector you use is up to you. But you will have to place it carefully in your HTML so that the generated add/remove links get the correct placing. In the HTML example above I placed it in the following `<div>`:

```html
<div class="form-group row nested-query-formset">
  <!-- ... -->
</div>
```

And that's it. Here is an example of a personal implementation of this tutorial:

![Nested Search Implementation](/posts/django-formsets-with-generic-formviews/nested_search_result.gif)