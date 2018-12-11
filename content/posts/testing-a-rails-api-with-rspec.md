---
date: '2017-05-15'
tags:
- rails
- ruby
- tdd
- bdd
- rspec
- json
title: Testing a Rails API With RSpec
---

As I continue to improve me API testing skills in Rails, I have come to point where I really feel comfortable with all the tools I need to correctly add useful tests to my API. This post explains how I usually test my Rails APIs using RSpec.

## Setting Up the Necessary Tools

In addition to RSpec, there are a few tools that make my testing experience much easier. These are:

- [Factory Girl](https://github.com/thoughtbot/factory_girl_rails)
- [Faker](https://github.com/stympy/faker)
- [Shoulda Matchers](https://github.com/thoughtbot/shoulda-matchers)
- [Database Cleaner](https://github.com/DatabaseCleaner/database_cleaner)

After Adding these gems to the Gemfile. I proceed to create a `/support` directory under the `/spec` directory. This directory will contain the additional configuration of the above tools, as well as some helper definitions that our specs will use.

**/spec/support/shoulda.rb**:

```ruby
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    # Choose a test framework:
    with.test_framework :rspec

    # Or, choose the following (which implies all of the above):
    with.library :rails
  end
end
```

<!--more-->

**/spec/support/database_cleaner.rb**:

```ruby
RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
```

It will also be necessary that we make RSpec Rails recognize the above configurations:

**/spec/rails_helper.rb**:

```ruby
# Add additional requires below this line. Rails is not loaded until this point!
require 'shoulda/matchers'
require 'support/shoulda'
require 'support/database_cleaner'
```

Perfect. With this setup we are ready to dive into the specs.

## Model Specs

Model specs in a Rails API don't really differ much from the model specs of a typical Rails application. Still, I am including here for completeness. Notice how `shoulda_matchers` greatly reduce the code in the specs, and improves readability:

**/spec/models/user_spec.rb**:

```ruby
require 'rails_helper'

RSpec.describe User, type: :model do

  it 'has a valid factory' do
    expect(FactoryGirl.create(:user)).to be_valid
  end

  context 'validations' do
    it { is_expected.to validate_presence_of :email }
    it { is_expected.to validate_uniqueness_of :email }
    it { is_expected.to validate_confirmation_of :password }
    it { is_expected.to validate_presence_of :first_name }
    it { is_expected.to validate_presence_of :last_name }
  end
end
```

## Routing Specs

You should not really bother creating tests for REST routes in a Rails API. A Rails `--api` application will automatically **not** include `new` and `edit` routes in your routes configuration. So there is no need to test that these routes are effectively not routable.

However, this is a good place to test additional non REST-ful routes. For example, an authentication endpoint that returns a JSON Web Token (JWT):

**/spec/routing/authentication\_routing\_spec.rb**:

```ruby
require 'rails_helper'

RSpec.describe Api::V1::AuthenticationController, type: :routing do
  describe 'authentication routing' do
    it 'routes to /v1/auth to user_token#create' do
      expect(:post => '/v1/auth').to route_to('api/v1/user_token#create')
    end
  end
end
```

In the example above I am using the [Knock](https://github.com/nsarno/knock) gem to easily implement JWT authentication in the application.

## Request Specs

In my Rails APIs, controller specs are completely replaced by **request specs**. This is because request specs directly hit the API endpoints and simulates how users would actually interact with the API, without worrying about the controller behavior.

Let's take a look at an example spec for a `GET /users` request:

**/spec/requests/users_spec.rb**:

```ruby
describe 'GET /v1/users' do
  let!(:users) { FactoryGirl.create_list(:user, 10) }

  before { get '/v1/users', headers: { 'Accept': 'application/vnd' } }

  it 'returns HTTP status 200' do
    expect(response).to have_http_status 200
  end

  it 'returns all users' do
    body = JSON.parse(response.body)
    expect(body['data'].size).to eq(10)
  end
end
```

I've seen many request spec examples use multiple expectations for each example. I prefer creating multiple examples with only one expectation for each. In the example above, we have two examples.

Additionally, the actual request is done in a `before` block so that we can separate the expectations accross multiple examples. This will slow down the test suite a bit, however.

### DRY-ing The JSON Response

In request specs, it is very common to see the response being parsed and asserted like this:

```ruby
body = JSON.parse(response.body)
user_email = body['data']['attributes']['email']

expect(user_email).to eq 'pabloescobar@domain.com'
```

Writing each example that way can get tiring really fast. We can nicely DRY it up by creating a helper method in a new module. This can be created in the `/support` directory:

**/spec/support/request_helpers.rb**:

```ruby
module Request
  module JsonHelpers
    def json_response
      @json_response ||= JSON.parse(response.body, symbolize_names: true)
    end
  end
end
```

Then include it in the RSpec configuration:

**/spec/rails_helper.rb**:

```ruby
require 'support/request_helpers'

# ...

config.include Request::JsonHelpers, type: :request
```

Our helper provides a `json_response` method that will return the parsed response. It can also take an option `symbolize_names` if you want to use symbols instead of strings or vice-versa. Now we can re-write the examples like this (using symbols):

```ruby
it 'returns all users' do
  expect(json_response[:data].size).to eq(10)
end

it 'returns the requested user' do
  expect(json_response[:data][:attributes][:email]).to eq('james@text.com')
end
```

### Request Headers

It is important to include the correct headers in our request specs. Otherwise you could be seeing mischievous failing tests. When using the [JSON API](http://jsonapi.org/) specification, I use the following headers for `GET` requests:

```ruby
before { get '/v1/users', headers: { 'Accept': 'application/vnd' } }
```

For `POST`, `PUT`, and `PATCH`:

```ruby
post '/v1/users', params: new_user.to_json, headers: { 'Accept': 'application/vnd', 'Content-Type': 'application/vnd.api+json' }
```

### JWT Authentication Helper

When using the Knock gem, a JWT token must be passed via the request headers when requesting endpoints that require authentication. Like this:

```
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9
GET /my_resources
```

We can create a helper that returns this additional header along with the token, so that it can be used in the request specs. We can add a new module to the `Request` module we just created in `/spec/support/request_helpers.rb`:

**/spec/support/request_helpers.rb**:

```ruby
module Request
  # ...

  module AuthHelpers
    def auth_headers(user)
      token = Knock::AuthToken.new(payload: { sub: user.id }).token
      {
        'Authorization': "Bearer #{token}"
      }
    end
  end
end
```

Likewise, we must include it in `rails_helper.rb`:

```ruby
# ...
config.include Request::AuthHelpers, type: :request
```

Then in our request specs, we can use it in the following way:

```ruby
describe 'GET /v1/users' do
  let!(:users) { FactoryGirl.create_list(:user, 10) }

  before { get '/v1/users', headers: auth_headers(current_user) }

  it 'returns HTTP status 200' do
    expect(response).to have_http_status 200
  end
end
```

Of course, you will also have to add the other headers I previously mentioned.

## Conclusion

And there it is. Simple yet effective tests that should give you confidence that your API is working the way you expect it to.

I hope I can update this article in the future and include other topics such as more complex Factory Girl factories, among other things.

## References

- http://www.betterspecs.org/
- https://www.learnhowtoprogram.com/rails/building-an-api/testing-a-rails-api