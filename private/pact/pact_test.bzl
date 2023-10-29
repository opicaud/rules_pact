load("//private:provider.bzl", "ExampleInfo", "ContractInfo")


script_template="""\
#!/bin/bash
_healthCheck () {{
    echo "starting health check of $2"
    healthy="503"
    if [ $1 == "nop" ]; then healthy="200" && echo "health check ignored"; fi
    attempt=0
    until [ $healthy = "200" ]
    do
     healthy=$(curl -s -o /dev/null -w "%{{http_code}}" $1)
     echo "health check of $2 not ok, will recheck in 1 sec.."
     sleep 1
    done
}}
pwd
cp {libpact_ffi} $(dirname $(dirname {run_consumer_test}))
cp {libpact_ffi} .
ls .
echo "### Running Consumers Tests ###"
mkdir -p protobuf-0.3.5
cp {manifest} protobuf-0.3.5
cp {plugin} pact-protobuf-plugin
mv pact-protobuf-plugin protobuf-0.3.5
export PACT_PLUGIN_DIR=$(pwd)
./{run_consumer_test}
ls shape-app/api/pacts/
echo "### Running Providers Tests ###"
contract=$(dirname $(dirname {run_consumer_test}))/pacts/{contract}.json
pact_verifier_cli_args=$(cat {pact_verifier_cli_opts} || echo "--help")
side_car_cli_args=$(cat {side_car_opts} || echo "")
cli_args="$side_car_cli_args -f $contract $pact_verifier_cli_args"
echo $cli_args
while read first_line; read second_line
do
    export "$first_line"="$second_line"
done < {env_side_car}
nohup {provider_bin} &
echo "Provider started.."
nohup {side_car_bin} &
echo "State manager started.."
_healthCheck $(cat {health_check_side_car}) "side_car"
echo "Now running provider on $contract"
./{pact_verifier_cli} $cli_args
"""

def pact_test(**kwargs):
    print(kwargs)
    _consumer = kwargs["consumer"]
    _provider = kwargs["provider"]
    _pact_test(
        name = kwargs["name"],
        consumer = _consumer,
        provider = _provider,
    )

def _impl(ctx):
    pact_plugins = ctx.toolchains["@rules_pact//:pact_protobuf_plugin_toolchain_type"]
    pact_reference = ctx.toolchains["@rules_pact//:pact_reference_toolchain_type"]
    consumer = ctx.attr.consumer[DefaultInfo].default_runfiles.files.to_list()
    provider = ctx.attr.provider[DefaultInfo].default_runfiles.files.to_list()
    dict = {}
    for p in provider:
        dict.update({p.basename: p.short_path})
        if ctx.attr.provider[ExampleInfo].file == p.basename:
            dict.update({ctx.attr.provider[ExampleInfo].file: p.short_path})
        dict.update({"contract": ctx.attr.consumer[ContractInfo].name + "-" + ctx.attr.provider[ContractInfo].name})
    script_content = script_template.format(
        manifest = pact_plugins.manifest.short_path,
        plugin = pact_plugins.protobuf_plugin.short_path,
        run_consumer_test = consumer[0].short_path,
        libpact_ffi = pact_reference.libpact_ffi.short_path,
        pact_verifier_cli = pact_reference.pact_verifier_cli.short_path,
        pact_verifier_cli_opts = dict.setdefault("cli_args", "nop"),
        side_car_opts = dict.setdefault("side_car_cli_args", "nop"),
        provider_bin = dict.setdefault("cmd", "nop"),
        side_car_bin = dict.setdefault(ctx.attr.provider[ExampleInfo].file, "nop"),
        env_side_car = dict.setdefault("env_side_car","nop"),
        health_check_side_car = dict.setdefault("health_check_side_car", "nop"),
        contract = dict.setdefault("contract", "nop")
    )
    ctx.actions.write(ctx.outputs.executable, script_content)
    runfiles = ctx.runfiles(files = consumer + [pact_plugins.manifest, pact_plugins.protobuf_plugin, pact_reference.pact_verifier_cli, pact_reference.libpact_ffi, consumer[1]] + provider)

    return [DefaultInfo(runfiles = runfiles)]

_pact_test = rule(
    implementation = _impl,
    attrs = {
        "consumer": attr.label(),
        "provider": attr.label()
    },
    toolchains = ["@rules_pact//:pact_reference_toolchain_type", "@rules_pact//:pact_protobuf_plugin_toolchain_type"],
    test = True,
)