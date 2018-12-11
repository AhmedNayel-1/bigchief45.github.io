---
date: '2017-08-24'
tags:
- rails
- ruby
- web dev
title: Integrating Devise With Rolify in Rails
---

I have searched through tons of StackOverflow questions and blog posts on how to **properly** integrate Rolify with Devise when **registering as a new user** through the registration view provided by Devise. All proposed solutions and half-solutions seemed very messy to me, but I found a very simple way to achieve this.

## Preparing the Roles

Assuming you already have initialized a Devise `User` model along with a Rolify `Role` model, a very common question I see is how should the roles be prepared so that the *new* users can have a list of already created roles to choose from when registering? In the [Rolify documentation](https://github.com/RolifyCommunity/rolify), most (if not all) examples involve implicitely creating roles by adding roles to user in the Rails console:

```ruby
user = User.find(1)
user.add_role :admin
```

A new `admin` role will be created if it does not exist already. But in a fresh application, with no users, a list of existing roles should be available in order to register.

Answers to this dilemma involve different approaches. I personally prefer creating them when seeding the database:

```ruby
# db/seeds.rb

Role.create!(name: 'admin')
Role.create!(name: 'doctor')
Role.create!(name: 'nurse')
```

<!--more-->

Obviously any other dummy data you have in your seeds file should be removed for production.

## Adding Roles to the Registration Form

Now let's proceed to add the available roles to the registration form that the users will use to sign up. Depending on your application, you will have to decide whether you need check boxes (multiple roles) or radio buttons (single role). In this example I will go with radio buttons, limiting the user to a single role only.

Using [Simple Form](https://github.com/plataformatec/simple_form), we can render our radio buttons like this:

```haml
= simple_form_for(resource, as: resource_name, url: registration_path(resource_name)) do |f|
  = devise_error_messages!

  .form-inputs
    = f.input :email, required: true, autofocus: true
    = f.input :password, required: true
    = f.input :password_confirmation, required: true
    = f.input :roles, as: :radio_buttons, collection: Role.all, value_method: :name, required: true

  .form-actions
    = f.button :submit, t('.sign_up'), class: 'btn btn-success'
```

Notice that we are pulling and displaying *all* the available roles. This will include the `admin` role, which you might not want. This can easily be solved using the handy [where.not](https://robots.thoughtbot.com/activerecords-wherenot):

```haml
= f.input :roles, as: :radio_buttons, collection: Role.where.not(name: 'admin'), value_method: :name, required: true
```

Additionally, the `value_method` is very important. We will use the role's name to pass as a parameter value to the Devise controller. This will allow for easier adding of the role to the user.

## Customizing the Devise Controller

When the form is submitted by the user, it will go through Devise's registration controller, which will proceed to do all the registration magic. However, after the user is successfully registered, we want this controller to add the role we passed in the form.

We can begin by explicitely creating this controller and "overwriting" its `create` method:

```ruby
# app/controllers/registrations_controller.rb

class RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]

  # POST /resource
  def create
    super
    resource.add_role(params[:user][:roles])
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [roles: []])
  end

end
```

Technically we aren't really *overwriting* the controller, since the controller's original create method is still being called by using the `super` keyword. After this is done, we proceed to add the role.

If you are passing many roles (checkboxes) to the controller as parameters, you will need to adjust this part accordingly.

Lastly we also sanitize this extra `roles` parameter inside a protected method.

### Don't Forget the Routes

We will need to edit the devise route to point to this new registrations controller we created:

```ruby
# routes.rb

Rails.application.routes.draw do

  devise_for :users, controllers: { registrations: 'registrations' }

end

```

And that's it! The selected role in the form should now be properly added to the newly registered user upon successful registration. The best part of all is that we do not need to re-write the registration controller's create logic thanks to the handy `super`.