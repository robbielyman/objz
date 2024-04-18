//! function names in this library follow
//! the objective-C ownership naming convention:
//! briefly "get" means you do not own the returned memory
//! while "alloc" or "create" or "copy" does.

pub const Method = opaque {
    pub fn getName(m: *Method) *Sel {
        return c.method_getName(m);
    }

    /// must be cast to the proper type in order to call
    pub fn getImplementation(m: *Method) Imp {
        return c.method_getImplementation(m);
    }

    pub fn getTypeEncoding(m: *Method) ?[:0]const u8 {
        const enc = c.method_getTypeEncoding(m) orelse return null;
        return std.mem.sliceTo(enc, 0);
    }

    pub fn getNumberOfArguments(m: *Method) usize {
        return c.method_getNumberOfArguments(m);
    }

    pub fn copyReturnType(m: *Method) [:0]u8 {
        return std.mem.sliceTo(c.method_copyReturnType(m), 0);
    }

    pub fn copyArgumentType(m: *Method, index: usize) ?[:0]u8 {
        const ptr = c.method_copyArgumentType(m, @intCast(index)) orelse return null;
        return std.mem.sliceTo(ptr, 0);
    }

    pub fn getReturnType(m: *Method, buf: []u8) void {
        c.method_getReturnType(m, buf.ptr, buf.len);
    }

    pub fn getArgumentType(m: *Method, index: usize, buf: []u8) void {
        c.method_getArgumentType(m, @intCast(index), buf.ptr, buf.len);
    }

    pub fn getDescription(m: *Method) *MethodDescription {
        return c.method_getDescription(m);
    }

    pub fn setImplementation(m: *Method, imp: Imp) Imp {
        return c.method_setImplementation(m, imp);
    }

    pub fn exchangeImplementations(m1: *Method, m2: *Method) void {
        c.method_exchangeImplementations(m1, m2);
    }
};

pub const Ivar = opaque {
    pub fn getName(v: *Ivar) ?[:0]const u8 {
        const ptr = c.ivar_getName(v) orelse return null;
        return std.mem.sliceTo(ptr, 0);
    }

    pub fn getTypeEncoding(v: *Ivar) ?[:0]const u8 {
        const ptr = c.ivar_getTypeEncoding(v) orelse return null;
        return std.mem.sliceTo(ptr, 0);
    }

    pub fn getOffset(v: *Ivar) isize {
        return c.ivar_getOffset(v);
    }
};

// pub const Category = opaque {};

pub const Property = opaque {
    pub fn getName(property: *Property) [:0]const u8 {
        return std.mem.sliceTo(c.property_getName(property), 0);
    }

    pub fn getAttributes(property: *Property) ?[:0]const u8 {
        const ptr = c.property_getAttributes(property) orelse return null;
        return std.mem.sliceTo(ptr, 0);
    }

    pub fn copyAttributeList(property: *Property) ?[]Attribute {
        var count: c_uint = undefined;
        const ptr = c.property_copyAttributeList(property, &count) orelse return null;
        if (count == 0) return null;
        return ptr[0..count];
    }

    pub fn copyAttributeValue(property: *Property, name: [:0]const u8) ?[:0]u8 {
        const ptr = c.property_copyAttributeValue(property, name.ptr) orelse return null;
        return std.mem.sliceTo(ptr, 0);
    }
};

pub fn getProtocol(name: [:0]const u8) ?*Protocol {
    return c.objc_getProtocol(name.ptr);
}

pub fn copyProtocolList() ?[]*Protocol {
    var count: c_uint = undefined;
    const list = c.objc_copyProtocolList(&count) orelse return null;
    if (count == 0) return null;
    return list[0..count];
}

