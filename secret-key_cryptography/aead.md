# Authenticated Encryption with Additional Data

This operation:

* Encrypts a message with a key and a nonce to keep it confidential
* Computes an authentication tag. This tag is used to make sure that the message, as well as optional, non-confidential \(non-encrypted\) data, haven't been tampered with.

A typical use case for additional data is to store protocol-specific metadata about the message, such as its length and encoding.

## Supported constructions

Libsodium supports two popular constructions: AES256-GCM and ChaCha20-Poly1305, as well as a variant of the later with an extended nonce: XChaCha20-Poly1305.

### AES256-GCM

The current implementation of this construction is hardware-accelerated and requires the Intel SSSE3 extensions, as well as the `aesni` and `pclmul` instructions.

Intel Westmere processors \(introduced in 2010\) and newer meet the requirements.

There are no plans to support non hardware-accelerated implementations of AES-GCM, as correctly mitigating side-channels in a software implementation comes with major speed tradeoffs, that defeat the whole point of AES-GCM over ChaCha20-Poly1305.

### ChaCha20-Poly1305

While AES is very fast on dedicated hardware, its performance on platforms that lack such hardware is considerably lower. Another problem is that many software AES implementations are vulnerable to cache-collision timing attacks.

ChaCha20 is considerably faster than AES in software-only implementations, making it around three times as fast on platforms that lack specialized AES hardware. ChaCha20 is also not sensitive to timing attacks.

Poly1305 is a high-speed message authentication code.

The combination of the ChaCha20 stream cipher with the Poly1305 authenticator was proposed in January 2014 as an alternative to the Salsa20-Poly1305 construction. ChaCha20-Poly1305 was implemented in major operating systems, web browsers and crypto libraries shortly after. It eventually became an official IETF standard in May 2015.

The ChaCha20-Poly1305 implementation in Libsodium is portable across all supported architectures, and is the recommended choice for most applications.

### XChaCha20-Poly1305

XChaCha20-Poly1305 applies the construction described in Daniel Bernstein's [Extending the Salsa20 nonce](https://cr.yp.to/snuffle/xsalsa-20081128.pdf) paper to the ChaCha20 cipher in order to extend the nonce size to 192-bit.

This extended nonce size allows random nonces to be safely used, and also facilitates the construction of misuse-resistant schemes.

The only limitation of XChaCha20-Poly1305 is that it is not widely implemented in other libraries yet.

