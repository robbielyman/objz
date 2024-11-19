pub extern "c" fn sel_getName(sel: *objc.Sel) [*:0]const u8;
pub extern "c" fn sel_registerName(str: [*:0]const u8) *objc.Sel;
pub extern "c" fn sel_isMapped(self: *objc.Sel) bool;

pub extern "c" fn object_getClassName(id: ?*objc.Id) ?[*:0]const u8;
pub extern "c" fn object_copy(obj: ?*objc.Id, size: usize) ?*objc.Id;
pub extern "c" fn object_dispose(obj: ?*objc.Id) ?*objc.Id;
pub extern "c" fn object_getClass(obj: ?*objc.Id) ?*objc.Class;
pub extern "c" fn object_setClass(obj: ?*objc.Id, cls: *objc.Class) ?*objc.Class;
pub extern "c" fn object_isClass(obj: ?*objc.Id) bool;
pub extern "c" fn object_getIvar(obj: ?*objc.Id, ivar: *objc.Ivar) ?*objc.Id;
pub extern "c" fn object_setIvar(obj: ?*objc.Id, ivar: *objc.Ivar, value: ?*objc.Id) void;
pub extern "c" fn object_setIvarWithStrongDefault(obj: ?*objc.Id, ivar: *objc.Ivar, value: ?*objc.Id) void;
pub extern "c" fn object_getInstanceVariable(obj: ?*objc.Id, name: [*:0]const u8, out_value: ?*?*anyopaque) ?*objc.Ivar;
pub extern "c" fn object_setInstanceVariable(obj: ?*objc.Id, name: [*:0]const u8, value: ?*anyopaque) ?*objc.Ivar;
pub extern "c" fn object_setInstanceVariableWithStrongDefault(obj: ?*objc.Id, name: [*:0]const u8, value: ?*anyopaque) ?*objc.Ivar;

pub extern "c" fn objc_getClass(name: [*:0]const u8) ?*objc.Class;
pub extern "c" fn objc_getMetaClass(name: [*:0]const u8) ?*objc.Class;
pub extern "c" fn objc_getClassList(buffer: ?[*]*objc.Class, count: c_int) c_int;
pub extern "c" fn objc_copyClassList(count: ?*c_uint) ?[*]*objc.Class;

pub extern "c" fn class_getName(cls: ?*objc.Class) [*:0]const u8;
pub extern "c" fn class_isMetaClass(cls: ?*objc.Class) bool;
pub extern "c" fn class_getInstanceSize(cls: ?*objc.Class) usize;
pub extern "c" fn class_getInstanceVariable(cls: ?*objc.Class, name: [*:0]const u8) ?*objc.Ivar;
pub extern "c" fn class_getClassVariable(cls: ?*objc.Class, name: [*:0]const u8) ?*objc.Ivar;
pub extern "c" fn class_copyIvarList(cls: ?*objc.Class, out_count: ?*c_uint) ?[*]*objc.Ivar;
pub extern "c" fn class_getInstanceMethod(cls: ?*objc.Class, name: *objc.Sel) ?*objc.Method;
pub extern "c" fn class_getClassMethod(cls: ?*objc.Class, name: *objc.Sel) ?*objc.Method;
pub extern "c" fn class_getMethodImplementation(cls: ?*objc.Class, name: *objc.Sel) ?objc.Imp;
pub extern "c" fn class_copyMethodList(cls: ?*objc.Class, out_count: ?*c_uint) ?[*]*objc.Method;
pub extern "c" fn class_copyProtocolList(cls: ?*objc.Class, out_count: ?*c_uint) ?[*]*objc.Protocol;
pub extern "c" fn class_getProperty(cls: ?*objc.Class, name: [*:0]const u8) ?*objc.Property;
pub extern "c" fn class_addMethod(cls: ?*objc.Class, name: *objc.Sel, imp: objc.Imp, types: ?[*:0]const u8) bool;
pub extern "c" fn class_replaceMethod(cls: ?*objc.Class, name: *objc.Sel, imp: objc.Imp, types: ?[*:0]const u8) ?objc.Imp;
pub extern "c" fn class_addIvar(cls: ?*objc.Class, name: [*:0]const u8, size: usize, log2_alignment: u8, types: ?[*:0]const u8) bool;
pub extern "c" fn class_addProtocol(cls: ?*objc.Class, protocol: *objc.Protocol) bool;
pub extern "c" fn class_addProperty(cls: ?*objc.Class, name: [*:0]const u8, attributes: ?[*]objc.Attribute, count: c_uint) bool;
pub extern "c" fn class_replaceProperty(cls: ?*objc.Class, name: [*:0]const u8, attributes: ?[*]const objc.Attribute, count: c_uint) void;
pub extern "c" fn class_createInstance(cls: ?*objc.Class, extra_bytes: usize) ?*objc.Id;

