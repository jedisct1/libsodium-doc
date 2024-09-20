# Authenticated Encryption with Additional Data

This operation:

- Encrypts a message with a key and a nonce to keep it confidential
- Computes an authentication tag. This tag is used to make sure that the message, as well as optional, non-confidential (non-encrypted) data, haven’t been tampered with.

A typical use case for additional data is to authenticate protocol-specific metadata about the message, such as its length and encoding.

## Supported constructions

libsodium supports two popular constructions: AES256-GCM and ChaCha20-Poly1305 (original version and IETF version), as well as a variant of the later with an extended nonce: XChaCha20-Poly1305.

The “combined mode” API of each construction appends the authentication tag to the ciphertext. The “detached mode” API stores the authentication tag in a separate location.

### Availability and interoperability

| Construction            | Key size | Nonce size | Block size | MAC size | Availability                                                                                                |
| :---------------------- | :------- | :--------- | :--------- | :------- | :---------------------------------------------------------------------------------------------------------- |
| AEGIS-128L              | 128 bits | 128 bits   | 256 bits   | 256 bits | libsodium \>= 1.0.19. On the standard track.                                                                |
| AEGIS-256               | 256 bits | 256 bits   | 128 bits   | 256 bits | libsodium \>= 1.0.19. On the standard track.                                                                |
| AES256-GCM              | 256 bits | 96 bits    | 128 bits   | 128 bits | libsodium \>= 1.0.4 but requires hardware support. IETF standard; also implemented in many other libraries. |
| ChaCha20-Poly1305       | 256 bits | 64 bits    | 512 bits   | 128 bits | libsodium \>= 0.6.0. Also implemented in {Libre,Open,Boring}SSL.                                            |
| ChaCha20-Poly1305-IETF  | 256 bits | 96 bits    | 512 bits   | 128 bits | libsodium \>= 1.0.4. IETF standard; also implemented in Ring, {Libre,Open,Boring}SSL and other libraries.   |
| XChaCha20-Poly1305-IETF | 256 bits | 192 bits   | 512 bits   | 128 bits | libsodium \>= 1.0.12. Not standardized but widely implemented.                                              |

## Limitations

| Construction            | Max bytes for a single (key,nonce)  |
| :---------------------- | :---------------------------------- |
| AEGIS-256               | No practical limits                 |
| AEGIS-128L              | No practical limits                 |
| XChaCha20-Poly1305-IETF | No practical limits (\~ 2^64 bytes) |
| ChaCha20-Poly1305       | No practical limits (\~ 2^64 bytes) |
| ChaCha20-Poly1305-IETF  | 256 GB                              |
| AES256-GCM              | \~ 64 GB                            |

| Construction            | Max messages with random nonces |
| :---------------------- | :------------------------------ |
| AEGIS-256               | No practical limits             |
| XChaCha20-Poly1305-IETF | No practical limits             |
| AEGIS-128L              | 2^48                            |
| AES256-GCM              | 2^32                            |
| ChaCha20-Poly1305-IETF  | 2^32                            |
| ChaCha20-Poly1305       | 2^16                            |

These figures assume an untruncated (128-bit or 256-bit) authentication tag.

Although periodic rekeying remains highly recommended, online protocols leveraging additional data to discard old messages don’t have practical limitations on the total number of messages.

In spite of these limits, applications must enforce a limit on the maximum size of a ciphertext to decrypt. Very large messages should be split in multiple chunks instead of being encrypted as a single ciphertext:

- This keeps memory usage in control,
- A corrupted chunk can be immediately detected before the whole ciphertext is received,
- Large messages provide more wiggle room for attacks.

Applications are also encouraged to limit the number of attempts an adversary can make, for example by closing a session after a large number of decryption failures.

Assuming a 2^-32 attack success probability, and nonces safely chosen (cf. the `Nonces` section below) the following tables summarize how many messages should be encrypted with a single key before switching to a new key, as well as how many brute force decryption attempts an attacker should be allowed to make to prevent forgery.

Note that the latter is not a practical concern due to application limits, noisiness, storage and bandwidth requirements. The maximum number of encryptions is the most important criteria for selecting a secure primitive.

- For 16 KB long messages:

| Construction                   | Max number of encryptions | Max number of decryption attempts/message |
| :----------------------------- | :------------------------ | :---------------------------------------- |
| AEGIS-256                      | No practical limits       | > 2^128 (with 256-bit tags)               |
| AEGIS-128L                     | No practical limits       | > 2^128 (with 256-bit tags)               |
| AES256-GCM                     | 2^38                      | 2^85                                      |
| All ChaCha20-Poly1305 variants | 2^63                      | 2^61 (but requires at least 2^77 bytes)   |
| AEGIS-128L                     | No practical limits       | 2^                                        |

- For 1 MB long messages:

| Construction                   | Max number of encryptions | Max number of decryption attempts/message |
| :----------------------------- | :------------------------ | :---------------------------------------- |
| AEGIS-256                      | No practical limits       | > 2^128 (with 256-bit tags)               |
| AEGIS-128L                     | No practical limits       | > 2^128 (with 256-bit tags)               |
| AES256-GCM                     | 2^32                      | 2^79                                      |
| All ChaCha20-Poly1305 variants | 2^57                      | 2^55 (but requires at least 2^77 bytes)   |

- For 1 GB long messages:

