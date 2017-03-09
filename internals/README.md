# Internals

## Naming conventions

Sodium follows the NaCl naming conventions.

Each operation defines functions and macros in a dedicated `crypto_operation` namespace. For example, the "hash" operation defines:

* A description of the underlying primitive: `crypto_hash_PRIMITIVE`
* Constants, such as key and output lengths: `crypto_hash_BYTES`
* For each constant, a function returning the same value. The name is identical to the constant, but all lowercase: `crypto_hash_bytes(void)`
* A set of functions with the same prefix, or being identical to the prefix: `crypto_hash()`

Low-level APIs are defined in the `crypto_operation_primitivename` namespace.  
For example, specific hash functions and their related macros are defined in the `crypto_hash_sha256`, `crypto_hash_sha512` and `crypto_hash_sha512256` namespaces.

To guarantee forward compatibilility, specific implementations are intentionally not directly accessible. The library is responsible for chosing the best working implementation at runtime.

For compatibility with NaCl, sizes of messages and ciphertexts are given as `unsigned long long` values.  
Other values representing the size of an object in memory use the standard `size_t` type.

## Thread safety

Initializing the random number generator is the only operation that requires an internal lock.

`sodium_init()` should be called before any other functions. It picks the best implementations for the current platform, initializes the random number generator and generates the canary for guarded heap allocations.

On POSIX systems, everything in libsodium is guaranteed to always be thread-safe.

## Heap allocations

Cryptographic operations in Sodium never allocate memory on the heap \(`malloc`, `calloc`, etc\) with the obvious exceptions of `crypto_pwhash` and `sodium_malloc`.

## Extra padding

For some operations, the traditional NaCl API requires extra zero bytes \(`*_ZEROBYTES`, `*_BOXZEROBYTES`\) before messages and ciphertexts.

However, this proved to be error-prone.

For this reason, functions whose input requires extra padding are discouraged in Sodium.

When not API compatibility is needed, alternative functions that do not require padding are available.

## Branches

Secrets are always compared in constant time using `sodium_memcmp()` or `crypto_verify_(16|32|64)()`.

## Alignment and endianness

All operations work on big endian and little endian systems, and do not require pointers to be aligned.

## C macros

C header files cannot be used in other programming languages.

For this reason, none of the documented functions are macros hiding the actual symbols.

## Testing

### Unit testing

The test suite covers all the functions, symbols and macros of a library built with `--enable-minimal`.

In addition to fixed test vectors, all functions include non-deterministic tests, using variable-length, random data.

Non-scalar parameters are stored into a region allocated with `sodium_malloc()` whenever possible. This immediately detects out-of-bounds accesses, including reads. The base address is also not guaranteed to be aligned, which to helps detect mishandling of unaligned data.

The Makefile for the test suite also includes a `check-valgrind` target, that checks that the whole suite passes with the Valgrind's memcheck, helgrind, drd and sgcheck modules.

### Static analysis

Continous static analysis of the Sodium source code is provided by Coverity and Facebook's Infer.

On Windows, static analysis is done using Visual Studio and Viva64 PVS-Studio.

The Clang static analyzer is also used on OSX and Linux.

Releases are never shipped until all these tools report zero defects.

### Dynamic analysis

Continuous Integration is provided by
[Travis](https://travis-ci.org/jedisct1/libsodium?branch=master) for
Linux/x86_64, and by
[AppVeyor](https://ci.appveyor.com/project/jedisct1/libsodium) for the
Visual Studio builds.

In addition, the test suite has to always pass on the following  
environments. Libsodium is manually validated on all of these before  
every release, as well as before merging a new change to the `stable`  
branch.

* asmjs/V8 \(node + in-browser\), asmjs/SpiderMonkey, asmjs/JavaScriptCore,
  asmjs/ChakraCore
* NativeClient/portable, NativeClient/x86\_64
* OpenBSD/x86\_64 using `gcc -fstack-protector-strong -fstack-shuffle`
* Ubuntu/x86\_64 using gcc 6, `-fsanitize=address,undefined` and Valgrind \(memcheck, helgrind, drd and sgcheck\)
* Ubuntu/x86\_64 using clang, `-fsanitize=address,undefined` and Valgrind \(memcheck, helgrind, drd and sgcheck\)
* Ubuntu/x86\_64 using tcc
* macOS using Xcode 8
* macOS using CompCert
* Windows 10 using Visual Studio 2010, 2012, 2013, 2015 and 2017
* msys2 using mingw32 and mingw64
* ArchLinux/x86\_64
* ArchLinux/armv6
* Debian/x86
* Debian/sparc
* Debian/ppc
* Ubuntu/aarch64 - Courtesy of the GCC compile farm project
* Fedora/ppc64 - Courtesy of the GCC compile farm project
* AIX 7.1/ppc64 - Courtesy of the GCC compile farm project
* Debian/mips64 - Courtesy of the GCC compile farm project

### Cross-implementation testing

\(in progress\)

[crypto test vectors](https://github.com/jedisct1/crypto-test-vectors) aims at generating large collections of test vectors for cryptographic primitives, produced by multiple implementations.

[libsodium validation](https://github.com/jedisct1/libsodium-validation) verifies that the output of libsodium's implementations are matching these test vectors. Each release has to pass all these tests on the platforms listed above.

## Bindings for other languages

Bindings are essential to the Libsodium ecosystem. It is expected that:

* New versions of Libsodium will be installed along with bindings written before these Libsodium versions were available.

* Recent versions of these bindings will be installed along with older versions of Libsodium \(e.g. stock package from a Linux distribution\).

For these reasons, ABI stability is critical:

* Symbols must not be removed from non-minimal builds without changing the major version of the library. Symbols must not be replaced with macros either.
* However, symbols that will eventually be removed can be tagged with GCC's `deprecated` attribute. They can also be removed from minimal builds.
* A data structure must considered opaque from an application perspective, and a structure size cannot change if that size was previously exposed as a constant. Structures whose size are subject to changes must only expose their size through a function.

Any major change to the library should be tested for compatibility with popular bindings, especially those recompiling a copy of the library.

