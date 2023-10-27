"""# rules_pact
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
"""
load("@rules_pact//private:toolchains.bzl", _pact_reference_toolchain = "pact_reference_toolchain", _pact_protobuf_plugin_toolchain = "pact_protobuf_plugin_toolchain")
load("@rules_pact//private:consumer.bzl", _pact_test = "pact_test", _consumer = "consumer", _provider = "provider", _side_car = "side_car")

pact_reference_toolchain = _pact_reference_toolchain
pact_protobuf_plugin_toolchain = _pact_protobuf_plugin_toolchain
pact_test = _pact_test
consumer = _consumer
provider = _provider
side_car = _side_car