//! As far as I can tell, the extern functions in this file
//! are undeclared in any header.
//! Instead they are documented in [1].
//!
//! [1]: https://clang.llvm.org/docs/AutomaticReferenceCounting.html#runtime-support

extern "c" fn objc_autorelease(?*objc.Id) ?*objc.Id;
extern "c" fn objc_autoreleasePoolPop(*anyopaque) void;
extern "c" fn objc_autoreleasePoolPush() *anyopaque;
extern "c" fn objc_autoreleaseReturnValue(?*objc.Id) ?*objc.Id;
extern "c" fn objc_copyWeak(*?*objc.Id, *?*objc.Id) void;
extern "c" fn objc_destroyWeak(*?*objc.Id) void;
extern "c" fn objc_initWeak(*?*objc.Id, ?*objc.Id) ?*objc.Id;
extern "c" fn objc_loadWeak(*?*objc.Id) ?*objc.Id;
extern "c" fn objc_loadWeakRetained(*?*objc.Id) ?*objc.Id;
extern "c" fn objc_moveWeak(*?*objc.Id, *?*objc.Id) void;
extern "c" fn objc_release(?*objc.Id) void;
extern "c" fn objc_retain(?*objc.Id) ?*objc.Id;
extern "c" fn objc_retainAutorelease(?*objc.Id) ?*objc.Id;
extern "c" fn objc_retainAutoreleaseReturnValue(?*objc.Id) ?*objc.Id;
extern "c" fn objc_retainAutoreleasedReturnValue(?*objc.Id) ?*objc.Id;
extern "c" fn objc_retainBlock(?*objc.Id) ?*objc.Id;
extern "c" fn objc_storeStrong(*?*objc.Id, ?*objc.Id) void;
extern "c" fn objc_storeWeak(*?*objc.Id, ?*objc.Id) ?*objc.Id;
extern "c" fn objc_unsafeClaimAutoreleasedReturnValue(?*objc.Id) ?*objc.Id;

/// adds the object to the innermost autorelease pool
/// equivalent to sending it the `autorelease` message
pub fn autorelease(id: ?*objc.Id) ?*objc.Id {
    return objc_autorelease(id);
}

/// makes a "best effort" to hand off ownership
/// to a call to retainAutoreleasedReturnValue
/// or to unsafeClaimAutoreleasedReturnValue
/// otherwise autoreleases the object
pub fn autoreleaseReturnValue(id: ?*objc.Id) ?*objc.Id {
    return objc_autoreleaseReturnValue(id);
}

/// srcPtr should be either null or an object
/// which has been registered as __weak
/// destPtr is initialized to be equivalent to src, potentially registering it
pub fn copyWeak(destPtr: *?*objc.Id, srcPtr: *?*objc.Id) void {
    objc_copyWeak(destPtr, srcPtr);
}

/// unregisters the given __weak object if it is non-null
/// equivalent to `storeWeak(selfPtr, null)`
pub fn destroyWeak(selfPtr: *?*objc.Id) void {
    objc_destroyWeak(selfPtr);
}

/// registers selfPtr as a weak object with value `value`
/// equivalent to the following code:
/// ```
/// selfPtr.* = null;
/// return storeWeak(selfPtr, value);
/// ```
pub fn initWeak(selfPtr: *?*objc.Id, value: ?*objc.Id) ?*objc.Id {
    return objc_initWeak(selfPtr, value);
}

/// loads a __weak object and autoreleases it
/// equivalent to `autorelease(loadWeakRetained(selfPtr))`
pub fn loadWeak(selfPtr: *?*objc.Id) ?*objc.Id {
    return objc_loadWeak(selfPtr);
}

/// loads a __weak object and retains it
pub fn loadWeakRetained(selfPtr: *?*objc.Id) ?*objc.Id {
    return objc_loadWeakRetained(selfPtr);
}

/// moves src to dest. may invalidate src or may not.
pub fn moveWeak(destPtr: *?*objc.Id, srcPtr: *?*objc.Id) void {
    objc_moveWeak(destPtr, srcPtr);
}

/// releases a previous retain (unreferencing it)
pub fn release(self: ?*objc.Id) void {
    objc_release(self);
}

/// retains an object (referencing it)
pub fn retain(self: ?*objc.Id) ?*objc.Id {
    return objc_retain(self);
}

/// retains and autoreleases an object
/// equivalent to `return autorelease(retain(self));
pub fn retainAutorelease(self: ?*objc.Id) ?*objc.Id {
    return objc_retainAutorelease(self);
}

/// equivalent to `return autoreleaseReturnValue(retain(self))`
pub fn retainAutoreleaseReturnValue(self: ?*objc.Id) ?*objc.Id {
    return objc_retainAutoreleaseReturnValue(self);
}

/// used to accept a handoff of `autoreleaseReturnValue`
pub fn retainAutoreleasedReturnValue(self: ?*objc.Id) ?*objc.Id {
    return objc_retainAutoreleasedReturnValue(self);
}

/// copies the block to the heap if it is on the stack
/// otherwise behaves as if it had been sent a `retain` message
pub fn retainBlock(block: ?*objc.Id) ?*objc.Id {
    return objc_retainBlock(block);
}

/// performs the complete sequence for assigning to a __strong object of non-block type
/// equivalent to the code
/// ```
/// const oldValue = objPtr.*;
/// objPtr.* = retain(value);
/// release(oldValue);
/// ```
pub fn storeStrong(objPtr: *?*objc.Id, value: ?*objc.Id) void {
    return objc_storeStrong(objPtr, value);
}

/// stores `value` to `objPtr` and returns the value of `objPtr` after this operation
/// registers objPtr as a __weak object
pub fn storeWeak(objPtr: *?*objc.Id, value: ?*objc.Id) ?*objc.Id {
    return objc_storeWeak(objPtr, value);
}

/// an opaque handle to an "autorelease pool",
/// which gathers the lifetimes of objects together to simplify releasing and retaining
pub const Pool = opaque {
    /// creates a new autorelease pool conceptually nested within the current pool
    /// makes the nested pool the current pool
    /// and returns a handle to this new pool
    pub fn push() *Pool {
        return @ptrCast(objc_autoreleasePoolPush());
    }

    /// releases all objects and pools owned by or nested within `self`
    /// makes the current pool the enclosing pool
    pub fn pop(self: *Pool) void {
        objc_autoreleasePoolPop(self);
    }
};

const objc = @import("lib.zig");