pub const Protocol = opaque {
    pub fn conformsTo(self: *Protocol, other: *Protocol) bool {
        return c.protocol_conformsToProtocol(self, other);
    }

    pub fn isEqual(self: *Protocol, other: *Protocol) bool {
        return c.protocol_isEqual(self, other);
    }

    pub fn getName(self: *Protocol) [:0]const u8 {
        return std.mem.sliceTo(c.protocol_getName(self), 0);
    }

    pub fn getMethodDescription(proto: *Protocol, name: anytype, is_required: bool, is_instance: bool) MethodDescription {
        const sel: *Sel = switch (@TypeOf(name)) {
            *Sel => name,
            else => Sel.register(name),
        };
        return c.protocol_getMethodDescription(proto, sel, is_required, is_instance);
    }

    pub fn copyMethodDescriptionList(proto: *Protocol, is_required: bool, is_instance: bool) ?[]MethodDescription {
        var count: c_uint = undefined;
        const list = c.protocol_copyMethodDescriptionList(proto, is_required, is_instance, &count) orelse return null;
        if (count == 0) return null;
        return list[0..count];
    }

    pub fn getProperty(proto: *Protocol, name: [:0]const u8, is_required: bool, is_instance: bool) ?*Property {
        return c.protocol_getProperty(proto, name.ptr, is_required, is_instance);
    }

    pub fn copyPropertyList(proto: *Protocol, is_required: bool, is_instance: bool) ?[]*Property {
        var count: c_uint = undefined;
        const list = c.protocol_copyPropertyList2(proto, &count, is_required, is_instance) orelse return null;
        if (count == 0) return null;
        return list[0..count];
    }

    /// registers with the runtime
    pub fn register(proto: *Protocol) void {
        c.objc_registerProtocol(proto);
    }

    /// must be under construction
    /// it is recommended to get types by calling /// encode on a function type
    pub fn addMethodDescription(proto: *Protocol, name: anytype, types: ?[:0]const u8, is_required: bool, is_instance: bool) void {
        const sel: *Sel = switch (@TypeOf(name)) {
            *Sel => name,
            else => Sel.register(name),
        };
        c.protocol_addMethodDescription(proto, sel, types, is_required, is_instance);
    }

    /// self must be under construction, while other must not
    pub fn addProtocol(self: *Protocol, other: *Protocol) void {
        c.protocol_addProtocol(self, other);
    }

    /// protocol must be under construction
    pub fn protocol_addProperty(self: *Protocol, name: [:0]const u8, attributes: ?[]Attribute, is_required: bool, is_instance: bool) void {
        c.protocol_addProperty(
            self,
            name.ptr,
            if (attributes) |a| a.ptr else null,
            if (attributes) |a| @intCast(a.len) else 0,
            is_required,
            is_instance,
        );
    }
};

/// call register on the returned protocol to begin using
pub fn allocateProtocol(name: [:0]const u8) ?*Protocol {
    return c.objc_allocateProtocol(name.ptr);
}

pub const Sel = opaque {
    pub fn getName(sel: *Sel) [:0]const u8 {
        return std.mem.sliceTo(c.sel_getName(sel), 0);
    }

    pub fn register(name: [:0]const u8) *Sel {
        return c.sel_registerName(name.ptr);
    }

    pub fn isMapped(sel: *Sel) bool {
        return c.sel_isMapped(sel);
    }

    test "sel" {
        const yo = Sel.register("yo");
        try std.testing.expectEqualStrings("yo", yo.getName());
        try std.testing.expect(yo.isMapped());
    }
};

pub const MethodDescription = extern struct {
    name: ?*Sel,
    types: ?[*:0]const u8,
};

pub const Attribute = extern struct {
    name: [*:0]const u8,
    value: [*:0]const u8,
};

pub fn getClass(name: [:0]const u8) ?*Class {
    return c.objc_getClass(name.ptr);
}

pub fn getMetaClass(name: [:0]const u8) ?*Class {
    return c.objc_getMetaClass(name.ptr);
}

// if buf is null, returns the number of classe in the runtime
pub fn getClassList(buf: ?[]*Class) usize {
    const len: c_int = if (buf) |b| @intCast(b.len) else 0;
    const ptr: ?[*]*Class = if (buf) |b| b.ptr else null;
    return @intCast(c.objc_getClassList(ptr, len));
}

pub fn copyClassList() ?[]*Class {
    var count: c_uint = undefined;
    const list = c.objc_copyClassList(&count) orelse return null;
    if (count == 0) return null;
    return list[0..count];
}

