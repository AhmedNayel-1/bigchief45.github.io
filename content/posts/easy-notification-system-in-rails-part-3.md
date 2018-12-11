---
date: '2017-09-12'
tags:
- ruby
- rails
- coffeescript
- javascript
- web dev
title: Easy Notification System in Rails Part 3
---

*Read [part 1](/posts/easy-notification-system-in-rails.html) and [part 2](/posts/easy-notification-system-in-rails-part-2.html) of this series*

In this post, we will be sending automatic e-emails every time notifications are created.

## Creating the Mailer

We will work with one [mailer](http://guides.rubyonrails.org/action_mailer_basics.html) that will send e-mails for every notification that is created. We can generate our mailer with this command:

```
rails g mailer NotificationsMailer
```

Our mailer will contain an action for each notifiable type that works with notifications in our application. In this series, we've been using **comments** and **posts** as examples.

<!--more-->

Therefore, we can create an action for each:

```ruby
# app/mailers/notifications_mailer.rb

class NotificationsMailer < ApplicationMailer
  before_action { @notification = params[:notification] }

  default from: 'youremail@yourdomain.com'

  def post_notification
    @recipient = @notification.recipient
    @url = post_url(@notification.notifiable)

    mail(to: @recipient.email, subject: t('email.notifications.subject'))
  end

  def comment_notification
    @recipient = @notification.recipient
    @url = post_url(@notification.notifiable.post)

    mail(to: @recipient.email, subject: t('email.notifications.subject'))
  end

end
```

Notice that we are using a new Rails 5.1 [ActionMailer::Parameterized](http://edgeapi.rubyonrails.org/classes/ActionMailer/Parameterized.html) feature. This allows us to use a `before_action` to set instance variables before all actions, similar to controllers. These parameters will then be manually passed when the mailer is called.

### Mailer Views

Let's go ahead and build the mailer's views. For each mailer action, we must create a HTML view and a plain text view with the same name. Here is an example view for posts mail:

```haml
-# app/views/notifications_mailer/post_notification.html.haml

!!!
%html
  %head
    %meta{:content => "text/html; charset=UTF-8", "http-equiv" => "Content-Type"}
  %body
    %p
      %strong #{@notification.actor.full_name}
      = t("notifications.actions.#{@notification.action}")
      a new post titled
      %strong= @notification.notifiable.title

    %p= simple_format h @notification.notifiable.description

    %hr

    = link_to 'View in application', @url
```

Notice how I am using I18n to localize and internationalize some strings using the `t()` method in the mailer actions and views. You can discard this and simply enter a hardcoded string if you want.

## Sending the E-mails

We will be using again ActiveRecord callbacks on our Notification model to send the e-mail:

```ruby
# app/models/notification.rb

class Notification < ApplicationRecord
  # ...

  after_create :mail_notification

  private

  def mail_notification
    action = (self.notifiable_type.underscore + '_notification').to_sym

    NotificationMailer.with(notification: self).send(action).deliver_now
  end

end
```

With the `after_create` callback, after the notification object is persisted in the database, Raisl will proceed to call the `mail_notification` method. In this method we will use the notification's `notifiable_type` attribute to form an underscored string that should match the corresponding *action** in the mailer (`post_notification`, `comment_notification`, or any other actions added in the future), represented by a Ruby symbol.

Next we proceed to call the mailer to send the e-mail. We use the `with` method to manually pass in the notification as a parameter, as mentioned before. We then use the Ruby method **send** to call the corresponding mailer action based on the symbol we constructed.

~> One downside of using an ActiveRecord callback in this situation is that your application will send e-mails for every notification object created in your application. This may be exactly what you want, but this also means that e-mails will also be sent when creating notifications using the Rails console, or when seeding the database with test data.

## Other Enhancements

You can also pretty up your HTML emails by using a framework such as [Foundation for E-mails](https://www.driftingruby.com/episodes/mail-previews-and-templates)

## References