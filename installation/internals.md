# Internals

## Naming conventions

Sodium follows the NaCl naming conventions.

Each operation defines functions and macros in a dedicated `crypto_operation` namespace. For example, the "hash" operation defines:

- A description of the underlying primitive: `crypto_hash_PRIMITIVE`
- Constants, such as key and output lengths: `crypto_hash_BYTES`
- For each constant, a function returning the same value. The name is identical to the constant, but all lowercase: `crypto_hash_bytes(void)`
- A set of functions with the same prefix, or being identical to the prefix: `crypto_hash()`

Low-level APIs are defined in the `crypto_operation_primitivename` namespace.
For example, specific hash functions and their related macros are defined in the `crypto_hash_sha256`, `crypto_hash_sha512` and `crypto_hash_sha512256` namespaces.

To guarantee forward compatibilility, specific implementations are intentionally not directly accessible. The library is responsible for chosing the best working implementation at runtime.

For compatibility with NaCl, sizes of messages and ciphertexts are given as `unsigned long long` values.

## Thread safety

Initializing the random number generator is the only operation which is not thread-safe.

`sodium_init()` should be called once before any operation. It picks the best implementations for the current platform, initializes the random number generator and generates the canary for guarded heap allocations.

After `sodium_init()` has been called, everything in libsodium is guaranteed to always be thread-safe.

## Heap allocations

Cryptographic operations in Sodium never allocate memory on the heap (`malloc`, `calloc`, etc) with the obvious exception of `crypto_pwhash`.

## Extra padding

For some operations, the traditional NaCl API requires extra zero bytes (`*_ZEROBYTES`, `*_BOXZEROBYTES`) before messages and ciphertexts.

However, this proved to be error-prone.

For this reason, functions whose input requires extra padding are discouraged in Sodium.

When API compatibility is needed, alternative functions that do not require padding are also made available.

## Branches

Secrets are always compared in constant time using `sodium_memcmp()` or `crypto_verify_(16|32|64)()`.

## Alignment and endianness

All operations work on big endian and little endian systems, and do not require pointers to be aligned.

## C macros

C header files cannot be used in other programming languages.

For this reason, none of the documented functions are macros hiding the actual symbols.

