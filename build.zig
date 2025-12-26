const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const linkage = b.option(std.builtin.LinkMode, "linkage", "Linkage type for the library") orelse .static;
    const zlib_symbol_prefix = b.option([]const u8, "ZLIB_SYMBOL_PREFIX", "Prefix");
    const with_gzfileop = b.option(bool, "WITH_GZFILEOP ", "Compile with support for gzFile related functions") orelse true;
    const zlib_compat = b.option(bool, "ZLIB_COMPAT", "Compile with zlib compatible API") orelse false;
    const with_all_fallbacks = b.option(bool, "WITH_ALL_FALLBACKS", "Build all generic fallback functions (Useful for Gbench)") orelse false;
    const with_reduced_mem = b.option(bool, "WITH_REDUCED_MEM", "Reduced memory usage for special cases (reduces performance)") orelse false;
    const with_new_strategies = b.option(bool, "WITH_NEW_STRATEGIES", "Use new strategies") orelse true;
    const with_crc32_chorba = b.option(bool, "WITH_CRC32_CHORBA", "Enable optimized CRC32 algorithm Chorba") orelse true;
    const with_runtime_cpu_detection = b.option(bool, "WITH_RUNTIME_CPU_DETECTION", "Build with runtime detection of CPU architecture") orelse true;
    const with_inflate_strict = b.option(bool, "WITH_INFLATE_STRICT", "Build with strict inflate distance checking") orelse false;
    const with_inflate_allow_invalid_dist = b.option(bool, "WITH_INFLATE_ALLOW_INVALID_DIST", "Build with zero fill for inflate invalid distances") orelse false;

    const zlib_ng_dep = b.dependency("zlib-ng", .{});

    const zlib_ng_h = b.addConfigHeader(.{ .style = .{
        .autoconf_at = zlib_ng_dep.path("zlib-ng.h.in"),
    } }, .{
        .ZLIB_SYMBOL_PREFIX = zlib_symbol_prefix,
    });

    const zconf_ng_h = b.addConfigHeader(.{ .style = .{
        .autoconf_at = zlib_ng_dep.path("zconf-ng.h.in"),
    } }, .{});
    const zlib_name_mangling_ng_h = b.addConfigHeader(.{ .style = .{
        .autoconf_at = zlib_ng_dep.path("zlib_name_mangling-ng.h.in"),
    } }, .{
        .ZLIB_SYMBOL_PREFIX = zlib_symbol_prefix,
    });

    const zconf_h = b.addConfigHeader(.{ .style = .{
        .autoconf_at = zlib_ng_dep.path("zconf.h.in"),
    } }, .{});
    const zlib_h = b.addConfigHeader(.{ .style = .{
        .autoconf_at = zlib_ng_dep.path("zlib.h.in"),
    } }, .{
        .ZLIB_SYMBOL_PREFIX = zlib_symbol_prefix,
    });
    const zlib_name_mangling_h = b.addConfigHeader(.{ .style = .{
        .autoconf_at = zlib_ng_dep.path("zlib_name_mangling.h.in"),
    } }, .{
        .ZLIB_SYMBOL_PREFIX = zlib_symbol_prefix,
    });

    const flags = .{""};

    const zlib_ng = b.addLibrary(.{
        .name = "zlib-ng",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
        .linkage = linkage,
    });
    zlib_ng.root_module.addCMacro("HAVE_SYS_AUXV_H", "1");
    zlib_ng.root_module.addCMacro("HAVE_SYS_SDT_H", "1");
    zlib_ng.root_module.addCMacro("HAVE_UNISTD_H", "1");
    zlib_ng.root_module.addCMacro("_LARGEFILE64_SOURCE", "1");
    zlib_ng.root_module.addCMacro("__USE_LARGEFILE64", "1");
    zlib_ng.root_module.addCMacro("HAVE_CPUID_GNU", "1");
    zlib_ng.root_module.addCMacro("HAVE_VISIBILITY_HIDDEN", "1");
    zlib_ng.root_module.addCMacro("HAVE_VISIBILITY_INTERNAL", "1");
    zlib_ng.root_module.addCMacro("HAVE_ATTRIBUTE_ALIGNED", "1");
    zlib_ng.root_module.addCMacro("HAVE_BUILTIN_ASSUME_ALIGNED", "1");
    zlib_ng.root_module.addCMacro("HAVE_BUILTIN_CTZ", "1");
    zlib_ng.root_module.addCMacro("HAVE_BUILTIN_CTZLL", "1");
    if (zlib_compat) {
        zlib_ng.root_module.addCMacro("ZLIB_COMPAT", "1");
    }
    if (with_reduced_mem) {
        zlib_ng.root_module.addCMacro("HASH_SIZE", "32768u");
        zlib_ng.root_module.addCMacro("GZBUFSIZE", "8192");
        zlib_ng.root_module.addCMacro("NO_LIT_MEM", "1");
    }
    if (!with_new_strategies) {
        zlib_ng.root_module.addCMacro("NO_QUICK_STRATEGY", "1");
        zlib_ng.root_module.addCMacro("NO_MEDIUM_STRATEGY", "1");
    }
    if (!with_crc32_chorba) {
        zlib_ng.root_module.addCMacro("WITHOUT_CHORBA", "1");
    }
    if (with_inflate_strict) {
        zlib_ng.root_module.addCMacro("INFLATE_STRICT", "1");
    }
    if (with_inflate_allow_invalid_dist) {
        zlib_ng.root_module.addCMacro("INFLATE_ALLOW_INVALID_DISTANCE_TOOFAR_ARRR", "1");
    }
    zlib_ng.addConfigHeader(zlib_ng_h);
    zlib_ng.addConfigHeader(zconf_ng_h);
    zlib_ng.addConfigHeader(zlib_name_mangling_ng_h);
    zlib_ng.addConfigHeader(zlib_h);
    zlib_ng.addConfigHeader(zconf_h);
    zlib_ng.addConfigHeader(zlib_name_mangling_h);
    zlib_ng.addIncludePath(zlib_ng_dep.path("."));

    zlib_ng.addCSourceFiles(.{
        .root = zlib_ng_dep.path("."),
        .files = &zlib_sources,
        .flags = &flags,
    });
    if (with_gzfileop) {
        zlib_ng.root_module.addCMacro("WITH_GZFILEOP", "1");
        zlib_ng.addCSourceFiles(.{
            .root = zlib_ng_dep.path("."),
            .files = &gzfile_sources,
            .flags = &flags,
        });
        const gzread_c = b.addConfigHeader(.{ .style = .{
            .autoconf_at = zlib_ng_dep.path("gzread.c.in"),
        } }, .{
            .ZLIB_SYMBOL_PREFIX = zlib_symbol_prefix,
        });
        zlib_ng.addCSourceFile(.{
            .file = gzread_c.getOutputFile(),
            .flags = &flags,
            .language = .c,
        });
    }
    if (with_all_fallbacks) {
        zlib_ng.root_module.addCMacro("WITH_ALL_FALLBACKS", "1");
        zlib_ng.addCSourceFiles(.{
            .root = zlib_ng_dep.path("."),
            .files = &fallback_sources,
            .flags = &flags,
        });
    } else {
        zlib_ng.root_module.addCMacro("WITH_OPTIM", "1");
        switch (target.result.cpu.arch) {
            .x86, .x86_64 => {
                zlib_ng.root_module.addCMacro("X86_FEATURES", "1");
                if (with_runtime_cpu_detection) {
                    zlib_ng.addCSourceFiles(.{
                        .root = zlib_ng_dep.path("arch/x86"),
                        .files = &.{"x86_features.c"},
                        .flags = &flags,
                    });
                }
                zlib_ng.addCSourceFiles(.{
                    .root = zlib_ng_dep.path("arch/generic"),
                    .files = &.{
                        "adler32_c.c",
                        "adler32_fold_c.c",
                        "crc32_braid_c.c",
                        "crc32_chorba_c.c",
                        "crc32_fold_c.c",
                    },
                    .flags = &flags,
                });
                const have_sse2 = target.result.cpu.has(.x86, .sse2);
                if (have_sse2) {
                    zlib_ng.root_module.addCMacro("X86_SSE2", "1");
                    zlib_ng.addCSourceFiles(.{
                        .root = zlib_ng_dep.path("arch/x86"),
                        .files = &.{
                            "chunkset_sse2.c",
                            "chorba_sse2.c",
                            "compare256_sse2.c",
                            "slide_hash_sse2.c",
                        },
                        .flags = &flags,
                    });
                }
                const have_sse3 = target.result.cpu.has(.x86, .sse3);
                if (have_sse2 and have_sse3) {
                    zlib_ng.root_module.addCMacro("X86_SSSE3", "1");
                    zlib_ng.addCSourceFiles(.{
                        .root = zlib_ng_dep.path("arch/x86"),
                        .files = &.{
                            "adler32_ssse3.c",
                            "chunkset_ssse3.c",
                        },
                        .flags = &flags,
                    });
                }
                const have_sse41 = target.result.cpu.has(.x86, .sse4_1);
                if (have_sse3 and have_sse41) {
                    zlib_ng.root_module.addCMacro("X86_SSE41", "1");
                    zlib_ng.addCSourceFiles(.{
                        .root = zlib_ng_dep.path("arch/x86"),
                        .files = &.{
                            "chorba_sse41.c",
                        },
                        .flags = &flags,
                    });
                }
                const have_sse42 = target.result.cpu.has(.x86, .sse4_2);
                if (have_sse41 and have_sse42) {
                    zlib_ng.root_module.addCMacro("X86_SSE42", "1");
                    zlib_ng.addCSourceFiles(.{
                        .root = zlib_ng_dep.path("arch/x86"),
                        .files = &.{
                            "adler32_sse42.c",
                        },
                        .flags = &flags,
                    });
                }
                const have_pclmulqdq = target.result.cpu.has(.x86, .pclmul);
                if (have_sse42 and have_pclmulqdq) {
                    zlib_ng.root_module.addCMacro("X86_PCLMULQDQ_CRC", "1");
                    zlib_ng.addCSourceFiles(.{
                        .root = zlib_ng_dep.path("arch/x86"),
                        .files = &.{
                            "crc32_pclmulqdq.c",
                        },
                        .flags = &flags,
                    });
                }
                const have_avx2 = target.result.cpu.has(.x86, .avx2);
                if (have_sse42 and have_avx2) {
                    zlib_ng.root_module.addCMacro("X86_AVX2", "1");
                    zlib_ng.addCSourceFiles(.{
                        .root = zlib_ng_dep.path("arch/x86"),
                        .files = &.{
                            "slide_hash_avx2.c",
                            "chunkset_avx2.c",
                            "compare256_avx2.c",
                            "adler32_avx2.c",
                        },
                        .flags = &flags,
                    });
                }
                const have_avx512 = target.result.cpu.has(.x86, .avx512f) and target.result.cpu.has(.x86, .avx512dq) and target.result.cpu.has(.x86, .avx512bw) and target.result.cpu.has(.x86, .avx512vl);
                if (have_avx2 and have_avx512) {
                    zlib_ng.root_module.addCMacro("X86_AVX512", "1");
                    zlib_ng.addCSourceFiles(.{
                        .root = zlib_ng_dep.path("arch/x86"),
                        .files = &.{
                            "adler32_avx512.c",
                            "chunkset_avx512.c",
                            "compare256_avx512.c",
                        },
                        .flags = &flags,
                    });
                }
                const have_avx512vnni = target.result.cpu.has(.x86, .avx512vnni);
                if (have_avx2 and have_avx512vnni) {
                    zlib_ng.root_module.addCMacro("X86_AVX512VNNI", "1");
                    zlib_ng.addCSourceFiles(.{
                        .root = zlib_ng_dep.path("arch/x86"),
                        .files = &.{
                            "adler32_avx512_vnni.c",
                        },
                        .flags = &flags,
                    });
                }
                const have_vpclmulqdq = target.result.cpu.has(.x86, .vpclmulqdq);
                if (have_pclmulqdq and have_avx512 and have_vpclmulqdq) {
                    zlib_ng.root_module.addCMacro("X86_VPCLMULQDQ_CRC", "1");
                    zlib_ng.addCSourceFiles(.{
                        .root = zlib_ng_dep.path("arch/x86"),
                        .files = &.{
                            "crc32_vpclmulqdq.c",
                        },
                        .flags = &flags,
                    });
                }
            },
            else => {},
        }
    }
    if (with_runtime_cpu_detection) {
        zlib_ng.addCSourceFiles(.{
            .root = zlib_ng_dep.path("."),
            .files = &.{"cpu_features.c"},
            .flags = &flags,
        });
    }
    if (with_crc32_chorba) {
        zlib_ng.addCSourceFiles(.{
            .root = zlib_ng_dep.path("arch/generic"),
            .files = &.{"crc32_chorba_c.c"},
            .flags = &flags,
        });
    }

    zlib_ng.installConfigHeader(zlib_ng_h);
    zlib_ng.installConfigHeader(zconf_ng_h);
    zlib_ng.installConfigHeader(zlib_name_mangling_ng_h);
    zlib_ng.installConfigHeader(zconf_h);
    zlib_ng.installConfigHeader(zlib_h);
    zlib_ng.installConfigHeader(zlib_name_mangling_h);
    b.installArtifact(zlib_ng);
}

const zlib_sources = .{
    "adler32.c",
    "compress.c",
    "crc32.c",
    "crc32_braid_comb.c",
    "deflate.c",
    "deflate_fast.c",
    "deflate_huff.c",
    "deflate_medium.c",
    "deflate_quick.c",
    "deflate_rle.c",
    "deflate_slow.c",
    "deflate_stored.c",
    "functable.c",
    "infback.c",
    "inflate.c",
    "inftrees.c",
    "insert_string.c",
    "insert_string_roll.c",
    "trees.c",
    "uncompr.c",
    "zutil.c",
};

const gzfile_sources = .{
    "gzlib.c",
    "gzwrite.c",
};

const fallback_sources = .{
    "arch/generic/adler32_c.c",
    "arch/generic/chunkset_c.c",
    "arch/generic/compare256_c.c",
    "arch/generic/crc32_braid_c.c",
    "arch/generic/crc32_chorba_c.c",
    "arch/generic/crc32_fold_c.c",
    "arch/generic/slide_hash_c.c",
};