pub const Class = opaque {
    pub const msgSend = msg_send.msgSend;
    pub const msgSendSuper = msg_send.msgSendSuper;
    
    pub fn getMetaClass(cls: *Class) ?*Class {
        return c.object_getClass(@ptrCast(cls));
    }

    pub fn getName(cls: *Class) [:0]const u8 {
        return std.mem.sliceTo(c.class_getName(cls), 0);
    }

    pub fn isMetaClass(cls: *Class) bool {
        return c.class_isMetaClass(cls);
    }

    pub fn getInstanceSize(cls: *Class) usize {
        return c.class_getInstanceSize(cls);
    }

    pub fn getInstanceVariable(cls: *Class, name: [:0]const u8) ?*Ivar {
        return c.class_getInstanceVariable(cls, name.ptr);
    }

    pub fn copyIvarList(cls: *Class) ?[]*Ivar {
        var count: c_uint = undefined;
        const list = c.class_copyIvarList(cls, &count) orelse return null;
        if (count == 0) return null;
        return list[0..count];
    }

    pub fn getInstanceMethod(cls: *Class, name: anytype) ?*Method {
        const sel: *Sel = switch (@TypeOf(name)) {
            *Sel => name,
            else => Sel.register(name),
        };
        return c.class_getInstanceMethod(cls, sel);
    }

    pub fn getClassMethod(cls: *Class, name: anytype) ?*Method {
        const sel: *Sel = switch (@TypeOf(name)) {
            *Sel => name,
            else => Sel.register(name),
        };
        return c.class_getClassMethod(cls, sel);
    }

    pub fn getMethodImplementation(cls: *Class, name: anytype) ?Imp {
        const sel: *Sel = switch (@TypeOf(name)) {
            *Sel => name,
            else => Sel.register(name),
        };
        return c.class_getMethodImplementation(cls, sel);
    }

    /// does not contain instance methods implemented by superclasses
    pub fn copyMethodList(cls: *Class) ?[]*Method {
        var count: c_uint = undefined;
        const list = c.class_copyMethodList(cls, &count) orelse return null;
        if (count == 0) return null;
        return list[0..count];
    }

    /// does not contain protocols implemented by superclasses
    pub fn copyProtocolList(cls: *Class) ?[]*Protocol {
        var count: c_uint = undefined;
        const list = c.class_copyProtocolList(cls, &count) orelse return null;
        if (count == 0) return null;
        return list[0..count];
    }

    pub fn getProperty(cls: *Class, name: [:0]const u8) ?*Property {
        return c.class_getProperty(cls, name.ptr);
    }

    /// returns true on success
    pub fn addMethod(cls: *Class, name: anytype, imp: anytype) bool {
        const sel = switch (@TypeOf(name)) {
            *Sel => name,
            else => Sel.register(name),
        };
        const fn_info = @typeInfo(imp).Fn;
        std.debug.assert(fn_info.calling_convention == .C);
        const types = comptime encode(@TypeOf(imp));
        comptime std.debug.assert(std.mem.startsWith(u8, &types, "@:"));
        return c.class_addMethod(cls, sel, @ptrCast(&imp), &types);
    }

    /// the returned function pointer will be of type Imp;
    /// if you need it to be its actual type, cast it
    pub fn replaceMethod(cls: *Class, name: anytype, imp: anytype) ?Imp {
        const sel = switch (@TypeOf(name)) {
            *Sel => name,
            else => Sel.register(name),
        };
        const fn_info = @typeInfo(imp).Fn;
        std.debug.assert(fn_info.calling_convention == .C);
        const types = comptime encode(@TypeOf(imp));
        comptime std.debug.assert(std.mem.startsWith(u8, &types, "@:"));
        return c.class_replaceMethod(cls, sel, @ptrCast(&imp), &types);
    }

    /// must be called on an under-construction class
    /// must not be a metaclass
    /// returns true on success
    pub fn addIvar(cls: *Class, name: [:0]const u8, comptime T: type) bool {
        const info = @typeInfo(T);
        const log2_alignment: u8, const size: usize = if (info == .Pointer)
            .{ std.math.log2(@alignOf(usize)), @sizeOf(usize) }
        else
            .{ std.math.log2(@alignOf(T)), @sizeOf(T) };
        const types = comptime encode(T);
        return c.class_addIvar(cls, name.ptr, size, log2_alignment, &types);
    }

    /// returns true on success, false if, for example, the class conforms to the protocol
    pub fn addProtocol(cls: *Class, protocol: *Protocol) bool {
        return c.class_addProtocol(cls, protocol);
    }

    /// returns true on success, false if, for example, the class already hass the property
    pub fn addProperty(cls: *Class, name: [:0]const u8, attributes: []const Attribute) bool {
        return c.class_addProperty(cls, name.ptr, attributes.ptr, @intCast(attributes.len));
    }

    pub fn replaceProperty(cls: *Class, name: [:0]const u8, attributes: []const Attribute) void {
        c.class_replaceProperty(cls, name.ptr, attributes.ptr, @intCast(attributes.len));
    }

    pub fn createInstance(cls: *Class, extra_bytes: usize) ?*Id {
        return c.class_createInstance(cls, extra_bytes);
    }

    /// registers a class with the runtime
    pub fn register(cls: *Class) void {
        c.objc_registerClassPair(cls);
    }
};

