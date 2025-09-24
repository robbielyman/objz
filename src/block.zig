/// Creates the equivalent of a __block variable
pub fn Variable(comptime Type: type) type {
    return extern struct {
        const Self = @This();

        isa: ?*anyopaque,
        forwarding: ?*anyopaque,
        flags: c_int,
        size: c_int,
        keep: ?*const fn (dst: *anyopaque, src: *anyopaque) callconv(.c) void,
        dispose: ?*const fn (src: *anyopaque) callconv(.c) void,
        captured: Type,

        const Encoding = @import("encoding.zig").Encoding;

        pub fn encoding() Encoding {
            return .init(Type);
        }

        pub fn access(self: Self) *Type {
            const forwarding: *Self = @ptrCast(@alignCast(self.forwarding));
            return &forwarding.captured;
        }

        pub fn release(self: *Self) void {
            const flag = flag: {
                comptime var flag: FieldIs = .fromType(Type);
                flag.byref = true;
                break :flag flag;
            };
            _Block_object_dispose(self, flag.asInt());
        }

        pub fn disposeHelper(src: *anyopaque) callconv(.c) void {
            const real_src: *Self = @ptrCast(@alignCast(src));
            const flag = flag: {
                comptime var flag: FieldIs = .fromType(Type);
                flag.byref_caller = true;
                break :flag flag;
            };
            _Block_object_dispose(@ptrCast(&real_src.captured), flag.asInt());
        }

        pub fn keepHelper(dst: *anyopaque, src: *anyopaque) callconv(.c) void {
            const real_dst: *Self = @ptrCast(@alignCast(dst));
            const real_src: *Self = @ptrCast(@alignCast(src));
            const flag = flag: {
                comptime var flag: FieldIs = .fromType(Type);
                flag.byref_caller = true;
                break :flag flag;
            };
            _Block_object_assign(@ptrCast(&real_dst.captured), @ptrCast(&real_src.captured), flag.asInt());
        }

        pub const field_is: FieldIs = blk: {
            var ret: FieldIs = .fromType(Type);
            ret.byref = true;
            ret.byref_caller = true;
            break :blk ret;
        };

        pub fn init(self: *Self, value: Type) void {
            self.forwarding = self;
            self.captured = value;
        }

        pub const uninit: Self = .{
            .isa = null,
            .forwarding = undefined,
            .flags = 0,
            .size = @sizeOf(Self),
            .keep = keepHelper,
            .dispose = disposeHelper,
            .captured = undefined,
        };
    };
}

/// Creates a new block type with captured (closed over) values.
///
/// The CapturesArg is the a struct of captured values that will become
/// available to the block. The Args is a tuple of types that are additional
/// invocation-time arguments to the function. The Return param is the return
/// type of the function.
///
/// The function that must be implemented is available as the `Fn` field.
/// The first argument to the function is always a pointer to the `Context`
/// type (see field in the struct). This has the captured values.
///
/// The captures struct is always available as the `Captures` field which
/// makes it easy to use an inline type definition for the argument and
/// reference the type in a named fashion later.
///
/// The returned block type can be initialized and invoked multiple times
/// for different captures and arguments.
///
/// See the tests for an example.
pub fn Block(
    comptime CapturesArg: type,
    comptime Args: anytype,
    comptime Return: type,
) type {
    return opaque {
        const Self = @This();
        const captures_info = @typeInfo(Captures).@"struct";
        const InvokeFn = FnType(anyopaque);

        pub const is_block = true;

        fn FnType(comptime First: type) type {
            var params: [Args.len + 1]std.builtin.Type.Fn.Param = undefined;
            params[0] = .{
                .is_generic = false,
                .is_noalias = false,
                .type = *const First,
            };

            for (Args, 1..) |Arg, i| {
                params[i] = .{
                    .is_generic = false,
                    .is_noalias = false,
                    .type = Arg,
                };
            }
            return @Type(.{ .@"fn" = .{
                .calling_convention = .c,
                .is_generic = false,
                .is_var_args = false,
                .return_type = Return,
                .params = &params,
            } });
        }
        const descriptor: Descriptor = .{
            .reserved = 0,
            .size = Size(CapturesArg, InvokeFn),
            .copy_helper = &descCopyHelper,
            .dispose_helper = &descDisposeHelper,
            .signature = &objc.encode(FnType(anyopaque)),
        };

        fn descCopyHelper(src: *anyopaque, dst: *anyopaque) callconv(.c) void {
            const real_src: *Context = @ptrCast(@alignCast(src));
            const real_dst: *Context = @ptrCast(@alignCast(dst));
            inline for (captures_info.fields) |field| {
                const kind: FieldIs = .fromType(field.type);
                _Block_object_assign(
                    @ptrCast(&@field(real_dst, field.name)),
                    @ptrCast(&@field(real_src, field.name)),
                    kind.asInt(),
                );
            }
        }

        fn descDisposeHelper(src: *anyopaque) callconv(.c) void {
            const real_src: *Context = @ptrCast(@alignCast(src));
            inline for (captures_info.fields) |field| {
                const kind: FieldIs = .fromType(field.type);
                _Block_object_dispose(@ptrCast(&@field(real_src, field.name)), kind.asInt());
            }
        }

        pub const Context = BlockContext(Captures, InvokeFn, descriptor);

        pub const Fn = FnType(Context);
        pub const Captures = CapturesArg;

        pub fn asId(self: *Self) *objc.Id {
            return @ptrCast(self);
        }

        /// Invoke the block with the given arguments. The arguments are
        /// the arguments to pass to the function beyond the captured scope.
        pub fn invoke(self: *const Self, args: anytype) Return {
            const context: *const Self.Context = @ptrCast(@alignCast(self));
            return @call(.auto, context.invoke, .{context} ++ args);
        }

        pub fn copyFromContext(context: *const Context) *Self {
            return @ptrCast(_Block_copy(context));
        }

        const auto = @import("autorelease.zig");

        pub fn retain(self: *Self) *Self {
            return @ptrCast(auto.retainBlock(self.asId()));
        }

        pub fn release(self: *Self) void {
            auto.release(self.asId());
        }

        pub fn contextCast(ctx: *const anyopaque) *const Context {
            return @ptrCast(@alignCast(ctx));
        }
    };
}

