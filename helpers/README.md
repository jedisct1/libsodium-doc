# Helpers

## Hexadecimal encoding/decoding

```c
char *sodium_bin2hex(char * const hex, const size_t hex_maxlen,
                     const unsigned char * const bin, const size_t bin_len);
```

The `sodium_bin2hex()` function converts `bin_len` bytes stored at `bin` into a hexadecimal string.

The string is stored into `hex` and includes a nul byte (`\0`) terminator.

`hex_maxlen` is the maximum number of bytes that the function is allowed to write starting at `hex`. It should be at least `bin_len * 2 + 1`.

The function returns `hex` on success, or `NULL` on overflow.

```c
int sodium_hex2bin(unsigned char * const bin, const size_t bin_maxlen,
                   const char * const hex, const size_t hex_len,
                   const char * const ignore, size_t * const bin_len,
                   const char ** const hex_end);
```

The `sodium_hex2bin()` function parses a hexadecimal string `hex` and converts it to a byte sequence.

`hex` do not have to be nul terminated, as the number of characters to parse is supplied via the `hex_len` parameter.

`ignore` is a string of characters to skip. For example, the string `": "` allows columns and spaces to be present at any locations in the hexadecimal string. These characters will just be ignored. As a result, `"69:FC"`, `"69 FC"`, `"69 : FC"` and `"69FC"` will be valid inputs, and will produce the same output.

`ignore` can be set to `NULL` in order to disallow any non-hexadecimal character.

`bin_maxlen` is the maximum number of bytes to put into `bin`.

The parser stops when a non-hexadecimal, non-ignored character is found or when `bin_maxlen` bytes have been written.

The function returns `-1` if more than `bin_maxlen` bytes would be required to store the parsed string.
It returns `0` on success, and sets `hex_end`, if it is not `NULL`, to a pointer to the character following the last parsed character.

## Constant-time comparison

```c
int sodium_memcmp(const void * const b1_, const void * const b2_, size_t len);
```

When a comparison involves secret data (e.g. key, authentication tag), is it critical to use a constant-time comparison function in order to mitigate side-channel attacks.

The `sodium_memcmp()` function can be used for this purpose.

It returns `0` is `len` bytes pointed by `b1_` are matching `len` bytes pointed by `b2_`.

It returns `-1` if they differ. **Note:** `sodium_memcmp()` is not a lexicographic comparator and
is not a generic replacement for `memcmp()`.

## Zeroing memory

```c
void sodium_memzero(void * const pnt, const size_t len);
```

After usage, sensitive data should be overwritten. But `memset()` and hand-written code can be silently stripped out by an optimizing compiler or by the linker.

The `sodium_memzero()` function tries to effectively zero `len` bytes starting at `pnt`, even if optimizations are being applied to the code.

## Locking memory

```c
int sodium_mlock(void * const addr, const size_t len);
```

The `sodium_mlock()` function locks at least `len` bytes of memory starting at `addr`. This can help to avoid sensitive data to be swapped to disk.

In addition, it is recommended to totally disable swap partitions on machines processing senstive data, or, as a second choice, to use encrypted swap partitions.

For similar reasons, on Unix systems, one should also disable core dumps when running crypto code outside a development environment. This can be achieved using a shell built-in such as `ulimit` or programatically using `setrlimit(RLIMIT_CORE, &(struct rlimit) {0, 0})`.
On operating systems where this feature is implemented, kernel crash dumps should also be disabled.

`sodium_mlock()` wraps `mlock()` and `VirtualLock()`. **Note:** Many systems place limits on the amount of memory that may be locked by a process. Care should be taken to raise those limits (e.g. Unix ulimits) where neccessary. `sodium_lock()` will return `-1` when any limit is reached.

```c
int sodium_munlock(void * const addr, const size_t len);
```

The `sodium_munlock()` function should be called after locked memory is not being used any more.
It will zero `len` bytes starting at `addr` before actually flagging the pages as swappable again. Calling `sodium_memzero()` prior to `sodium_munlock()` is thus not required.

On systems where it is supported, `sodium_mlock()` also wraps `madvise()` and advises the kernel not to include the locked memory in coredumps. `sodium_unlock()` also undoes this additional protection.

## Guarded heap allocations

Heartbleed was a serious vulnerability in OpenSSL. The ability to read past the end of a buffer is a serious bug, but what made it even worse is the fact that secret data could be disclosed by doing so.

In order to mitigate the impact of similar bugs, Sodium provides heap allocation functions for storing sensitive data.

These are not general-purpose allocation functions. In particular, they are slower than `malloc()` and friends, and require 3 or 4 extra pages of virtual memory.

```c
void *sodium_malloc(size_t size);
```

The `sodium_malloc()` function returns a pointer from which exactly `size` contiguous bytes of memory can be accessed.

The allocated region is placed at the end of a page boundary, immediately followed by a guard page. As a result, accessing memory past the end of the region will immediately terminate the application.

A canary is also placed right before the returned pointer. Modification of this canary are detected when trying to free the allocated region with `sodium_free()`, and also cause the application to immediately terminate.

An additional guard page is placed before this canary: in a Heartbleed-like scenario, the guard page is likely to be hit before the actual data, and will cause the application to terminate instead of leaking sensitive data.

The allocated region is filled with `0xd0` bytes in order to help catch bugs due to initialized data.

In addition, `sodium_mlock()` is called on the region to help avoiding it being swapped to disk. On operating systems supporting `MAP_NOCORE` or `MADV_DONTDUMP`, memory allocated that way will also not be part of core dumps.

The returned address will not be aligned if the allocation size is not a multiple of the required alignment. For this reason, `sodium_malloc()` should not be used to store structures mixing different data types.

```c
void *sodium_allocarray(size_t count, size_t size);
```

The `sodium_allocarray()` function returns a pointer from which `count` objects that are `size` bytes of memory each can be accessed.

It provides the same guarantees as `sodium_malloc()` but also protects against arithmetic overflows when `count * size` exceeds `SIZE_MAX`.

```c
void sodium_free(void *ptr);
```

The `sodium_free()` function unlocks and deallocates memory allocated using `sodium_malloc()` or `sodium_allocarray()`.

Prior to this, the canary is checked in order to detect possible buffer underflows and terminate the process if required.

`sodium_free()` also fills the memory region with zeros before the deallocation.

The function can be called even if the region was previously protected using `sodium_mprotect_noaccess()` or `sodium_mprotect_readonly()`; the protection will automatically be changed as needed.

`ptr` can be `NULL`, in which case no operations is performed.

```c
int sodium_mprotect_noaccess(void *ptr);
```

The `sodium_mprotect_noaccess()` function makes a region allocated using `sodium_malloc()` or `sodium_allocarray()` inaccessible. It cannot be read nor written, but the data are preserved.

This can be used to make confidential data inacessible except when actually needed for a specific operation.

```c
int sodium_mprotect_readonly(void *ptr);
```

The `sodium_mprotect_readonly()` function marks a region allocated using `sodium_malloc()` or `sodium_allocarray()` as read-only.

Attempting to modify the data will cause the process to terminate.

```c
int sodium_mprotect_readwrite(void *ptr);
```

The `sodium_mprotect_readwrite()` function marks a region allocated using `sodium_malloc()` or `sodium_allocarray()` as readable and writable, after having been protected using `sodium_mprotect_readonly()` or `sodium_mprotect_noaccess()`.
