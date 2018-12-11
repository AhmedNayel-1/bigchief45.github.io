---
date: '2018-01-10'
tags:
- django
- python
- javascript
- elasticsearch
title: Django AJAX Search With Elasticsearch
---

In this post I want to go over how I implemented a very neat AJAX search using Elasticsearch in Django. Let's get started!

## The Search Template

The starting point of our search feature will be the search template. That is, the template that contains the input field where the user will type in the search keywords.

This template is extremely simple and does not need a `<form>` tag. I will create it as a partial under `templates/search.html`:

```liquid
{% csrf_token %}
<input id="search" name="q" placeholder="Search...">
```

Notice how we have given the input a `name` with the value of `q`. This will be important when our view receives the query from this input field.

I can then render this partial in the main template like this:

```liquid
{% include 'search.html' %}
```

<!--more-->

In my case I am using a very neat front end theme called [Revox Pages](http://pages.revox.io/) which includes a very sweet JQuery search feature:

![Revox Pages Search](/posts/django-ajax-search-with-elasticsearch/revox_pages_search.png)

## Creating the View

We can now proceed to create the view that will handle the AJAX request that contains the query, perform the query in ElasticSearch, and then return the results.

I am a big fan of [Django Class Based Views](https://docs.djangoproject.com/en/2.0/topics/class-based-views/), so I will implement the view in the following way:

```python
from django.views import View
from django.shortcuts import render_to_response

from elasticsearch import Elasticsearch

from myapp.models import MyModel


class MyModelSearchView(View):
    def post(self, request, *args, **kwargs):
        query = self.request.POST.get('q', None)

        elastic_query = {}
        es = Elasticsearch('http://myelastichost:9200')
        res = es.search(index='myindex', body=elastic_query)

        # Let's assume that the response contains a list of IDs.
        # These are the IDs of the objects we want to retrieve from our
        # database.
        #
        # The structure of the response might vary depending on the query
        # you are trying to do.
        result_ids = [m['_id'] for m in res['hits']['hits']]
        result_objects = MyModel.objects.filter(id__in=result_ids)

        return render_to_response(
            '_partials/_search_results.html',
            {'models': result_objects}
        )
```

This is the good part. Our view will build a query following ElasticSearch's query DSL, and will then use the [ElasticSearch Python client](https://elasticsearch-py.readthedocs.io/en/master/) to run it in our ElasticSearch server. The client will then contain the response of the search results.

Afterwards, we are going to fetch from the Django application's database the objects that match the results returned by ElasticSearch. This way we can create a template (soon on this) that will contain all these results along with their respective model data.

~> The `render_to_response()` method has been deprecated in Django 2.0 for the `render()` method.

Also let's not forget to add the appropriate URL for this view:

```python
# urls.py

url(
    r'^/search',
    views.MyModelSearchView.as_view(),
    name='model-search'
),

```

## Search Results Partial

We will create a handy partial in `templates/_partials/_search_results.html` that will contain the list of the search results. A very basic example would be:

```liquid
{% if models.count > 0 %}
  {% for object in models %}
    <div>
      <h5>{{ object.title }}</h5>
      <p>{{ object.author }}</p>
    </div>
  {% endfor %}
{% endif %}
```

Obviously you should include the fields from your model that you want to show, and probably add some nice styling with Bootstrap.

## Making the AJAX Call

The last step is to write the JavaScript that will fire the AJAX request to our view, obtains the response, and appends the HTML from the response (thanks to the `render_to_response()` method) to show the final results.

The search component of the theme I am using comes with some JavaScript template that I can tweak to fit my needs. For example:

```javascript
// search.js

$(document).ready(function() {
  // Initializes search overlay plugin.
  // Replace onSearchSubmit() and onKeyEnter() with
  // your logic to perform a search and display results
  $('[data-pages="search"]').search({
    searchField: '#overlay-search',
    closeButton: '.overlay-close',
    suggestions: '#overlay-suggestions',
    brand: '.brand',
    onSearchSubmit: function(searchString) {
      $.ajax({
        type: 'POST',
        url: '/search',
        data: {
          'q': searchString,
          'csrfmiddlewaretoken': $('input[name=csrfmiddlewaretoken]').val()
        },
        success: function(res) {
          let searchResults = $('.search-results');
          let wait = setTimeout(function() {
            searchResults.find('.result-name').each(function() {
              searchResults.fadeIn('fast');
            });
          }, 500);
          $(this).data('timer', wait);

          searchResults.html(res);
        }
      });
    },
  });
});
```

The `onSearchSubmit` method will get called when the user presses the <kbd>ENTER</kbd> key after typing in the search query. This method will make an AJAX call to the URL we defined previously, passing in the the query `q` and the CSRF token to the controller. Afterwards it will append the template in the response to the `.search-results` area in the search template we created.

Here is a GIF so you can see it all in action:

![Final AJAX Search](/posts/django-ajax-search-with-elasticsearch/ajax_search.gif)

# References

1. [Python Django tutorial 15 - Ajax search feature by Mike Hibbert ](https://www.youtube.com/watch?v=jKSNciGr8kY)