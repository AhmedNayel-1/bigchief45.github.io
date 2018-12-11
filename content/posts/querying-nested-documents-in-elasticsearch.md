---
date: '2017-10-23'
tags:
- elasticsearch
title: Querying Nested Documents in ElasticSearch
---

The other day I was using ElasticSearch to build an index that would contain book documents. These book documents would then contain many pages, each page indicating its page number in the book, and its content as text, extrated from its own PDF file.

I wanted to perform some queries on a specific book so that ElasticSearch would return all the pages in the book which contained a certain word in its `text` field.

## Nested Documents

ElasticSearch 5 supports [nested documents](). These are internally separate documents that will belong to a certain parent, in this case, a book. Before creating any books, we must first define a [nested object mapping](https://www.elastic.co/guide/en/elasticsearch/guide/current/nested-mapping.html) for the index:

```
PUT /my_index

{
  "mappings": {
    "book": {
      "properties": {
        "pages": {
          "type": "nested",
          "properties": {
            "id":    { "type": "integer"  },
            "text": { "type": "text"  },
          }
        }
      }
    }
  }
}
```

Notice how the mapping is created using a `PUT` request at the **index** level.

<!--more-->

-> We can get the current mapping of the index by doing a `GET` request to `/<index>/_mapping`

### Creating the Books

We can now start creating books along with their own collections of pages (nested documents) with dummy data. Here is an example of one book with a few pages:

```
PUT /my_index/book/1

{
  "title": "Harry Potter and the Chamber of Secrets",
  "pages": [
    {
      "id": 1,
      "text": "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam a metus est. Duis ut est et mi feugiat bibendum feugiat eu tortor. Pellentesque accumsan, eros nec commodo euismod, odio dolor lobortis diam, in pulvinar lacus turpis sed justo. Ut placerat ut nulla sed blandit. Aenean vel turpis erat. Phasellus vehicula laoreet ex, nec dapibus leo tempus vitae. Nulla gravida efficitur metus, in euismod justo placerat sit amet. Maecenas tristique est mauris, sagittis scelerisque turpis suscipit vel. Nullam ultricies sapien sit amet neque aliquam hendrerit sed non nibh."
    },
    {
      "id": 2,
      "text": "Pellentesque facilisis turpis in diam maximus luctus. Mauris leo diam, pellentesque a malesuada vitae, scelerisque at ipsum. Fusce tincidunt neque dui. Nullam ac ex luctus, convallis leo eget, feugiat augue. Cras condimentum, purus eu scelerisque sodales, diam est commodo lectus, at finibus orci turpis nec lectus. Mauris in lectus ut diam finibus pellentesque quis tincidunt urna. Curabitur tristique luctus metus at interdum. Curabitur imperdiet ex vel enim pretium, a convallis velit tempor. Nullam odio eros, tincidunt ut consectetur non, scelerisque eget urna. Fusce placerat dui et odio tempus rutrum. Integer non dui eu ante interdum volutpat. Mauris quis ante sed lacus euismod mattis."
    }
  ]
}
```

Notice that the nested documents are defined as a JSON array. In this example we are using the page's `id` to refer to its page number in the book.

### Querying Book Pages for Ocurrences

Suppose we want to query all pages from a certain book (meaning we already know which book we are working with), we want to find **all pages and only pages** in the book where a certain word or phrase exists.

To do this, we will have to make use of [nested queries](https://www.elastic.co/guide/en/elasticsearch/guide/current/nested-query.html). These will allow us to query the nested documents (pages) in the book. Additionally, we will also have to make use of a [query string](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-query-string-query.html) in order to try to find the substring _inside_ the text, rather than comparing the whole text to the query string:

```json
{
  "_source": false,
  "query": {
    "bool": {
      "must": [
        {
          "term": {
            "_id": "1"
          }
        },
        {
          "nested": {
            "path": "pages",
            "query": {
              "query_string": {
                "query": "luctus",
                "fields": [
                  "pages.text"
                ]
              }
            },
            "inner_hits": {
              "_source": [
                "pages.number"
              ]
            }
          }
        }
      ]
    }
  }
}
```

The query above should only return the 2nd page (page with `id` of `2`), since the 1st page does not contain the `luctus` word.

The `"_source": false` field tells ElasticSearch that we only want the pages in the response, since we do not want the book data in it.

The query is composed of a [Bool Query](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-bool-query.html) that first filters out all books except the book we want to search in (ID of `1`). After the bool query we are inserting a nested query that will search inside the nested documents (pages) for the word `luctus` ocurrences in each page. Notice how we are using a "full path" approach to specify the `text` field in the `page` document.

[Inner_hits](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-inner-hits.html) returns per search hit in the search response additional nested hits that caused a search hit to match in a different scope. In this case we are only interested in the found pages's IDs, since these will represent the page numbers in the book where the word was found.

~> The maximum number of hits returned in `inner_hits` is **3**. By default, the top three matching hits are returned. To retrieve more results, you can specify a `size` option inside the `inner_hits` object of the query. [Read more](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-inner-hits.html#_options)

## References:

1. https://www.spacevatican.org/2012/6/3/fun-with-elasticsearch-s-children-and-nested-documents/
2. https://stackoverflow.com/questions/40779957/elasticsearch-get-only-matching-nested-objects-with-all-top-level-fields-in-se
3. https://stackoverflow.com/questions/46900249/searching-for-nested-documents-on-a-specific-parent/46932687#46932687