pub extern "c" fn objc_allocateClassPair(superclass: ?*objc.Class, name: [*:0]const u8, extra_bytes: usize) ?*objc.Class;
pub extern "c" fn objc_registerClassPair(cls: *objc.Class) void;
pub extern "c" fn objc_disposeClassPair(cls: *objc.Class) void;

pub extern "c" fn method_getName(m: *objc.Method) *objc.Sel;
pub extern "c" fn method_getImplementation(m: *objc.Method) objc.Imp;
pub extern "c" fn method_getTypeEncoding(m: *objc.Method) ?[*:0]const u8;
pub extern "c" fn method_getNumberOfArguments(m: *objc.Method) c_uint;
pub extern "c" fn method_copyReturnType(m: *objc.Method) [*:0]u8;
pub extern "c" fn method_copyArgumentType(m: *objc.Method, index: c_uint) ?[*:0]u8;
pub extern "c" fn method_getReturnType(m: *objc.Method, dst: [*]u8, len: usize) void;
pub extern "c" fn method_getArgumentType(m: *objc.Method, index: c_uint, dst: ?[*]u8, len: usize) void;
pub extern "c" fn method_getDescription(m: *objc.Method) *objc.MethodDescription;
pub extern "c" fn method_setImplementation(m: *objc.Method, imp: objc.Imp) objc.Imp;
pub extern "c" fn method_exchangeImplementations(m1: *objc.Method, m2: *objc.Method) void;

pub extern "c" fn ivar_getName(v: *objc.Ivar) ?[*:0]const u8;
pub extern "c" fn ivar_getTypeEncoding(v: *objc.Ivar) ?[*:0]const u8;
pub extern "c" fn ivar_getOffset(v: *objc.Ivar) isize;

pub extern "c" fn property_getName(property: *objc.Property) [*:0]const u8;
pub extern "c" fn property_getAttributes(property: *objc.Property) ?[*:0]const u8;
pub extern "c" fn property_copyAttributeList(property: *objc.Property, out_count: ?*c_uint) ?[*]objc.Attribute;
pub extern "c" fn property_copyAttributeValue(property: *objc.Property, name: [*:0]const u8) ?[*:0]u8;

pub extern "c" fn objc_getProtocol(name: [*:0]const u8) ?*objc.Protocol;
pub extern "c" fn objc_copyProtocolList(out_count: *c_uint) ?[*]*objc.Protocol;

pub extern "c" fn protocol_conformsToProtocol(proto: ?*objc.Protocol, other: ?*objc.Protocol) bool;
pub extern "c" fn protocol_isEqual(proto: ?*objc.Protocol, other: ?*objc.Protocol) bool;
pub extern "c" fn protocol_getName(proto: *objc.Protocol) [*:0]const u8;
pub extern "c" fn protocol_getMethodDescription(proto: *objc.Protocol, sel: *objc.Sel, is_required: bool, is_instance: bool) objc.MethodDescription;
pub extern "c" fn protocol_copyMethodDescriptionList(proto: *objc.Protocol, is_required: bool, is_instance: bool, out_count: ?*c_uint) ?[*]objc.MethodDescription;
pub extern "c" fn protocol_getProperty(proto: *objc.Protocol, name: [*:0]const u8, is_required: bool, is_instance: bool) ?*objc.Property;
pub extern "c" fn protocol_copyPropertyList2(proto: *objc.Protocol, out_count: ?*c_uint, is_required: bool, is_instance: bool) ?[*]*objc.Property;

pub extern "c" fn objc_allocateProtocol(name: [*:0]const u8) ?*objc.Protocol;
pub extern "c" fn objc_registerProtocol(proto: *objc.Protocol) void;

pub extern "c" fn protocol_addMethodDescription(proto: *objc.Protocol, name: *objc.Sel, types: ?[*:0]const u8, is_required: bool, is_instance: bool) void;
pub extern "c" fn protocol_addProtocol(proto: *objc.Protocol, addition: *objc.Protocol) void;
pub extern "c" fn protocol_addProperty(proto: *objc.Protocol, name: [*:0]const u8, attributes: ?[*]objc.Attribute, attr_count: c_uint, is_required: bool, is_instance: bool) void;

pub extern "c" fn imp_implementationWithBlock(block: *objc.Id) objc.Imp;
pub extern "c" fn imp_getBlock(imp: objc.Imp) ?*objc.Id;
pub extern "c" fn imp_removeBlock(imp: objc.Imp) bool;

pub extern "c" fn objc_msgSendSuper() void;
pub extern "c" fn objc_msgSend() void;
pub extern "c" fn objc_msgSendSuper_stret() void;
pub extern "c" fn objc_msgSend_stret() void;
pub extern "c" fn objc_msgSendSuper_fpret() void;
pub extern "c" fn objc_msgSend_fpret() void;

pub const ObjcSuper = extern struct {
    self: *objc.Id,
    super_class: *objc.Class,
};

const objc = @import("lib.zig");
