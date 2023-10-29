load("//private:provider.bzl", "ContractInfo")

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