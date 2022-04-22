# Internals

## Naming conventions

Sodium follows the NaCl naming conventions.

Each operation defines functions and macros in a dedicated `crypto_operation`
namespace. For example, the "hash" operation defines:

- A description of the underlying primitive: `crypto_hash_PRIMITIVE`.
- Constants, such as key and output lengths: `crypto_hash_BYTES`.
- For each constant, a function returning the same value. The name is identical
  to the constant but all lowercase: `crypto_hash_bytes(void)`.
- A set of functions with the same prefix or identical to the prefix:
  `crypto_hash()`.

Low-level APIs are defined in the `crypto_operation_primitivename` namespace.
For example, specific hash functions and their related macros are defined in the
`crypto_hash_sha256`, `crypto_hash_sha512`, and `crypto_hash_sha512256`
namespaces.

To guarantee forward compatibility, specific implementations are intentionally
not directly accessible. The library is responsible for choosing the best working
implementation at runtime.

For compatibility with NaCl, the size of messages and ciphertexts are given as
`unsigned long long` values. Other values representing the size of an object in
memory use the standard `size_t` type.

## Avoiding type confusion

An object type has only one public representation.

Points and scalars are always accepted and returned as a fixed-size, compressed, portable, and serializable bit string.

This simplifies usage and mitigates type confusion in languages that don't enforce strict type safety.

## Thread safety

Initializing the random number generator is the only operation that requires an
internal lock.

`sodium_init()` must be called before any other function. It picks the best
implementations for the current platform, initializes the random number
generator, and generates the canary for guarded heap allocations.

On POSIX systems, everything in libsodium is guaranteed to be
thread-safe.

## Heap allocations

Cryptographic operations in Sodium never allocate memory on the heap \(`malloc`,
`calloc`, etc\), except for `crypto_pwhash` and `sodium_malloc`.

## Prepended zeros

For some operations, the traditional NaCl API requires extra zero bytes
\(`*_ZEROBYTES`, `*_BOXZEROBYTES`\) before messages and ciphertexts.

However, this proved to be error-prone. Therefore, functions whose input
requires transformations before they can be used are discouraged in Sodium.

When NaCl API compatibility is required, alternative functions that do not
require extra steps are available and recommended.

## Branches

Secrets are always compared in constant time using `sodium_memcmp()` or
`crypto_verify_(16|32|64)()`.

## Alignment and endianness

All operations work on big-endian and little-endian systems and do not require
pointers to be aligned.

## C macros

C header files cannot be used in other programming languages.

For this reason, none of the documented functions are macros hiding the actual
symbols.

## Security first

When a balance is required, extra safety measures have a higher priority than
speed. Examples include:

- Sensitive data is wiped from memory when the cost remains
  reasonable compared to the cost of the actual computations.
- Signatures use different code paths for verification to mitigate
  fault attacks and check for small order nonces.
- X25519 checks for weak public keys.
- Heap memory allocations ensure that pages are not swapped and cannot be shared
  with other processes.
- The code is optimized for clarity, not for the number of lines of code. Except for
  trivial inlined functions (e.g. helpers for unaligned
  memory access), implementations are self-contained.
- The default compiler flags use a conservative optimization level, with extra
  code to check for stack overflows and some potentially dangerous
  optimizations disabled. The `--enable-opt` switch remains available for more
  aggressive optimizations.
- A complete, safe, and consistent API is favored over compact code. Redundancy
  of trivial functions is acceptable to improve clarity and prevent potential
  bugs in applications. For example, every operation gets a dedicated
  `_keygen()` function.
- The default PRG doesn't implement something complicated and potentially
  insecure in userland to save CPU cycles. It is fast enough for most
  applications while being guaranteed to be thread-safe and fork-safe in all
  cases. If thread safety is not required, a faster, simple, and provably secure
  userland implementation is provided.
- The code includes many internal consistency checks and will defensively
  `abort()` if something unusual is detected. This requires a few extra
  checks but is useful for spotting internal and application-specific bugs that
  tests don't catch.

## Testing

### Unit testing

