---
date: '2017-08-14'
tags:
- rails
- ruby
- javascript
- coffeescript
- web dev
title: Select2 With Simple Form in Rails
---

[Select2](https://select2.github.io/) is a great JQuery plugin that customizes your select boxes to give a better user interface and experience.

Recently while working on a Rails project, I was experiencing some problems when using Select2 and [Simple Form](https://github.com/plataformatec/simple_form) in my view.

In the view, I want to use Select2 to search for people in a `Person` table in the application's database. Select2 should use AJAX to hit a controller's action that performs the search. The user can then select one of the results found and it will be added to the field as a token (this is a multiple select field).

The controller action looks something like this:

```ruby
def search
  @people = Person.all.where('name LIKE ? OR last_name LIKE ?',
    "%#{params[:q]}%", "%#{params[:q]}%")

  respond_to do |format|
    format.json { render json: @people.map { |p| { id: p.id, full_name: p.full_name } } }
  end
end
```

<!--more-->

As you can see, we are returning `full_name`, which is a model instance method that combines both name fields and returns it into a single string.

Let's assume that the endpoint can return the following data:

```json
[
  { id: 1, full_name: "Pablo Escobar" },
  { id: 2, full_name: "Enrique Iglesias" }
]
```

In my view, I use Simple Form association helper to create the field.

```haml
= f.association :plaintiffs, input_html: { 'data-endpoint': people_search_path, class: 'select2-field' }
```

I then implement Select2 using CoffeScript like this:

```coffeescript
$ ->
  $('.select2-field').select2
    theme: 'bootstrap'
    minimumInputLength: 1
    maximumInputLength: 20
    ajax:
      url: $('.select2-field').data('endpoint')
      dataType: 'json'
      delay: 250
      data: (params) ->
        {
          q: params.term
          page: params.page
        }

      processResults: (data) ->
        {
          results: $.map(data, (item) ->
            {
              text: item.full_name
              id: item.id
            }
        )}
```

The problem was that after selecting the result, **only the first name** would appear in the field. In other words, only the part before the space in the full name.

![Simple Form Token Issue](/posts/select2-with-simple-form-in-rails/sf_issue.png)

Initially I thought this was a Select2 issue, but then I realized that it was actually a Simple Form issue. So I made this post specifically for future reference.

## The Solution

This solution is super simple. We need to add the `label_method` attribute to the Simple Form select field. Like this:

```haml
= f.association :plaintiffs, label_method: :full_name, value_method: :id, input_html: { 'data-endpoint': people_search_path, class: 'select2-field' }
```

Note how I specify the `full_name` field of the returned JSON data. I also added `value_method` in the example above, but it is not necessary.

The tokens should now look the way they were supposed to:

![Correct tokens](/posts/select2-with-simple-form-in-rails/correct_tokens.png)