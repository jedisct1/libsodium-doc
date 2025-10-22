# Securing memory allocations

## Zeroing memory

```c
void sodium_memzero(void * const pnt, const size_t len);
```

After use, sensitive data should be overwritten, but `memset()` and hand-written code can be silently stripped out by an optimizing compiler or the linker.

The `sodium_memzero()` function tries to effectively zero `len` bytes starting at `pnt`, even if optimizations are being applied to the code.

## Locking memory

```c
int sodium_mlock(void * const addr, const size_t len);
```

The `sodium_mlock()` function locks at least `len` bytes of memory starting at `addr`. This can help avoid swapping sensitive data to disk.

In addition, it is recommended to disable swap partitions on machines processing sensitive data or, as a second choice, use encrypted swap partitions.

For similar reasons, on Unix systems, one should also disable core dumps when running crypto code outside a development environment. This can be achieved using a shell built-in such as `ulimit` or programmatically using `setrlimit(RLIMIT_CORE, &(struct rlimit) {0, 0})`. On operating systems where this feature is implemented, kernel crash dumps should also be disabled.

`sodium_mlock()` wraps `mlock()` and `VirtualLock()`. **Note:** Many systems place limits on the amount of memory that may be locked by a process. Care should be taken to raise those limits (e.g. Unix ulimits) where necessary. `sodium_mlock()` will return `-1` when any limit is reached.

```c
int sodium_munlock(void * const addr, const size_t len);
```

The `sodium_munlock()` function should be called after locked memory is not being used anymore. It will zero `len` bytes starting at `addr` before flagging the pages as swappable again. Calling `sodium_memzero()` prior to `sodium_munlock()` is thus not required.

On systems where it is supported, `sodium_mlock()` also wraps `madvise()` and advises the kernel not to include the locked memory in core dumps. `sodium_munlock()` also undoes this additional protection.

## Guarded heap allocations

Sodium provides heap allocation functions for storing sensitive data.

These are not general-purpose allocation functions. In particular, they are slower than `malloc()` and friends and require 3 or 4 extra pages of virtual memory.

`sodium_init()` must be called before using any of the guarded heap allocation functions.

```c
void *sodium_malloc(size_t size);
```

The `sodium_malloc()` function returns a pointer from which exactly `size` contiguous bytes of memory can be accessed. Like normal `malloc`, `NULL` may be returned and `errno` set if it is not possible to allocate enough memory.

The allocated region is placed at the end of a page boundary, immediately followed by a guard page (or an emulation, if unsupported by the platform). As a result, accessing memory past the end of the region will immediately terminate the application.

A canary is also placed right before the returned pointer. Modifications of this canary are detected when trying to free the allocated region with `sodium_free()` and cause the application to immediately terminate.

If supported by the platform, an additional guard page is placed before this canary to make it less likely for sensitive data to be accessible when reading past the end of an unrelated region.

The allocated region is filled with `0xdb` bytes to help catch bugs due to uninitialized data.

In addition, `mlock()` is called on the region to help avoid it being swapped to disk. Note however that `mlock()` may not be supported, may fail or may be a no-op, in which case `sodium_malloc()` will return the memory regardless, but it will not be locked. If you specifically need to rely on memory locking, consider calling `sodium_mlock()` and checking its return value.

On operating systems supporting `MAP_NOCORE` or `MADV_DONTDUMP`, memory allocated this way will also not be part of core dumps.

The returned address will not be aligned if the allocation size is not a multiple of the required alignment.

For this reason, `sodium_malloc()` should not be used with packed or variable-length structures unless the size given to `sodium_malloc()` is rounded up to ensure proper alignment.

All the structures used by libsodium can safely be allocated using `sodium_malloc()`.

Allocating `0` bytes is a valid operation. It returns a pointer that can be successfully passed to `sodium_free()`.

```c
void *sodium_allocarray(size_t count, size_t size);
```

The `sodium_allocarray()` function returns a pointer from which `count` objects that are `size` bytes of memory each can be accessed.

It provides the same guarantees as `sodium_malloc()` but also protects against arithmetic overflows when `count * size` exceeds `SIZE_MAX`.

```c
void sodium_free(void *ptr);
```

The `sodium_free()` function unlocks and deallocates memory allocated using `sodium_malloc()` or `sodium_allocarray()`.

Before this, the canary is checked to detect possible buffer underflows and terminate the process if required.

`sodium_free()` also fills the memory region with zeros before the deallocation.

This function can be called even if the region was previously protected using `sodium_mprotect_readonly()`; the protection will automatically be changed as needed.

`ptr` can be `NULL`, in which case no operation is performed.

```c
int sodium_mprotect_noaccess(void *ptr);
```

The `sodium_mprotect_noaccess()` function makes a region allocated using `sodium_malloc()` or `sodium_allocarray()` inaccessible. It cannot be read or written, but the data are preserved.

This function can be used to make confidential data inaccessible except when needed for a specific operation.

```c
int sodium_mprotect_readonly(void *ptr);
```

The `sodium_mprotect_readonly()` function marks a region allocated using `sodium_malloc()` or `sodium_allocarray()` as read-only.

Attempting to modify the data will cause the process to terminate.

```c
int sodium_mprotect_readwrite(void *ptr);
```

The `sodium_mprotect_readwrite()` function marks a region allocated using `sodium_malloc()` or `sodium_allocarray()` as readable and writable after having been protected using `sodium_mprotect_readonly()` or `sodium_mprotect_noaccess()`.

## Notes on memory locking

While `mlock()` and `sodium_mlock()` are useful for preventing heap-allocated data from being swapped to disk, they have important limitations that developers should understand.

First, `mlock()` is not adequate for protecting data placed on the stack or in CPU registers. Temporary variables, function parameters, and intermediate values created during computation often reside on the stack or in registers, and this data may be swapped to disk. The stack cannot be reliably locked with `mlock()` because it only locks pages that exist at the time of the call. If the stack later grows into new pages, those new pages will not be locked.

Furthermore, even data stored in locked heap pages will typically be copied to the stack and registers when it is actually used. When sensitive data is read from locked memory for processing, the compiler will generally load it into CPU registers for computation, and may spill intermediate values to the stack. These copies exist outside the locked heap region and are subject to the same limitations described above.

Second, memory locking is constrained by the `RLIMIT_MEMLOCK` resource limit, which restricts the amount of memory a process can lock. On some systems, raising this limit requires the `CAP_IPC_LOCK` capability. If a process exceeds this limit, `mlock()` will fail and return `ENOMEM`. Applications that need to lock substantial amounts of memory must ensure the limit is appropriately configured.

For applications that require comprehensive protection of the stack, one approach is to lock all memory in the process using `mlockall(MCL_CURRENT | MCL_FUTURE)`. The `MCL_CURRENT` flag locks all currently mapped pages, while `MCL_FUTURE` ensures that all pages mapped in the future are also locked. However, this approach has practical implications: it increases memory pressure, may require elevated resource limits, and can impact application performance.

Despite these techniques, protecting CPU registers from being swapped to disk is fundamentally impossible with current operating system interfaces. Registers may be saved to the stack during context switches, interrupt handling, or when the kernel pages out a process.

Therefore, if cold boot attacks or at-rest data protection are serious concerns for your threat model, the most effective defense is to encrypt the entire disk volume and encrypt the swap partition (or disable swap entirely). Encryption at rest ensures that even if memory contents are written to disk, they remain protected. Memory locking should be viewed as a defense-in-depth measure, not a complete solution for preventing sensitive data from ever reaching persistent storage.
