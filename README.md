<!-- Generated with Stardoc: http://skydoc.bazel.build -->

# rules_pact
Bazel rules to test services interactions with [pacts][pactsws]

[pactsws]: https://docs.pact.io/

## MODULE.bazel
```starlark
bazel_dep(name = "rules_pact", version = "1.0.0")
archive_override(
    module_name = "rules_pact",
    urls = ["https://github.com/opicaud/rules_pact/archive/refs/tags/v1.0.0.tar.gz"],
    strip_prefix = "rules_pact-1.0.0",
    integrity = "sha256-GqWy8GzwY7RHhmt2lVRSQ2absC3Z5rnP698foezdfY8=",
)
```

## Usage
You can find this full example inside this [repository](https://github.com/opicaud/monorepo)

Start to declare a consumer:
```starlark
consumer(
    name = "area-calculator-grpc",
    testonly = True,
    srcs = ":consumer_test",
    data = ["//events/eventstore/grpc/proto:protodef"],
    visibility = ["//visibility:public"],
)
```
``srcs = ":consumer_test"`` contains the implementation of the pact-test, in your favourite language :), see this [example](https://github.com/opicaud/monorepo/blob/main/shape-app/domain/internal/BUILD.bazel) with go

Then declare a provider:
```starlark
provider(
    name = "area-calculator-provider",
    srcs = ":cmd",
    opts = {
        "transport": "grpc",
        "port": "50051",
    },
    visibility = ["//visibility:public"],
    deps = [":proxy"],
)
```
use ``opts`` rule attribute to declare some options used by the toolchain [pact_verifier_cli](https://github.com/pact-foundation/pact-reference/blob/master/rust/pact_verifier_cli/README.md)

If needed, declare a side_car with the provider (proxy / state-manager /...) and bind it as a deps to your provider

Example of a http proxy side_car
```starlark
side_car(
    name = "proxy",
    srcs = "//shape-app/api/proxy",
    health_check = "http://localhost:8080/healthz"
)
```
Example of a state-manager side_car:
```starlark
side_car(
    name = "side_car",
    srcs = "//events/eventstore/grpc/test/helper",
    opts = {
        "state-change-url": "http://localhost:8081/event",
        "state-change-teardown": "true",
    },
    env = {
        "CONFIG": "$(location //events/eventstore/grpc/test/helper:config)",
    },
    data = ["//events/eventstore/grpc/test/helper:config"],
    health_check = "http://localhost:8081/healthz"
)
```
Then declare your pact_test:
```starlark
pact_test(
    name = "pact_test",
    testonly = True,
    consumer = "//shape-app/api/pacts:grpc-consumer-go",
    provider = ":area-calculator-provider",
)
```

The ``pact_test`` rule will run the consumer to create the contract if tests are green.
Then it will run the provider against the contract via [pact_verifier_cli](https://github.com/pact-foundation/pact-reference/blob/master/rust/pact_verifier_cli/README.md) with the help of the ``side_car``

## Toolchains

| toolchain            | os        | cpu   | version (default) |
|----------------------|-----------|-------|-------------------|
| pact_verifier_cli    | osx;linux | amd64 |  1.0.1            |
| pact_protobuf_plugin | osx;linux | amd64 |  0.3.5            |
| libpact_ffi          | osx;linux | amd64 |  0.4.9            |

NB: it's possible to embed libpact_ffi to create an hermetic build, like this [example](https://github.com/opicaud/monorepo/blob/main/pact-helper/pact_ffi.patch), by applying a patch.

## Rules
- [consumer](#consumer)
- [provider](#provider)
- [side_car](#side_car)
- [pact_test](#pact_test)
- [pact_reference_toolchain](#pact_reference_toolchain)
- [pact_protobuf_plugin_toolchain](#pact_protobuf_plugin_toolchain)

<a id="consumer"></a>

## consumer

<pre>
consumer(<a href="#consumer-name">name</a>, <a href="#consumer-srcs">srcs</a>, <a href="#consumer-data">data</a>)
</pre>

Rule that wrap consumer interaction.
It executes the test provided in srcs attribute through the toolchain.
This rule will be executed from the pact_test rule.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="consumer-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="consumer-srcs"></a>srcs |  a test target   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="consumer-data"></a>data |  data useful to provide with test target   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |


<a id="pact_protobuf_plugin_toolchain"></a>

## pact_protobuf_plugin_toolchain

<pre>
pact_protobuf_plugin_toolchain(<a href="#pact_protobuf_plugin_toolchain-name">name</a>, <a href="#pact_protobuf_plugin_toolchain-manifest">manifest</a>, <a href="#pact_protobuf_plugin_toolchain-protobuf_plugin">protobuf_plugin</a>)
</pre>

A pact protobuf plugin toolchain

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="pact_protobuf_plugin_toolchain-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="pact_protobuf_plugin_toolchain-manifest"></a>manifest |  A json manifest   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="pact_protobuf_plugin_toolchain-protobuf_plugin"></a>protobuf_plugin |  A pact protobuf plugin binary   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="pact_reference_toolchain"></a>

## pact_reference_toolchain

<pre>
pact_reference_toolchain(<a href="#pact_reference_toolchain-name">name</a>, <a href="#pact_reference_toolchain-libpact_ffi">libpact_ffi</a>, <a href="#pact_reference_toolchain-pact_verifier_cli">pact_verifier_cli</a>)
</pre>

A pact reference toolchain

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="pact_reference_toolchain-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="pact_reference_toolchain-libpact_ffi"></a>libpact_ffi |  A pact ffi library   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="pact_reference_toolchain-pact_verifier_cli"></a>pact_verifier_cli |  A pact reference binary   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="pact_test"></a>

## pact_test

<pre>
pact_test(<a href="#pact_test-name">name</a>, <a href="#pact_test-consumer">consumer</a>, <a href="#pact_test-provider">provider</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="pact_test-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="pact_test-consumer"></a>consumer |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="pact_test-provider"></a>provider |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |


<a id="provider"></a>

## provider

<pre>
provider(<a href="#provider-name">name</a>, <a href="#provider-deps">deps</a>, <a href="#provider-srcs">srcs</a>, <a href="#provider-opts">opts</a>)
</pre>

Rule that describe provider interaction

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="provider-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="provider-deps"></a>deps |  any useful dep to run with the provider like a state-manager, a proxy or a side-car   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="provider-srcs"></a>srcs |  the provider to run   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="provider-opts"></a>opts |  options to provide to pact_verifier_cli   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional |  `{}`  |


<a id="side_car"></a>

## side_car

<pre>
side_car(<a href="#side_car-name">name</a>, <a href="#side_car-srcs">srcs</a>, <a href="#side_car-data">data</a>, <a href="#side_car-env">env</a>, <a href="#side_car-health_check">health_check</a>, <a href="#side_car-opts">opts</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="side_car-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="side_car-srcs"></a>srcs |  the side-car to run   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="side_car-data"></a>data |  any data useful to run with the side-car, like a configuration file for instance   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="side_car-env"></a>env |  any environment variable to provide with the side_car   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional |  `{}`  |
| <a id="side_car-health_check"></a>health_check |  uri to curl before launching provider test   | String | optional |  `"nop"`  |
| <a id="side_car-opts"></a>opts |  the option specific to the side-car   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional |  `{}`  |


