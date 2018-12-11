---
date: '2017-03-29'
tags:
- ruby
- rails
- programming
- web dev
- bootstrap
title: Using Objects and Ranges With Cases in Ruby
---

Ruby's [`case` statement](http://www.techotopia.com/index.php/The_Ruby_case_Statement) provides some nice functionality to be used with objects and ranges. I was recently developing a small application in Ruby on Rails using blood test data where I had to check if a certain test item (i.e. HDL Cholesterol) value belonged to a certain range. I did not want to use a bunch of `if` statements and I actually found a pretty neat way to implement using the Ruby `case`.

In my application I have a Rails model called `Entry` which represents a blood test result with a lot of field data such as blood glucose level, blood pressure level, etc. etc. I want to display this data in the view using Bootstrap 3's nice [progress bars](http://getbootstrap.com/components/#progress) and I want the progress bar's contextual class to be changed and determined by the range in which this data point sits in.

If we take [total cholesterol](https://en.wikipedia.org/wiki/Cholesterol) as an example, a quick Google search indicates that an ideal value would be less than 200 mg/dL, a high value (not good) would be between 200-239 mg/dL, and a very high value (definitely not good) would be above 240 mg/dL.

To implement this, I created a `Recommendations` module under the `/models` directory. All classes belonging to this module will have different ranges to represent what I explained above. This is what the model directory tree looks like:

```
app/models/
├── application_record.rb
├── concerns
├── entry.rb
├── recommendations
│   ├── blood_glucose.rb
│   ├── diastolic_pressure.rb
│   ├── hdl.rb
│   ├── ldl.rb
│   ├── systolic_pressure.rb
│   └── total_cholesterol.rb
└── user.rb
```

<!--more-->

If we pick one of those PORO (Plain Old Ruby Object) classes, it looks something like this:

```ruby
module Recommendations
  class TotalCholesterol
    def self.info
    end

    def self.ideal
      (0..200)
    end

    def self.warning
      (200..239)
    end

    def self.danger
      (240..300)
    end

    def self.top
      300
    end
  end
end
```

Notice that the class simply consists of **class methods** that return a range. We will now use these methods along with the `case` statement in some helpers that we will define to be used on the view. We can define this in `EntriesHelper` module (`app/helpers/entries_helper.rb`):

```ruby
module EntriesHelper

  def progress_bar_color(item, current_value)
    # 'item' is a class of the Recommendations module which represents
    # a test result item (i.e Systolic Blood Pressure)
    case current_value
      when item.ideal then 'progress-bar-success'
      when item.info then 'progress-bar-info'
      when item.warning then 'progress-bar-warning'
      when item.danger then 'progress-bar-danger'
    end
  end

  def progress_bar_width(item, current_value)
    (current_value / item.top ) * 100
  end

end

```

In the code above, the `progress_bar_color` method shows the magic of using the `case` statement with a current value to determine if it is inside a range, by simply using the `when` statement with a class method. By comparing to different ranges we simply return a different contextual CSS class for the progress bar.

The second method is simply for setting an appropriate width for the progress bar. This one uses an additional class method called `top`, which simply returns an integer that should represent the end of the bar. A percentage between this integer and the current data point is calculated.

We can then use these helper methods when setting the progress bar's class and width like this (using [HAML](http://haml.info/)):

```haml
.progress-bar{class: "#{progress_bar_color(Recommendations::DiastolicPressure, @entry.diastolic_blood_pressure)}", 'aria-valuenow': @entry.diastolic_blood_pressure, 'aria-valuemin': '0', 'aria-valuemax': '100', style: "width: #{progress_bar_width(Recommendations::DiastolicPressure, @entry.diastolic_blood_pressure)}%;" }
```

Using this implementation in the view with the rest of the data points, we obtain some nice progress bars that will automatically have a good contextual class to represent the severity (or lack thereof) of a blood test item:

![Progress Bars](/posts/using-objects-and-ranges-with-cases-in-ruby/progress_bars.jpg)

Some nice [Bootstrap popovers](http://getbootstrap.com/javascript/#popovers) can be added to help user understand different optimal and dangerous levels for different items, greatly improving the user interface and experience.