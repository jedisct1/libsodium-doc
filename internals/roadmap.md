# Roadmap

libsodium’s roadmap is driven by its user community, and new ideas are always welcome.

New features will gladly be implemented if they are not redundant and solve common problems.

## pre-1.0.0 roadmap

  - AEAD construction (ChaCha20-Poly1305)
  - API to set initial counter value in ChaCha20/Salsa20
  - Big-endian compatibility
  - BLAKE2
  - ChaCha20
  - Constant-time comparison
  - Cross-compilation support
  - Detached authentication for `crypto_box()` and `crypto_secretbox()`
  - Detached signatures
  - Deterministic key generation for `crypto_box()`
  - Deterministic key generation for `crypto_sign()`
  - Documentation
  - Ed25519 signatures
  - Emscripten support
  - FP rounding mode independent Poly1305 implementation
  - Faster portable Curve25519 implementation
  - Fix undefined behaviors for C99
  - Guarded memory
  - HMAC-SHA512, HMAC-SHA256
  - Hex codec
  - Hide specific implementations, expose wrappers
  - Higher-level API for crypto\_box
  - Higher-level API for crypto\_secretbox
  - Lift `ZEROBYTES` requirements
  - Make all constants accessible via public functions
  - MinGW port
  - Minimal build mode
  - NuGet packages
  - Password hashing
  - Pluggable random number generator
  - Portable memory locking
  - Position-independent code
  - Replace the build system with Autotools/Libtool
  - Runtime CPU features detection
  - Secure memory zeroing
  - Seed and public key extraction from an Ed25519 secret key
  - SipHash
  - Streaming support for hashing and authentication
  - Streaming support for one-time authentication
  - Support for arbitrary HMAC key lengths
  - Support for architectures requiring strict alignment
  - Visual Studio port
  - 100% code coverage, static and dynamic analysis
  - `arc4random*()` compatible API
  - Ed25519 to X25519 keys conversion
  - iOS/Android compatibility

## 1.0.x roadmap

  - Constant-time bin2hex() \[DONE\] and hex2bin() \[DONE\]
  - Constant-time base64 codecs \[DONE\]
  - Improve consistency and clarity of function prototypes
  - Improve the documentation
  - Consider `getrandom(2)` \[DONE\]
  - Consider [Gitian](https://gitian.org/)
  - Complete the sodium-validation project
  - Optimized implementations for ARM w/NEON
  - AVX optimized Curve25119 \[DONE\]
  - Precomputed interface for crypto\_box\_easy() \[DONE\]
  - First-class support for JavaScript \[DONE\]
  - ChaCha20 and ChaCha20-Poly1305 with a 96-bit nonce and a 32-bit counter \[DONE\]
  - IETF-compatible ChaCha20-Poly1305 implementation \[DONE\]
  - SSE-optimized BLAKE2b implementation \[DONE\]
  - AES-GCM \[DONE\]
  - AES-GCM detached mode \[DONE\]
  - Use Montgomery reduction for GHASH
  - ChaCha20-Poly1305 detached mode \[DONE\]
  - Argon2i as crypto\_pwhash \[DONE\]
  - Argon2id as crypto\_pwhash \[DONE\]
  - Multithreaded crypto\_pwhash \[on hold\]
  - Generic subkey derivation API \[DONE\]
  - Nonce misuse-resistant scheme
  - BLAKE2 AVX2 implementations \[DONE\]
  - Keyed (Hash-then-Encrypt) crypto\_pwhash
  - Consider yescrypt
  - Argon2id \[DONE\]
  - Port libhydrogen’s key exchange API
  - SSSE3 ChaCha20 implementation \[DONE\]
  - SSSE3 Salsa20 implementation \[DONE\]
  - SSSE3 Poly1305 implementation \[DONE\]
  - AVX2 Salsa20 implementation \[DONE\]
  - AVX2 ChaCha20 implementation \[DONE\]
  - AVX2 Poly1305 implementation
  - AVX512 implementations \[done for Argon2, withhold for other operations due to throttling concerns\]
  - Key generation API \[DONE\]
  - Nonce/subkey generation API
  - WebAssembly support \[DONE\]
  - Stream encryption using a CHAIN-like construction \[DONE\]
  - Security audit by a 3rd party \[DONE\]
  - Formally-verified implementations \[on hold\]
  - Padding API \[DONE\]
  - `secretstream_inject()` for nonce misuse-resistance \[on hold\]
  - Point addition, subtraction \[DONE\]
  - Point validation \[DONE\]
  - Hash-to-point (Elligator) \[DONE\]
  - SPAKE2+ \[DONE\]
  - Support server relief in the password hashing API
  - Ristretto \[DONE\]
  - Consider a streaming interface for `crypto_shorthash_*()`
  - AEGIS-256 \[DONE\]
  - AEGIS-128L \[DONE\]
  - AEGIS-based `secretstream` API \[PoC exists\]
  - HKDF/SHA-512 and HKDF/SHA-256 \[DONE\]
  - Standard hash-to-curve \[DONE\]
  - Consider [signcryption](https://github.com/jedisct1/libsodium-signcryption)
  - High-level AEAD and `secretstream` APIs
  - Consider ECVRF \[in progress\]
  - Consider FROST
  - Consider using TIMECOP2
  - Keep an eye on jq255
  - Consider [bscrypt](https://github.com/Sc00bz/bscrypt)
  - Check/mitigate the implications of the [DIT](https://developer.arm.com/documentation/ddi0601/2020-12/AArch64-Registers/DIT--Data-Independent-Timing) and [DOITM](https://www.intel.com/content/www/us/en/developer/articles/technical/software-security-guidance/best-practices/data-operand-independent-timing-isa-guidance.html) flags.
  - Consider SHAKE/TurboSHAKE/KangarooTwelve
  - AEGIS-128X and 256X
  - Add more ARM optimized implementations
  - Add AEGIS-based `crypto_auth` APIs
  - Consider AES-GCM-SIV
  - Parallel Argon2
  - Consider a streaming interface to Ed25519 signatures
  - Batch signatures
  - HPKE
  - ML-KEM
  - CHERI support for the allocation functions
  - See if `wasm32-freestanding` can be supported

## 2.0.0 roadmap

  - Switch to a new API (libhydrogen/WASI-crypto)
  - Session support