fn Size(comptime Captures: type, comptime InvokeFn: type) comptime_int {
    const captures_info = @typeInfo(Captures).@"struct";
    var fields: [captures_info.fields.len + 5]std.builtin.Type.StructField = undefined;
    fields[0] = .{
        .name = "isa",
        .type = ?*anyopaque,
        .default_value_ptr = null,
        .is_comptime = false,
        .alignment = @alignOf(*anyopaque),
    };
    fields[1] = .{
        .name = "flags",
        .type = c_int,
        .default_value_ptr = null,
        .is_comptime = false,
        .alignment = @alignOf(c_int),
    };
    fields[2] = .{
        .name = "reserved",
        .type = c_int,
        .default_value_ptr = null,
        .is_comptime = false,
        .alignment = @alignOf(c_int),
    };
    fields[3] = .{
        .name = "invoke",
        .type = *const InvokeFn,
        .default_value_ptr = null,
        .is_comptime = false,
        .alignment = @typeInfo(*const InvokeFn).pointer.alignment,
    };
    fields[4] = .{
        .name = "descriptor",
        .type = *const Descriptor,
        .default_value_ptr = null,
        .is_comptime = false,
        .alignment = @alignOf(*Descriptor),
    };

    for (captures_info.fields, 5..) |capture, i| {
        switch (capture.type) {
            comptime_int => @compileError("capture should not be a comptime_int, try using @as"),
            comptime_float => @compileError("capture should not be a comptime_float, try using @as"),
            else => {},
        }

        fields[i] = .{
            .name = capture.name,
            .type = capture.type,
            .default_value_ptr = capture.default_value_ptr,
            .is_comptime = false,
            .alignment = capture.alignment,
        };
    }

    return @sizeOf(@Type(.{
        .@"struct" = .{
            .layout = .@"extern",
            .fields = &fields,
            .decls = &.{},
            .is_tuple = false,
        },
    }));
}

/// This is the type of a block structure that is passed as the first
/// argument to any block invocation. See Block.
fn BlockContext(comptime Captures: type, comptime InvokeFn: type, comptime descriptor: Descriptor) type {
    const flags: BlockFlags = .{
        .stret = @typeInfo(@typeInfo(InvokeFn).@"fn".return_type.?) == .@"struct",
    };
    const captures_info = @typeInfo(Captures).@"struct";
    var fields: [captures_info.fields.len + 5]std.builtin.Type.StructField = undefined;
    fields[0] = .{
        .name = "isa",
        .type = ?*anyopaque,
        .default_value_ptr = @ptrCast(&NSConcreteStackBlock),
        .is_comptime = false,
        .alignment = @alignOf(*anyopaque),
    };
    fields[1] = .{
        .name = "flags",
        .type = c_int,
        .default_value_ptr = &flags,
        .is_comptime = false,
        .alignment = @alignOf(c_int),
    };
    fields[2] = .{
        .name = "reserved",
        .type = c_int,
        .default_value_ptr = &@as(c_int, 0),
        .is_comptime = false,
        .alignment = @alignOf(c_int),
    };
    fields[3] = .{
        .name = "invoke",
        .type = *const InvokeFn,
        .default_value_ptr = null,
        .is_comptime = false,
        .alignment = @typeInfo(*const InvokeFn).pointer.alignment,
    };
    fields[4] = .{
        .name = "descriptor",
        .type = *const Descriptor,
        .default_value_ptr = &descriptor,
        .is_comptime = false,
        .alignment = @alignOf(*Descriptor),
    };

    for (captures_info.fields, 5..) |capture, i| {
        switch (capture.type) {
            comptime_int => @compileError("capture should not be a comptime_int, try using @as"),
            comptime_float => @compileError("capture should not be a comptime_float, try using @as"),
            else => {},
        }

        fields[i] = .{
            .name = capture.name,
            .type = capture.type,
            .default_value_ptr = capture.default_value_ptr,
            .is_comptime = false,
            .alignment = capture.alignment,
        };
    }

    return @Type(.{
        .@"struct" = .{
            .layout = .@"extern",
            .fields = &fields,
            .decls = &.{},
            .is_tuple = false,
        },
    });
}

