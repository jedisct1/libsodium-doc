# Securing memory allocations

## Zeroing memory

```c
void sodium_memzero(void * const pnt, const size_t len);
```

After use, sensitive data should be overwritten, but `memset()` and hand-written
code can be silently stripped out by an optimizing compiler or the linker.

The `sodium_memzero()` function tries to effectively zero `len` bytes starting
at `pnt`, even if optimizations are being applied to the code.

## Locking memory

```c
int sodium_mlock(void * const addr, const size_t len);
```

The `sodium_mlock()` function locks at least `len` bytes of memory starting at
`addr`. This can help avoid swapping sensitive data to disk.

In addition, it is recommended to disable swap partitions on machines
processing sensitive data or, as a second choice, use encrypted swap
partitions.

For similar reasons, on Unix systems, one should also disable core dumps when
running crypto code outside a development environment. This can be achieved
using a shell built-in such as `ulimit` or programmatically using
`setrlimit(RLIMIT_CORE, &(struct rlimit) {0, 0})`. On operating systems where
this feature is implemented, kernel crash dumps should also be disabled.

`sodium_mlock()` wraps `mlock()` and `VirtualLock()`. **Note:** Many systems
place limits on the amount of memory that may be locked by a process. Care
should be taken to raise those limits (e.g. Unix ulimits) where necessary.
`sodium_mlock()` will return `-1` when any limit is reached.

```c
int sodium_munlock(void * const addr, const size_t len);
```

The `sodium_munlock()` function should be called after locked memory is not
being used anymore. It will zero `len` bytes starting at `addr` before flagging
the pages as swappable again. Calling `sodium_memzero()` prior to
`sodium_munlock()` is thus not required.

On systems where it is supported, `sodium_mlock()` also wraps `madvise()` and
advises the kernel not to include the locked memory in core dumps.
`sodium_munlock()` also undoes this additional protection.

## Guarded heap allocations

Sodium provides heap allocation functions for storing sensitive data.

These are not general-purpose allocation functions. In particular, they are
slower than `malloc()` and friends and require 3 or 4 extra pages of
virtual memory.

`sodium_init()` must be called before using any of the guarded heap allocation
functions.

```c
void *sodium_malloc(size_t size);
```

The `sodium_malloc()` function returns a pointer from which exactly `size`
contiguous bytes of memory can be accessed. Like normal `malloc`, `NULL`
may be returned and `errno` set if it is not possible to allocate enough
memory.

The allocated region is placed at the end of a page boundary, immediately
followed by a guard page. As a result, accessing memory past the end of the
region will immediately terminate the application.

A canary is also placed right before the returned pointer. Modifications of this
canary are detected when trying to free the allocated region with
`sodium_free()` and cause the application to immediately terminate.

An additional guard page is placed before this canary to make it less likely for
sensitive data to be accessible when reading past the end of an unrelated
region.

The allocated region is filled with `0xdb` bytes to help catch bugs due
to uninitialized data.

In addition, `sodium_mlock()` is called on the region to help avoid it being
swapped to disk. On operating systems supporting `MAP_NOCORE` or
`MADV_DONTDUMP`, memory allocated this way will also not be part of core dumps.

The returned address will not be aligned if the allocation size is not a
multiple of the required alignment.

For this reason, `sodium_malloc()` should not be used with packed or
variable-length structures unless the size given to `sodium_malloc()` is
rounded up to ensure proper alignment.

All the structures used by libsodium can safely be allocated using
`sodium_malloc()`.

Allocating `0` bytes is a valid operation. It returns a pointer that can be
successfully passed to `sodium_free()`.

```c
void *sodium_allocarray(size_t count, size_t size);
```

The `sodium_allocarray()` function returns a pointer from which `count` objects
that are `size` bytes of memory each can be accessed.

It provides the same guarantees as `sodium_malloc()` but also protects against
arithmetic overflows when `count * size` exceeds `SIZE_MAX`.

```c
void sodium_free(void *ptr);
```

The `sodium_free()` function unlocks and deallocates memory allocated using
`sodium_malloc()` or `sodium_allocarray()`.

Before this, the canary is checked to detect possible buffer
underflows and terminate the process if required.

`sodium_free()` also fills the memory region with zeros before the deallocation.

This function can be called even if the region was previously protected using
`sodium_mprotect_readonly()`; the protection will automatically be changed as
needed.

`ptr` can be `NULL`, in which case no operation is performed.

```c
int sodium_mprotect_noaccess(void *ptr);
```

The `sodium_mprotect_noaccess()` function makes a region allocated using
`sodium_malloc()` or `sodium_allocarray()` inaccessible. It cannot be read or
written, but the data are preserved.

This function can be used to make confidential data inaccessible except when
needed for a specific operation.

```c
int sodium_mprotect_readonly(void *ptr);
```

The `sodium_mprotect_readonly()` function marks a region allocated using
`sodium_malloc()` or `sodium_allocarray()` as read-only.

Attempting to modify the data will cause the process to terminate.

```c
int sodium_mprotect_readwrite(void *ptr);
```

The `sodium_mprotect_readwrite()` function marks a region allocated using
`sodium_malloc()` or `sodium_allocarray()` as readable and writable after
having been protected using `sodium_mprotect_readonly()` or
`sodium_mprotect_noaccess()`.
