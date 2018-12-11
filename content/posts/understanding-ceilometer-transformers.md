---
date: '2017-04-07'
tags:
- ceilometer
- openstack
- cloudcomputing
- python
title: Understanding Ceilometer Transformers
---

Ceilometer **transformers** are part of the Ceilometer **pipeline**, which is the mechanism by which data is processed. In Ceilometer there is a pipeline for **samples** and a pipeline for **events**.

Configurations for these pipelines can be found in `/etc/ceilometer/pipeline.yaml` and `/etc/ceilometer/event_pipeline.yaml`.

Transformers are responsible for mutating data points and passing them to publishers that will send the data to external systems.

![Ceilometer Pipeline](https://docs.openstack.org/developer/ceilometer/_images/3-Pipeline.png)

Different types of transformers exist to mutate different types of data. The following is a table containing all the available transformer types:

| Name of transformer | Reference name for configuration |
|:--------------------|:--------------------------------:|
| Accumulator | accumulator |
| Aggregator | aggregator |
| Arithmetic | arithmetic |
| Rate of change | rate_of_change |
| Unit conversion | unit_conversion |
| Delta | delta |

Let's take a more detailed look into the accumulator transformer.

<!--more-->

### Accumulator Transformer

This transformer simply caches the samples until enough samples have arrived and then flushes them all down the pipeline at once:

```yaml
transformers:
    - name: "accumulator"
      parameters:
          size: 15
```

## The Source Code

Source code for transfomers is found in [`ceilometer/transformers`](https://github.com/openstack/ceilometer/tree/master/ceilometer/transformer). Base classes are found in the `__init__.py` file:

```python
class TransformerBase(object):
    """Base class for plugins that transform the sample."""

    def __init__(self, **kwargs):
        """Setup transformer.
        Each time a transformed is involved in a pipeline, a new transformer
        instance is created and chained into the pipeline. i.e. transformer
        instance is per pipeline. This helps if transformer need keep some
        cache and per-pipeline information.
        :param kwargs: The parameters that are defined in pipeline config file.
        """
        super(TransformerBase, self).__init__()

    @abc.abstractmethod
    def handle_sample(self, sample):
        """Transform a sample.
        :param sample: A sample.
        """

    @abc.abstractproperty
    def grouping_keys(self):
        """Keys used to group transformer."""

    @staticmethod
    def flush():
        """Flush samples cached previously."""
return []
```

All the methods above are abstract methods (with the exception of `flush()`) that specific transformer classes must implement. For example, note the abstract method `handle_sample`. This is where the transformation of the sample will take place. It's implementation will differ depending on the transformer type.

For example, the class defintion of the accumulator transformer can be found in `accumulator.py`:

```python
from ceilometer import transformer


class TransformerAccumulator(transformer.TransformerBase):
    """Transformer that accumulates samples until a threshold.
    And then flushes them out into the wild.
    """

    grouping_keys = ['resource_id']

    def __init__(self, size=1, **kwargs):
        if size >= 1:
            self.samples = []
        self.size = size
        super(TransformerAccumulator, self).__init__(**kwargs)

    def handle_sample(self, sample):
        if self.size >= 1:
            self.samples.append(sample)
        else:
            return sample

    def flush(self):
        if len(self.samples) >= self.size:
            x = self.samples
            self.samples = []
            return x
return []
```

Notice how it implements `handle_sample`. It is a very simple transformer which keeps appending samples into an array. Once a threshold condition is met (in this case `self.size >= 1`), it will simply return all the samples in the array.

Remember that this `size` variable's value is defined and obtained from the `pipeline.yaml` configuration file in the transformer's definition.

The `flush()` method returns the transformed samples and then empties the transformer's array containing the samples.

After the transformers are done mutating the data, they pass this data to the **publishers**, also part of the Ceilometer pipeline.

![Ceilometer Transformers](https://docs.openstack.org/developer/ceilometer/_images/4-Transformer.png)