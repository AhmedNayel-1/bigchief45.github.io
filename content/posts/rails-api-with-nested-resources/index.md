---
date: '2017-05-08'
tags:
- rails
- ruby
- api
- back-end
- web-dev
title: Rails API With Nested Resources
---

[Cocoon](https://github.com/nathanvda/cocoon) is a very popular gem to add nested resources functionality in Rails. It allows you to add or remove "mini forms" of another model into a main model's form and create all objects at once when the form is saved.

I was recently finding myself trying to implement a similar functionality using only Rails 5 API and [JSON API specification](http://jsonapi.org).

As an example, we will try to implement the commonly seen *Work Experience* and *Educational Background* features seen in sites such as LinkedIn, where the user can add many items for these categories. The user's profile and all items for those categories (which are separate models) should all be saved at once, once the form is submitted.

![Education](/posts/rails-api-with-nested-resources/education.jpg)

## accepts\_nested\_attributes\_for

[`accepts_nested_attributes_for` ](http://api.rubyonrails.org/classes/ActiveRecord/NestedAttributes/ClassMethods.html) allows us to save attributes on **associated** records (work experience, educational background) through a parent record (user). By default nested attribute updating is turned off and you can enable it using the `#accepts_nested_attributes_for` class method.

<!--more-->

Let's take a look on how the models could be defined and implement `accepts_nested_attributes_for`:

```ruby
class User < ApplicationRecord
  has_many :work_experiences
  has_many :educational_backgrounds

  accepts_nested_attributes_for :work_experiences, allow_destroy: true
  accepts_nested_attributes_for :educational_backgrounds, allow_destroy: true
end

class WorkExperience < ApplicationRecord
  belongs_to :user, optional: true
end

class EducationalBackground < ApplicationRecord
  belongs_to :user, optional: true
end
```

The `:allow_destroy` option allows the deletion of nested work experience or educational background items.

For the "child" models, the presence of the user is defined as optional. This attribute is important because without it, the model validation will fail with *User must exist* when it tries to create Work Experiences for which an Event does not yet exist.

The `accepts_nested_attributes_for` method defines an attribute writer on the parent model. This is a method which by convention is named after the nested model, with the postfix `_attributes`. In our case this becomes `work_experiences_attributes` and `educational_backgrounds_attributes`.

## Strong Parameters

Strong parameters in the parent resource's controller must be configured correctly to accept the nested attributes from the other resources. This can be done in the following manner:

```ruby
# users_controller.rb

def user_params
  params.require(:user).permit(:name, :email, work_experiences_attributes: [:id, :title, :company, :location, :description], educational_background_attributes: [:id, :institution, :career, :description])
end
```

This works fine in typical scenarios. But what if we are using JSON API specification?

### JSON API

Parameters are required and permitted a bit differently when the API follows the JSON API specification.

We can re-write the method above to reflect this:

```ruby
def user_params
  params.require(:data).require(:attributes).permit(:name, :email, :email, work_experiences_attributes: [:id, :title, :company, :location, :description], educational_background_attributes: [:id, :institution, :career, :description])
end
```