/// to access the metaclass, call getMetaClass on the returned class
/// to finish, call register on the class
pub fn allocateClassPair(superclass: ?*Class, name: [:0]const u8) ?*Class {
    return c.objc_allocateClassPair(superclass, name.ptr, 0);
}

/// there must not be any instances of this class
pub fn disposeClassPair(cls: *Class) void {
    c.objc_disposeClassPair(cls);
}

pub const Id = opaque {
    pub const msgSend = msg_send.msgSend;
    pub const msgSendSuper = msg_send.msgSendSuper;
    
    pub fn getClassName(self: *Id) ?[*:0]const u8 {
        return std.mem.sliceTo(
            c.object_getClassName(self) orelse return null,
            0,
        );
    }

    pub fn copy(self: *Id, size: usize) ?*Id {
        return c.object_copy(self, size);
    }

    pub fn dispose(self: *Id) void {
        _ = c.object_dispose(self);
    }

    pub fn getClass(self: *Id) ?*Class {
        return c.object_getClass(self);
    }

    pub fn setClass(self: *Id, cls: *Class) ?*Class {
        return c.object_setClass(self, cls);
    }

    pub fn isClass(self: *Id) bool {
        return c.object_isClass(self);
    }

    // if you happen to have the Ivar already,
    // this is faster than getInstanceVariable
    pub fn getIvar(self: *Id, ivar: *Ivar) ?*Id {
        return c.object_getIvar(self, ivar);
    }

    // returns the Ivar for the given name
    // also fills the out_value pointer with the given value if non-null
    pub fn getInstanceVariable(self: *Id, name: [:0]const u8, out_value: ?*?*Ivar) ?*Ivar {
        return c.object_getInstanceVariable(self, name.ptr, out_value);
    }

    // if you happen to have the Ivar already,
    // this is faster than setInstanceVariable
    pub fn setIvar(self: *Id, ivar: *Ivar, val: ?*Id) void {
        c.object_setIvar(self, ivar, val);
    }

    // if you happen to have the Ivar already,
    // this is faster than setInstanceVariable
    pub fn setIvarWithStrongDefault(self: *Id, ivar: *Ivar, val: ?*Id) void {
        c.object_setIvarWithStrongDefault(self, ivar, val);
    }

    // returns the Ivar for the given name
    pub fn setInstanceVariable(self: *Id, name: [:0]const u8, value: ?*anyopaque) ?*Ivar {
        return c.object_setInstanceVariable(self, name.ptr, value);
    }

    // returns the Ivar for the given name
    pub fn setInstanceVariableWithStrongDefault(self: *Id, name: [:0]const u8, value: ?*anyopaque) ?*Ivar {
        return c.object_setInstanceVariableWithStrongDefault(self, name.ptr, value);
    }
};

pub const Imp = *const fn () callconv(.C) void;

/// block's invoke function should have signature
/// self, method_args...
/// in particular it does not have access to the selector
pub fn implementationWithBlock(block: *Id) Imp {
    return c.imp_implementationWithBlock(block);
}

pub fn getBlock(imp: Imp) ?*Id {
    return c.imp_getBlock(imp);
}

/// returns true if the block was successfully released
pub fn removeBlock(imp: Imp) bool {
    return c.imp_removeBlock(imp);
}

pub fn encode(comptime T: type) [EncodeSize(T):0]u8 {
    comptime {
        const encoding = Encoding.init(T);

        // Build our final signature
        var buf: [EncodeSize(T) + 1]u8 = undefined;
        var fbs = std.io.fixedBufferStream(buf[0 .. buf.len - 1]);
        try std.fmt.format(fbs.writer(), "{}", .{encoding});
        buf[buf.len - 1] = 0;

        return buf[0 .. buf.len - 1 :0].*;
    }
}

fn EncodeSize(comptime T: type) usize {
    comptime {
        const encoding = Encoding.init(T);
        // Figure out how much space we need
        var counting = std.io.countingWriter(std.io.null_writer);
        try std.fmt.format(counting.writer(), "{}", .{encoding});
        return counting.bytes_written;
    }
}

pub const c = @import("c.zig");
const std = @import("std");
const Encoding = @import("encoding.zig").Encoding;
pub const Block = @import("block.zig").Block;
const msg_send = @import("msg_send.zig");

test {
    std.testing.refAllDecls(@This());
}
