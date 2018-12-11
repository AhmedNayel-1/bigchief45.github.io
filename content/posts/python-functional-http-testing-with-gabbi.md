---
date: '2017-06-06'
tags:
- python
- gabbi
- gnocchi
- tdd
- bdd
- web-dev
- backend
- yaml
title: Python Functional HTTP Testing With Gabbi
---

Continuing with my journey in contributing to [Gnocchi](http://gnocchi.xyz/index.html), I have learned of an excellent tool which Gnocchi uses to test its API from a HTTP request approach. The tool is called [**Gabbi**](https://github.com/cdent/gabbi).

Coming from a Ruby, Rails, and Rspec background, I was very pleased on learning how Gabbi works and how to use it. Gabbi uses YAML to construct the tests that will hit the API endpoints, in a similar way to using Rspec's DSL when making [request specs](https://github.com/rspec/rspec-rails#request-specs).

For my latest contribution to Gnocchi, I was working on an [issue](https://github.com/gnocchixyz/gnocchi/issues/12) where newly created metrics were not being returned in the response from `/v1/resource/generic/:id/metric`. After applying the fixes and submitting the patch, it was also necessary to update some of the functional Gabbi tests that belong to this specific use case.

One of these original tests is shown below:

<!--more-->

[**gnocchi/tests/functional/gabbits/resource.yaml**](https://github.com/gnocchixyz/gnocchi/blob/master/gnocchi/tests/functional/gabbits/resource.yaml):

```yaml
    - name: post metric at generic
      POST: /v1/resource/generic/85C44741-CC60-4033-804E-2D3098C7D2E9/metric
      request_headers:
          x-user-id: 0fbb231484614b1a80131fc22f6afc9c
          x-project-id: f3d41b770cc14f0bb94a1d5be9c0e3ea
          content-type: application/json
      status: 204
      data:
          electron.spin:
              archive_policy_name: medium
      response_headers:
```

We can see how the request is nicely defined using YAML, specifying required stuff such as the action, request headers, and data.

For the response, we are specifying that it should return a 204 HTTP status code. For [my patch](https://github.com/gnocchixyz/gnocchi/pull/55) I actually had to change the status code to 200.

Additionally, during the code review someone suggested to also test for the response JSON contents of the returned metrics. This is when I learned about the `response_json_paths` expectation, which allows us to access the response's JSON body and assert their content.

For my patch, I simply used this expectation to test against the metric's name and resource id, making the test now look like this:

```yaml
    - name: post metric at generic
      POST: /v1/resource/generic/85C44741-CC60-4033-804E-2D3098C7D2E9/metric
      request_headers:
          x-user-id: 0fbb231484614b1a80131fc22f6afc9c
          x-project-id: f3d41b770cc14f0bb94a1d5be9c0e3ea
          content-type: application/json
      status: 200
      data:
          electron.spin:
              archive_policy_name: medium
      response_headers:
      response_json_paths:
          $[/name][1].name:: electron.spin
          $[/name][1].resource_id: 85C44741-CC60-4033-804E-2D3098C7D2E9
```

Note how we are using `$` and an index `1` to access the response's **first** item in a similar fashion to accessing an array. The response actually return's a JSON array of metrics. Another important thing is that we are sorting the returned metrics by name using `[/name]`, as [documented](http://gabbi.readthedocs.io/en/latest/jsonpath.html) in Gabbi. The reason we do this is because the order of the response's items in Gnocchi's Gabbi tests cannot be predicted.

## References

- [Gabbi documentation](https://gabbi.readthedocs.io/en/latest/index.html)
- [Gabbi Github repository](https://github.com/cdent/gabbi)