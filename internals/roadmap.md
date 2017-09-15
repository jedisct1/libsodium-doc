# Roadmap

libsodium's roadmap is driven by its user community and new ideas are always welcome.

New features will be gladly implemented provided that they are not redundant and solve common problems.

## pre-1.0.0 roadmap

- AEAD construction \(ChaCha20Poly1305\)
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
- Higher-level API for crypto\_box
- Higher-level API for crypto\_secretbox
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

- Constant-time bin2hex\(\) \[DONE\] and hex2bin\(\) \[DONE\]
- Constant-time base64 codecs \[DONE\]
- Improve consistency and clarity of function prototypes
- Improve the documentation
- Consider `getrandom(2)` \[DONE\]
- Consider [Gitian](https://gitian.org/)
- Complete the sodium-validation project
- Optimized implementations for ARM w/NEON
- AVX optimized Curve25119 \[DONE\]
- Precomputed interface for crypto\_box\_easy\(\) \[DONE\]
- First-class support for Javascript \[DONE\]
- chacha20 and chacha20poly1305 with a 96 bit nonce and a 32 bit counter \[DONE\]
- IETF-compatible chacha20poly1305 implementation \[DONE\]
- Ed448-Goldilocks
- SSE-optimized BLAKE2b implementation \[DONE\]
- AES-GCM \[DONE\]
- AES-GCM detached mode \[DONE\]
- Use Montgomery reduction for GHASH
- ChaCha20-Poly1305 detached mode \[DONE\]
- Argon2i as crypto\_pwhash \[DONE\]
- Argon2id as crypto\_pwhash
- Multithreaded crypto\_pwhash
- Generic subkey derivation API \[DONE\]
- Nonce-misuse resistant scheme
- BLAKE2 AVX2 implementations \[DONE\]
- Keyed \(hash-then-encrypt\) crypto\_pwhash
- Consider BLAKE2X
- Argon2id \[DONE\]
- Port libhydrogen's key exchange API
- SSSE3 ChaCha20 implementation \[DONE\]
- SSSE3 Salsa20 implementation \[DONE\]
- SSSE3 Poly1305 implementation \[DONE\]
- AVX2 Salsa20 implementation \[DONE\]
- AVX2 ChaCha20 implementation \[DONE\]
- AVX2 Poly1305 implementation
- AVX512 implementations \[hardware needed for testing\]
- key generation API \[DONE\]
- Nonce/subkey generation API
- Webassembly support \[DONE\]
- Stream encryption using the CHAIN construction \[DONE\]
- Security audit by a 3rd party \[DONE\]
- Formally-verified implementations \[work in progress\]
- Padding API \[DONE\]
