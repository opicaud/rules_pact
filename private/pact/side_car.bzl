load("//private:provider.bzl", "SideCarInfo")

def _side_car_impl(ctx):
    args = ctx.actions.args()
    cli_args = ctx.actions.declare_file("side_car_cli_args")
    for k, v in ctx.attr.opts.items():
       args.add("--"+k, v) if k != "state-change-teardown" else args.add("--"+k)

    ctx.actions.write(cli_args, args)
    bin = ctx.attr.srcs[DefaultInfo].files_to_run.executable

    env_args_file = ctx.actions.declare_file("env_side_car")
    env_args = ctx.actions.args()
    for k, v in ctx.attr.env.items():
        path = ctx.expand_location(v, ctx.attr.data)
        env_args.add(k, path)
    ctx.actions.write(env_args_file, env_args)

    health_check_file = ctx.actions.declare_file("health_check_side_car")
    ctx.actions.write(health_check_file, ctx.attr.health_check)

    runfiles = ctx.runfiles(files = [bin, cli_args, env_args_file, health_check_file] + ctx.files.data)
    return [DefaultInfo(runfiles = runfiles),
            SideCarInfo(file = bin.basename)
]

side_car = rule(
    implementation = _side_car_impl,
    attrs = {
        "srcs": attr.label(allow_files = True, providers = [DefaultInfo], doc = "the side-car to run"),
        "opts": attr.string_dict(
            doc = "the option specific to the side-car"
        ),
        "env": attr.string_dict(
            doc = "any environment variable to provide with the side_car"
        ),
        "data": attr.label_list(
            allow_files = True,
            doc = "any data useful to run with the side-car, like a configuration file for instance"
        ),
        "health_check": attr.string(default = "nop", doc = "uri to curl before launching provider test")
    },
)