The test suite covers all the functions, symbols, and macros of the library built
with `--enable-minimal`.

In addition to fixed test vectors, all functions include non-deterministic
tests using variable-length, random data.

Non-scalar parameters are stored into a region allocated with `sodium_malloc()`
whenever possible. This immediately detects out-of-bounds accesses, including
reads. The base address is also not guaranteed to be aligned, which helps
detect mishandling of unaligned data.

The Makefile for the test suite also includes a `check-valgrind` target, which
checks that the whole suite passes with the Valgrind's Memcheck, Helgrind, DRD,
and SGCheck modules.

### Static analysis

Continuous static analysis of the Sodium source code is performed using Coverity and
GitHub's CodeQL scanner.

On Windows, static analysis is done using Visual Studio and Viva64 PVS-Studio.

The Clang static analyzer is also used on macOS and Linux.

Releases are never shipped until all these tools report zero defects.

### Dynamic analysis

Continuous Integration is provided by
[Azure Pipelines](https://jedisct1.visualstudio.com/Libsodium),
[Travis](https://travis-ci.com/jedisct1/libsodium?branch=stable),
[GitHub Actions](https://github.com/jedisct1/libsodium/actions), and
[AppVeyor](https://ci.appveyor.com/project/jedisct1/libsodium).

In addition, the test suite must pass on the following environments.
Libsodium is manually validated on all of these before every release and
before merging a new change to the `stable` branch.

- asmjs/V8 \(node + in-browser\), asmjs/SpiderMonkey, asmjs/JavaScriptCore
- WebAssembly/V8, WebAssembly/Firefox, WebAssembly/WASI using zig cc
- OpenBSD-current/x86_64
- Ubuntu/x86_64 using GCC 12, `-fsanitize=address,undefined` and Valgrind
  \(Memcheck, Helgrind, DRD, and SGCheck\)
- Ubuntu/x86_64 using Clang 14, `-fsanitize=address,undefined` and Valgrind
  \(Memcheck, Helgrind, DRD, and SGCheck\)
- Ubuntu/x86_64 using TCC
- Ubuntu/x86_64 using CompCert
- macOS using Xcode 13
- macOS using zig cc
- Windows 10 using Visual Studio 2017, 2019, and 2022 (x86 and x86_64)
- MSYS2 using MinGW32 and MinGW64
- Arch Linux/x86_64
- Arch Linux/ARMv6
- Debian/x86
- Debian/SPARC
- Debian/ppc
- Raspbian/Cortex-A53
- iOS/A12 (iSH)
- Ubuntu/AArch64 - Courtesy of the GCC Compile Farm project
- Fedora/ppc64 - Courtesy of the GCC Compile Farm project
- AIX 7.1/ppc64 - Courtesy of the GCC Compile Farm project
- Debian/MIPS64 - Courtesy of the GCC Compile Farm project

### Cross-implementation testing

[crypto test vectors](https://github.com/jedisct1/crypto-test-vectors) aims to
generate large collections of test vectors for cryptographic primitives
using different implementations.

[libsodium validation](https://github.com/jedisct1/libsodium-validation)
verifies that the output of libsodium's implementations match the test
vectors. Each release must pass all these tests on the platforms listed above.

## Bindings for other languages

Bindings are essential to the libsodium ecosystem. It is expected that:

- New versions of libsodium will be installed along with bindings written before
  these libsodium versions were available.
- Recent versions of these bindings will be installed along with older versions
  of libsodium \(e.g. a stock package from a Linux distribution\).

For these reasons, ABI stability is critical:

- Symbols must not be removed from non-minimal builds without changing the major
  version of the library. Symbols must not be replaced with macros either.
- However, symbols that will eventually be removed can be tagged with GCC's
  `deprecated` attribute. They can also be removed from minimal builds.
- A data structure must be considered opaque from an application perspective, and a
  structure size cannot change if that size was previously exposed as a
  constant. Structures whose size are subject to change must only expose their
  size through a function.

Any major change to the library should be tested for compatibility with popular
bindings, especially those recompiling a copy of the library.
