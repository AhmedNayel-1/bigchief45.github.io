---
date: '2017-03-07'
tags:
- ruby
- rails
- rspec
- web dev
- travisci
- github
- git
- heroku
title: Integrating TravisCI With Rails and Heroku
---

Adding [TravisCI](https://travis-ci.org/) to your application's deployment flow will enable you to spot any build fails or test fails during deployment without affecting your production environment.

In this post I go over on how to integrate TravisCI with a Rails 4 application that uses Postgresql, Rspec, and is later deployed to Heroku if the Travis build is successful.

## Setting up TravisCI

Assuming you already have an account in TravisCI, look for the Github repository of the Rails application and enable it. Then we will want to add a `.travis.yml` file to the application's root directory with the following contents:

```yaml
language: Ruby
rvm:
  - 2.3.0
```

The configuration above tells TravisCI that our application will use Ruby 2.3.0. Once you commit and push the change above to the master branch, Travis will begin creating the build, which might take a few minutes.

### Configure Postgresql

Seems our Rails application uses Postgresql, we need to configure TravisCI to run our build with a Postgresql database. To do this we will add the following configuration to `.travis.yml`:

```yaml
services:
  - postgresql
```

Then we will add another configuration that will make Travis create a Postgresql database with username `postgres` and blank password for the build:

```yaml
before_script:
  - psql -c 'create database travis_ci_test;' -U postgres
```

<!--more-->

Now in our Rails application's `config/database.yml` we configure our test environment database to use this database:

```yaml
test:
  adapter: postgresql
  database: travis_ci_test
```

Lastly make sure to tell Travis the version of Postgres we are using (Travis uses version 9.1 by default). To find out, first run the following command in your development environment's terminal:

```
psql --version
```

In my case I get the following output:

```
psql (PostgreSQL) 9.3.11
```

I add it to `.travis.yml`:

```yaml
addons:
  postgresql: "9.3"
```

Commit all the changes above and push it to the repository so that Travis can start running a new build. You should see the build pass.

## RSpec

Assuming that our application uses RSpec and has some passing tests, Travis will craete the `travis_ci_test` test database (as specified in `database.yml`) and will then run `rake` in the build. This will begin to run all the RSpec tests. You should be able to see the tests running and passing in the Travis Job Log:

```
$ psql -c 'create database travis_ci_test;' -U postgres

$ bundle exec rake

Running via Spring preloader in process 22684

......

Finished in 0.11929 seconds (files took 6.09 seconds to load)

6 examples, 0 failures

The command "bundle exec rake" exited with 0.

Done. Your build exited with 0.
```

Excellent! However if you now try running `rake` in your development environment you will run into an error:

```
`rescue in connect': FATAL:  database "travis_ci_test" does not exist (ActiveRecord::NoDatabaseError)
```

This is because we changed the configuration for the test database in `database.yml`. Rails cannot find this new database since we have not created it. We can easily create it by running the following command:

```
rake db:test:prepare
```

This will create and prepare a test database called `travis_ci_test`, and while having a development environment test database have this name doesn't really make much sense, it should not interfere with the testing at all. We can go ahead and run `rake` again and see our tests run and pass nicely.

## Integrating With Heroku

Since Travis will automatically run a new build after every new commit or merge in the master branch, it would be nice that our code could get deployed to Heroku automatically if the build passes. We can easily configure this by going to our [Heroku](www.heroku.com) dashboard and selecting our application from the list, and selecting the *Deploy* tab.

In the *Deployment method* section we will select to use Github, since we are pushing all our changes to our Github repository. Let's go ahead and connect it to Github and find our application's Github repository.

![Connect Github to Heroku](/posts/integrating-travisci-with-rails-and-heroku/heroku_github.jpg)

Once it's connected, we can configure automatic deploys with a repository branch. Additionally we want to check the **_Wait for CI to pass before deploy_** option, and voila!

## Adding a Build Badge to the Repository

Finally, let's add a nice build badge to the repository's README file. In the Travis repository dashboard we can already see the badge with our build status:

![Build status](/posts/integrating-travisci-with-rails-and-heroku/build_status.jpg)

If we click on it we can get some generated code in different formats. To add to our README file we will choose the Markdown format. We can then copy the snippet and paste it in the repository's `README.md` file, next to the file's title:

```markdown
# Hourglass [![Build Status](https://travis-ci.org/aalvrz/Hourglass.svg?branch=master)](https://travis-ci.org/aalvrz/Hourglass)
```