# Roadmap

libsodium's roadmap is driven by its user community and new ideas are always welcome.

New features will be gladly implemented provided that they are not redundant and solve common problems.

## pre-1.0.0 roadmap

- AEAD construction (ChaCha20Poly1305)
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
- FP rounding mode independent poly1305 implementation
- Faster portable curve25519 implementation
- Fix undefined behaviors for C99
- Guarded memory
- HMAC-SHA512, HMAC-SHA256
- Hex codec
- Hide specific implementations, expose wrappers
- Higher-level API for crypto_box
- Higher-level API for crypto_secretbox
- Lift `ZEROBYTES` requirements
- Make all constants accessible via public functions
- MingW port
- Minimal build mode
- NuGet packages
- Password hashing
- Pluggable random number generator
- Portable memory locking
- Position-independent code
- Replace the build system with autotools/libtool
- Runtime CPU features detection
- Secure memory zeroing
- Seed and public key extraction from an ed25519 secret key
- SipHash
- Streaming support for hashing and authentication
- Streaming support for one-time authentication
- Support for arbitrary HMAC key lengths
- Support for architectures requiring strict alignment
- Visual Studio port
- 100% code coverage, static and dynamic analysis
- `arc4random*()` compatible API
- ed25519 to curve25519 keys conversion
- iOS/Android compatibility

## 1.0.x roadmap

- Constant-time bin2hex() [DONE] and hex2bin() [DONE]
- Improve consistency and clarity of function prototypes
- Improve documentation
- Consider `getrandom(2)` [DONE]
- Consider [Gitian](https://gitian.org/)
- Complete the sodium-validation project [IN PROGRESS]
- Optimized implementations for ARM w/NEON
- AVX optimized Curve25119 [DONE]
- Precomputed interface for crypto_box_easy() [DONE]
- First-class support for Javascript [DONE]
- SIMD implementations of ChaCha20 [DONE]
- SIMD implementations of Poly1305 [DONE]
- chacha20 and chacha20poly1305 with a 96 bit nonce and a 32 bit counter [DONE]
- IETF-compatible chacha20poly1305 implementation [DONE]
- Ed448-Goldilocks
- SSE-optimized BLAKE2b implementation [DONE]
- AES-GCM [DONE]
- AES-GCM detached mode
- Argon2i as crypto_pwhash [IN PROGRESS]
- Multithreaded crypto_pwhash
- High-level key exchange API
- Generic subkey derivation API
- HS1-SIV or other nonce-misuse resistant scheme