| Construction                   | Max number of encryptions | Max number of decryption attempts/message |
| :----------------------------- | :------------------------ | :---------------------------------------- |
| AEGIS-256                      | No practical limits       | > 2^128 (with 256-bit tags)               |
| AEGIS-128L                     | No practical limits       | > 2^128 (with 256-bit tags)               |
| AES256-GCM                     | 2^22                      | 2^69                                      |
| All ChaCha20-Poly1305 variants | 2^47                      | 2^45 (but requires at least 2^77 bytes)   |

- For 64 GB long messages:

| Construction                   | Max number of encryptions | Max number of decryption attempts/message |
| :----------------------------- | :------------------------ | :---------------------------------------- |
| AEGIS-256                      | No practical limits       | > 2^128 (with 256-bit tags)               |
| AEGIS-128L                     | No practical limits       | > 2^128 (with 256-bit tags)               |
| AES256-GCM                     | 2^16                      | 2^63                                      |
| All ChaCha20-Poly1305 variants | 2^41                      | 2^39 (but requires at least 2^77 bytes)   |

### Nonces

| Construction            | Safe options to choose a nonce   |
| :---------------------- | :------------------------------- |
| XChaCha20-Poly1305-IETF | Counter, permutation, random     |
| AEGIS-256               | Counter, permutation, random     |
| AEGIS-128L              | Counter, permutation, random (*) |
| AES256-GCM              | Counter, permutation             |
| ChaCha20-Poly1305       | Counter, permutation             |
| ChaCha20-Poly1305-IETF  | Counter, permutation             |

*: for a collision probability below 2^-32, random nonces are safe up to 2^48 messages.

### TL;DR: which one should I use?

If the target CPU has hardware AES acceleration (modern Intel or ARM CPU), `AEGIS-256` is the safest choice.

If not, use `XChaCha20-Poly1305-IETF`.

Other choices are only present for interoperability with other libraries that don’t implement these ciphers yet.

### AES256-GCM

The current implementation of this construction is hardware-accelerated and requires the Intel AES-NI extensions, or the ARM Crypto extensions.

Intel Westmere processors (introduced in 2010) and newer, as well as the vast majority of 64-bit ARM processors meet the requirements.

There are no plans to support non hardware-accelerated implementations of AES-GCM, as correctly mitigating side-channels in a software implementation comes with major speed tradeoffs, that defeat the whole point of AES-GCM over ChaCha20-Poly1305.

### ChaCha20-Poly1305

While AES is very fast on dedicated hardware, its performance on platforms that lack such hardware is considerably lower. Another problem is that many software AES implementations are vulnerable to cache-collision timing attacks.

ChaCha20 is considerably faster than AES in software-only implementations, making it around three times as fast on platforms that lack specialized AES hardware. ChaCha20 is also not sensitive to timing attacks.

Poly1305 is a high-speed message authentication code.

The combination of the ChaCha20 stream cipher with the Poly1305 authenticator was proposed in January 2014 as an alternative to the Salsa20-Poly1305 construction. ChaCha20-Poly1305 was implemented in major operating systems, web browsers and crypto libraries shortly after. It eventually became an official IETF standard in May 2015.

The ChaCha20-Poly1305 implementation in libsodium is portable across all supported architectures.

### XChaCha20-Poly1305

XChaCha20-Poly1305 applies the construction described in Daniel Bernstein’s [Extending the Salsa20 nonce](https://cr.yp.to/snuffle/xsalsa-20081128.pdf) paper to the ChaCha20 cipher in order to extend the nonce size to 192-bit.

This extended nonce size allows random nonces to be safely used, and also facilitates the construction of misuse-resistant schemes.

The XChaCha20-Poly1305 implementation in libsodium is portable across all supported architectures.

## Additional data

These functions accept an optional, arbitrary long “additional data” parameter. These data are not present in the ciphertext, but are mixed in the computation of the authentication tag.

A typical use for these data is to authenticate version numbers, timestamps or monotonically increasing counters in order to discard previous messages and prevent replay attacks.

## Robustness

Ciphertexts are expected to be decrypted and verified using the same key as the key initially used for encryption.

However, when using AES-GCM and ChaCha20-Poly1305, multiple keys that would cause a (ciphertext, tag) pair to verify can be efficiently computed.

Decryption using a key that differs from the one used for encryption would produce a different message, and would not compromise the security of the original message.

Still, it may be an issue if an attacker has the ability to force a recipient to use a different key than the one used for encryption.

If that turns out to be a concern, the following can be done:

- Use the AEGIS ciphers, that, under common scenarios, are assumed to be safe against these attacks.

or with other ciphers:

- Prepend `H(key, nonce || ciphertext_tag)` to the ciphertext
- Verify this prior to decryption. This can be done with `crypto_auth()` and `crypto_auth_verify()`.

This assumes that attackers don’t have control over associated data. If they do, associated data `ad` must be included in the input of the hash function as well: `H(key, nonce || ciphertext_tag || ad)`. In that case, as an optimization, `ad` can be left empty in the encryption and decryption functions.

## References

- [Limits on Authenticated Encryption Use in TLS](https://eprint.iacr.org/2024/051.pdf) (Atul Luykx, Kenneth G. Paterson).
- [Usage Limits on AEAD Algorithms](https://datatracker.ietf.org/doc/draft-irtf-cfrg-aead-limits/)
- [Collision Attacks on Galois/Counter Mode (GCM)](https://eprint.iacr.org/2024/1111.pdf)
