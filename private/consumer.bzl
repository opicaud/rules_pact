load(":provider.bzl", "ExampleInfo", "ContractInfo")

def _consumer_impl(ctx):
    srcs = ctx.attr.srcs[DefaultInfo].files_to_run.executable
    runfiles = ctx.runfiles(files = [srcs])
    runfiles = runfiles.merge(ctx.attr.data[0].data_runfiles)
    return [DefaultInfo(runfiles = runfiles),
            ContractInfo(name = ctx.attr.name)]

consumer = rule(
    implementation = _consumer_impl,
    doc = """Rule that wrap consumer interaction.
    It executes the test provided in srcs attribute through the toolchain.
    This rule will be executed from the pact_test rule.
    """,
    attrs = {
        "srcs": attr.label(
            allow_files = True,
            providers = [DefaultInfo],
            doc = "a test target"
        ),
        "data": attr.label_list(
            allow_files = True,
            doc = "data useful to provide with test target"
        ),
    },
)

def _provider_impl(ctx):

    args = ctx.actions.args()
    cli_args = ctx.actions.declare_file("cli_args")
    for k, v in ctx.attr.opts.items():
        args.add("--"+k, v)
    ctx.actions.write(cli_args, args)

    runfiles = ctx.runfiles(files = [cli_args] +
        ctx.attr.srcs[DefaultInfo].default_runfiles.files.to_list()
    )

    for dep in ctx.attr.deps:
        runfiles = runfiles.merge(dep[DefaultInfo].default_runfiles)

    return [DefaultInfo(runfiles = runfiles),
            ExampleInfo(file = dep[ExampleInfo].file),
            ContractInfo(name = ctx.attr.name)]
provider = rule(
    implementation = _provider_impl,
    doc = "Rule that describe provider interaction",
    attrs = {
        "srcs": attr.label(allow_files = True,
            providers = [DefaultInfo],
            doc = "the provider to run"
        ),
        "opts": attr.string_dict(
            doc = "options to provide to pact_verifier_cli"
        ),
        "deps": attr.label_list(
            allow_files = True,
            providers = [ExampleInfo],
            doc="any useful dep to run with the provider like a state-manager, a proxy or a side-car"
        ),
    },
)