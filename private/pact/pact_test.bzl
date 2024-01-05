load("//private:provider.bzl", "SideCarInfo", "ContractInfo", "ProviderInfo")

def pact_test(**kwargs):
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
    debug = "op"
    if ctx.attr.debug == True:
        debug = "nop"
    dict = {}
    script = ctx.actions.declare_file(ctx.label.name + ".sh")
    for p in provider:
        dict.update({p.basename: p.short_path})
        if ctx.attr.provider[SideCarInfo].file == p.basename:
            dict.update({ctx.attr.provider[SideCarInfo].file: p.short_path})
        if ctx.attr.provider[ProviderInfo].file == p.basename:
            dict.update({ctx.attr.provider[SideCarInfo].file: p.short_path})
        dict.update({"contract": ctx.attr.consumer[ContractInfo].name + "-" + ctx.attr.provider[ContractInfo].name})
    ctx.actions.expand_template(
            template = ctx.file._script,
            output = script,
            substitutions = {
                "{debug}": debug,
                "{manifest}": pact_plugins.manifest.short_path,
                "{plugin}": pact_plugins.protobuf_plugin.short_path,
                "{run_consumer_test}": consumer[0].short_path,
                "{libpact_ffi}": pact_reference.libpact_ffi.short_path,
                "{pact_verifier_cli}": pact_reference.pact_verifier_cli.short_path,
                "{pact_verifier_cli_opts}": dict.setdefault("cli_args", "nop"),
                "{side_car_opts}": dict.setdefault("side_car_cli_args", "nop"),
                "{provider_bin}": dict.setdefault(ctx.attr.provider[ProviderInfo].file, "nop"),
                "{side_car_bin}": dict.setdefault(ctx.attr.provider[SideCarInfo].file, "nop"),
                "{env_side_car}": dict.setdefault("env_side_car","nop"),
                "{health_check_side_car}": dict.setdefault("health_check_side_car", "nop"),
                "{contract}": dict.setdefault("contract", "nop")
            },
            is_executable = True,
    )

    ctx.actions.write(ctx.outputs.executable, script.short_path)
    runfiles = ctx.runfiles(files = consumer + [script, pact_plugins.manifest, pact_plugins.protobuf_plugin, pact_reference.pact_verifier_cli, pact_reference.libpact_ffi, consumer[1]] + provider)

    return [DefaultInfo(runfiles = runfiles)]

_pact_test = rule(
    implementation = _impl,
    attrs = {
        "consumer": attr.label(),
        "provider": attr.label(),
        "debug": attr.bool(default = False),
        "_script" : attr.label(default = Label("//private/pact/templates:pact_test.template.sh"),  allow_single_file = True,)
    },
    toolchains = ["@rules_pact//:pact_reference_toolchain_type", "@rules_pact//:pact_protobuf_plugin_toolchain_type"],
    test = True,
)