// Pointer to opaque instead of anyopaque: https://github.com/ziglang/zig/issues/18461
const NSConcreteStackBlock = @extern(*opaque {}, .{ .name = "_NSConcreteStackBlock" });

extern "c" fn _Block_object_assign(dst: *anyopaque, src: *const anyopaque, flag: c_int) void;
extern "c" fn _Block_object_dispose(src: *const anyopaque, flag: c_int) void;

extern "c" fn _Block_copy(block: *const anyopaque) *anyopaque;
extern "c" fn _Block_release(block: *const anyopaque) void;

const Descriptor = extern struct {
    reserved: c_ulong = 0,
    size: c_ulong,
    copy_helper: *const fn (dst: *anyopaque, src: *anyopaque) callconv(.c) void,
    dispose_helper: *const fn (src: *anyopaque) callconv(.c) void,
    signature: ?[*:0]const u8,
};

pub const FieldIs = packed struct(u8) {
    kind: enum(u3) {
        neither = 0,
        object = 3,
        block = 7,
    } = .neither,
    byref: bool = false,
    weak: bool = false,
    _unused: u2 = 0,
    byref_caller: bool = false,

    pub const neither: FieldIs = .{ .kind = .neither };
    pub const object: FieldIs = .{ .kind = .object };
    pub const block: FieldIs = .{ .kind = .block };

    pub fn fromType(comptime T: type) FieldIs {
        const encoding = comptime objc.encode(T);
        if (comptime std.mem.eql(u8, &encoding, "@")) return .object;
        if (comptime std.mem.eql(u8, &encoding, "^")) return .block;

        const info = @typeInfo(T);
        switch (info) {
            .@"struct", .@"union", .@"enum", .@"opaque" => {
                if (@hasDecl(T, "field_is")) return T.field_is;
                if (@hasDecl(T, "is_block") and T.is_block) return .block;
                if (@hasDecl(T, "is_weak") and @hasDecl(T, "is_id") and T.is_weak and T.is_id) return .{
                    .kind = .object,
                    .weak = true,
                };
                if (@hasDecl(T, "is_id") and T.is_id) return .object;
                if (@hasDecl(T, "asId")) return .object;

                return .neither;
            },
            .pointer => |ptr| return fromType(ptr.child),
            .optional => |opt| return fromType(opt.child),
            else => return .neither,
        }
    }

    pub fn asInt(self: @This()) c_int {
        const byte: u8 = @bitCast(self);
        return byte;
    }
};

const BlockFlags = packed struct(c_int) {
    _unused: u22 = 0,
    noescape: bool = false,
    _unused_2: bool = false,
    copy_dispose: bool = true,
    ctor: bool = false,
    _unused_3: bool = false,
    global: bool = false,
    stret: bool,
    signature: bool = true,
    _unused_4: u2 = 0,
};

const std = @import("std");
const objc = @import("lib.zig");
const assert = std.debug.assert;

test Block {
    const AddBlock = Block(struct {
        x: i32 = 5,
        y: i32,
    }, .{i32}, i32);

    const context: AddBlock.Context = .{
        .y = 3,
        .invoke = struct {
            fn addFn(block_ctx: *const anyopaque, z: i32) callconv(.c) i32 {
                const block = AddBlock.contextCast(block_ctx);
                return block.x + block.y + z;
            }
        }.addFn,
    };

    const block: *AddBlock = .copyFromContext(&context);
    defer block.release();

    const ret = block.invoke(.{2});
    try std.testing.expectEqual(10, ret);
}

test Variable {
    const V = Variable(i32);
    var variable: V = .uninit;
    variable.init(5);
    defer variable.release();

    const Accumulate = Block(struct {
        x: V,
    }, .{i32}, i32);

    const context: Accumulate.Context = .{
        .x = variable,
        .invoke = struct {
            fn accumulate(block_ctx: *const anyopaque, add: i32) callconv(.c) i32 {
                const block = Accumulate.contextCast(block_ctx);
                const ptr = block.x.access();
                ptr.* += add;
                return ptr.*;
            }
        }.accumulate,
    };
    const block: *Accumulate = .copyFromContext(&context);
    defer block.release();

    const ret = block.invoke(.{2});
    try std.testing.expectEqual(7, ret);
    try std.testing.expectEqual(7, variable.access().*);
    variable.access().* = 99;
    try std.testing.expectEqual(100, block.invoke(.{1}));
}
