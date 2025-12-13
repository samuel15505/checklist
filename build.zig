const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const lib = b.addLibrary(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .optimize = optimize,
            .target = target,
        }),
        .name = "checklist",
    });

    const exe = b.addExecutable(.{
        .name = "checklist",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .optimize = optimize,
            .target = target,
        }),
    });

    exe.root_module.addImport("libchecklist", lib.root_module);
    exe.step.dependOn(&lib.step);

    b.installArtifact(exe);
    b.installArtifact(lib);

    const run_step = b.step("run", "Run the app.");
    const run_exe = b.addRunArtifact(exe);
    run_exe.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_exe.addArgs(args);
    }

    run_step.dependOn(&run_exe.step);

    const test_step = b.step("test", "Test artifacts.");
    const test_exe = b.addTest(.{
        .root_module = exe.root_module,
    });
    const test_lib = b.addTest(.{
        .root_module = lib.root_module,
    });

    test_step.dependOn(&b.addRunArtifact(test_exe).step);
    test_step.dependOn(&b.addRunArtifact(test_lib).step);

    const exe_check = b.addExecutable(.{
        .root_module = exe.root_module,
        .name = "exe_check",
    });

    const lib_check = b.addLibrary(.{
        .root_module = lib.root_module,
        .name = "exe_check",
    });

    const check = b.step("check", "Check if build compiles");
    check.dependOn(&exe_check.step);
    check.dependOn(&lib_check.step);
}
