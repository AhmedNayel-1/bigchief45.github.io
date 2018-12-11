---
date: '2017-09-05'
tags:
- ruby
- rails
- coffeescript
- javascript
- web dev
title: Easy Notification System in Rails Part 2
---

*Read Part 1 of this series [here](/posts/easy-notification-system-in-rails.html)*

In Part 1 we learned how to setup our models and controllers to create notifications using callbacks in our application. Then we displayed these notifications in a Bootstrap 3 navbar using JQuery written in CoffeeScript.

In this post we will be adding more functionality to our notification system.s

## Mark as Read Feature

We will be adding a feature that allows the current user to mark a notification as read as well as all notifications, in the following manner:

- For a single notification, it should be marked *as read* when it is clicked from the list of notifications.
- For all notifications, they should be marked as read when a specific button is pressed.

### Setting up the Routes

Let's begin adding the necessary routes. In part 1 we defined a `notifications` resource. We will add a [collection](http://guides.rubyonrails.org/routing.html#adding-more-restful-actions) POST route and a [member](http://guides.rubyonrails.org/routing.html#adding-more-restful-actions) POST route of the same name:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # ...

  resources :notifications, only: [:index] do
    post :mark_as_read, on: :collection
    post :mark_as_read, on: :member
  end

end
```

<!--more-->

These routes will create the following endpoints:

```
mark_as_read_notifications POST   /notifications/mark_as_read(.:format)                    notifications#mark_as_read
mark_as_read_notification POST   /notifications/:id/mark_as_read(.:format)               notifications#mark_as_read
```

The **collection** creates `/notifications/mark_as_read`, to be used for *all* notifications. The **member** route creates `/notifications/:id/mark_as_read`, to be used for a *single* notification, with the notification ID being passed in the parameters to the controller.

### The Controller

In Part 1 the notifications controller would fetch the current user's unread notifications. We will also mark notifications as read in the notifications controller. Let's go ahead and create the `mark_as_read` action:

```ruby
# app/controllers/notifications_controller.rb
class NotificationsController < ApplicationController

  # ...

  def mark_as_read
    if params[:id]
      @notification = Notification.find(params[:id])
      @notification.update_attribute(:read_at, Time.zone.now)
    else
      @notifications.update_all(:read_at, Time.zone.now)
    end

    respond_to do |format|
      format.json { render json: { success: true } }
    end
  end

end
```

This `mark_as_read` action will work for *both*, the collection and the member endpoints. The way the action itself will *know* which one is which is by checking for `params[:id]`. This ID will only be passed for the **member** route.

To mark the notification(s) as read, we simply give a value to the `read_at` attribute which was initially `nil`.

### Marking Notifications Using JQuery

Now that the endpoints are ready, we will be making AJAX requests to these endpoints to mark the notifications as read.

#### Marking Single Notifications

If you recall the notifications HTML template we made in Part 1, we gave the `link_to` tag a data attribute:

```haml
#- app/views/notifications/comments/_posted.html.haml

= link_to notification.notifiable, 'data-behavior': 'notification-link', id: notification.id do
  / ...
```

We can use this data attribute in JQuery to assign a click event when the link elements with these attributes are clicked, inside the `handleSuccess` function, at the end:

```coffeescript
# app/assets/javascripts/notifications.coffee

handleSuccess: (data) =>
  # ...

  $("[data-behavior='notification-link']").on 'click', @notificationClick
```

Now we can define this `notificationClick` function as follows:

```coffeescript
# app/assets/javascripts/notifications.coffee

$ ->
  class Notifications
    # ...

    notificationClick: (e) =>
      $.ajax(
        url: "/notifications/#{e.currentTarget.id}/mark_as_read"
        dataType: 'JSON'
        method: 'POST'
      )
```

When the notification's `<a>` element is clicked, the AJAX requet will be fired to the **member** endpoint, hitting the controller's action. At the same time, the user should be redirected to the actual `notification.notifiable` object, specified in the template's `link_to` tag.

#### Marking All Notifications

For this feature, we will change a bit our navbar markup and add a button to the navbar dropdown:

```haml
#- app/views/shared/_navbar.html.haml

            %ul#notifications.dropdown-menu{ 'data-behavior': 'notification-items' }
              %li.dropdown-header.text-uppercase Notifications
              - unless current_user.notifications.unread.empty?
                %li
                  .container-fluid
                    = link_to mark_as_read_notifications_path, method: :post, remote: true, class: 'btn btn-default btn-xs pull-right' do
                      %span.glyphicon.glyphicon-ok
                      Mark all as read
                %li.divider
              - else
                %li
                  .container-fluid
                    %p.text-center.small No new notifications
```

The button is a link to `mark_as_read_notifications_path`, which is the **collection** route. We are specifying a `POST` method, and also (very important) a `remote: true` option which tells rails to handle this request using AJAX. Again, this request will hit the notification controller's `mark_as_read` action to mark **all** notifications as read.

Here is an example of how the notifications dropdown would look with this button:

![Mark as read button](/posts/easy-notification-system-in-rails-part-2/mark_as_read.png)

If you press the button, all the current user's notifications should indeed be marked as read. But the dropdown still remains open, and the notification count badge still shows the same number. We can fix this behavior by creating a "JavaScript view". This is basically just some JavaScript code that we can execute when the controller action is hit.

Before we write the JavaScript however, we must also allow the controller action to respond to JavaScript:

```ruby
# app/controllers/notifications_controller.rb
class NotificationsController < ApplicationController

  # ...

  def mark_as_read
    # ...

    respond_to do |format|
      format.js
      format.json { render json: { success: true } }
    end
  end

end
```

The JSON format was added previously, so you just need to add `format.js`.

Once this is done, we can go ahead and create a "view" in `app/views/notifications/mark_as_read.js.erb`:

```javascript
$('#notifications').dropdown('toggle');
$("[data-behavior='unread-count']").text(0);
```

With this JavaScript we simply toggle the dropdown and set the notification count badge to zero. Easy!

Stay tuned for **Part 3** which I will go over how to test this notification system using RSpec.

## References

1. [Easy Notification System in Rails Part 2](/posts/easy-notification-system-in-rails.html)
2. [In-App Navbar Notifications](https://gorails.com/episodes/in-app-navbar-notifications?autoplay=1)