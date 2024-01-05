load("//private:provider.bzl", "SideCarInfo", "ContractInfo")

def _provider_impl(ctx):
    args = ctx.actions.args()
    cli_args = ctx.actions.declare_file("cli_args")
    for k, v in ctx.attr.opts.items():
        args.add("--"+k, v)
    ctx.actions.write(cli_args, args)

    runfiles = ctx.runfiles(files = [cli_args] +
        ctx.attr.srcs[DefaultInfo].default_runfiles.files.to_list()
    )

    if ctx.attr.deps == []:
        return [DefaultInfo(runfiles = runfiles),
                SideCarInfo(file = "nop"),
                ContractInfo(name = ctx.attr.name)]

    for dep in ctx.attr.deps:
        runfiles = runfiles.merge(dep[DefaultInfo].default_runfiles)

    return [DefaultInfo(runfiles = runfiles),
            SideCarInfo(file = dep[SideCarInfo].file),
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
            providers = [SideCarInfo],
            doc="any useful dep to run with the provider like a state-manager, a proxy or a side-car"
        ),
    },
)