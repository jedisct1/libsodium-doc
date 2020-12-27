# Authenticated Encryption with Additional Data

This operation:

* Encrypts a message with a key and a nonce to keep it confidential
* Computes an authentication tag. This tag is used to make sure that the
  message, as well as optional, non-confidential \(non-encrypted\) data, haven't
  been tampered with.

A typical use case for additional data is to authenticate protocol-specific metadata
about the message, such as its length and encoding.

## Supported constructions

libsodium supports two popular constructions: AES256-GCM and ChaCha20-Poly1305
\(original version and IETF version\), as well as a variant of the later with an
extended nonce: XChaCha20-Poly1305.

The "combined mode" API of each construction appends the
authentication tag to the ciphertext. The "detached mode" API stores
the authentication tag in a separate location.

### Availability and interoperability

| Construction            | Key size | Nonce size | Block size | MAC size | Availability                                                                                                  |
| :---------------------- | :------- | :--------- | :--------- | :------- | :------------------------------------------------------------------------------------------------------------ |
| AES256-GCM              | 256 bits | 96 bits    | 128 bits   | 128 bits | libsodium &gt;= 1.0.4 but requires hardware support. IETF standard; also implemented in many other libraries. |
| ChaCha20-Poly1305       | 256 bits | 64 bits    | 512 bits   | 128 bits | libsodium &gt;= 0.6.0. Also implemented in {Libre,Open,Boring}SSL.                                            |
| ChaCha20-Poly1305-IETF  | 256 bits | 96 bits    | 512 bits   | 128 bits | libsodium &gt;= 1.0.4. IETF standard; also implemented in Ring, {Libre,Open,Boring}SSL and other libraries.   |
| XChaCha20-Poly1305-IETF | 256 bits | 192 bits   | 512 bits   | 128 bits | libsodium &gt;= 1.0.12. On the standard track.                                                                |

## Limitations

| Construction            | Max bytes for a single \(key,nonce\) | Max bytes for a single key                                       |
| :---------------------- | :----------------------------------- | :--------------------------------------------------------------- |
| AES256-GCM              | ~ 64 GB                              | ~ 350 GB (for ~16 KB long messages)                              |
| ChaCha20-Poly1305       | No practical limits \(~ 2^64 bytes\) | Up to 2^64<sup>\*</sup> messages, no practical total size limits |
| ChaCha20-Poly1305-IETF  | 256 GB                               | Up to 2^64<sup>\*</sup> messages, no practical total size limits |
| XChaCha20-Poly1305-IETF | No practical limits \(~ 2^64 bytes\) | Up to 2^64<sup>\*</sup> messages, no practical total size limits |

These figures assume an untruncated (128-bit) authentication tag.

<sup>\*</sup> Although periodic rekeying remains highly recommended, online
protocols leveraging additional data to discard old messages don't have
practical limitations on the total number of messages.

In spite of these limits, applications must enforce a limit on the maximum size of a ciphertext to decrypt. Very large messages should be split in multiple chunks instead of being encrypted as a single ciphertext:

- This keeps memory usage in control,
- A corrupted chunk can be immediately detected before the whole ciphertext is received,
- Large messages provide more wiggle room for attacks.

Applications are also encouraged to limit the number of attempts an adversary can make, for example by closing a session after a large number of decryption failures.

Assuming a 2^-32 attack success probability, the following tables summarize how many messages should be encrypted with a single key before switching to a new key, as well as how many brute force decryption attempts an attacker should be allowed to make to prevent forgery.

Note that the latter is not a practical concern due to application limits, noisiness, storage and bandwidth requirements. The maximum number of encryptions is the most important criteria for selecting a secure primitive.

* For 16 KB long messages:

| Construction                   | Max number of encryptions | Max number of unsucessful decryption attempts          |
| :----------------------------- | :------------------------ | :----------------------------------------------------- |
| AES256-GCM                     | 2^38                      | 2^85                                                   |
| All ChaCha20-Poly1305 variants | 2^63                      | 2^63 (forgery with 2^-32 success requires ~2^77 bytes) |

* For 1 MB long messages:

| Construction                   | Max number of encryptions | Max number of unsucessful decryption attempts          |
| :----------------------------- | :------------------------ | :----------------------------------------------------- |
| AES256-GCM                     | 2^32                      | 2^78                                                   |
| All ChaCha20-Poly1305 variants | 2^57                      | 2^57 (forgery with 2^-32 success requires ~2^77 bytes) |

* For 1 GB long messages:

| Construction                   | Max number of encryptions | Max number of unsucessful decryption attempts          |
| :----------------------------- | :------------------------ | :----------------------------------------------------- |
| AES256-GCM                     | 2^22                      | 2^69                                                   |
| All ChaCha20-Poly1305 variants | 2^47                      | 2^47 (forgery with 2^-32 success requires ~2^77 bytes) |

* For 64 GB long messages:

| Construction                   | Max number of encryptions | Max number of unsucessful decryption attempts          |
| :----------------------------- | :------------------------ | :----------------------------------------------------- |
| AES256-GCM                     | 2^16                      | 2^63                                                   |
| All ChaCha20-Poly1305 variants | 2^41                      | 2^41 (forgery with 2^-32 success requires ~2^77 bytes) |

### Nonces

| Construction            | Safe options to choose a nonce                 |
| :---------------------- | :--------------------------------------------- |
| AES256-GCM              | Counter, permutation                           |
| ChaCha20-Poly1305       | Counter, permutation                           |
| ChaCha20-Poly1305-IETF  | Counter, permutation                           |
| XChaCha20-Poly1305-IETF | Counter, permutation, random, Hk\(random ‖ m\) |

`Hk` represents a keyed hash function that is safe against length-extension
attacks, such as BLAKE2 or the HMAC construction.

### TL;DR: which one should I use?

`XChaCha20-Poly1305-IETF` is the safest choice.

Other choices are only present for interoperability with other libraries that don't implement `XChaCha20-Poly1305-IETF` yet.

### AES256-GCM

The current implementation of this construction is hardware-accelerated and
requires the Intel SSSE3 extensions, as well as the `aesni` and `pclmul`
instructions.

Intel Westmere processors \(introduced in 2010\) and newer meet the
requirements.

There are no plans to support non hardware-accelerated implementations of
AES-GCM, as correctly mitigating side-channels in a software implementation
comes with major speed tradeoffs, that defeat the whole point of AES-GCM over
ChaCha20-Poly1305.

### ChaCha20-Poly1305

While AES is very fast on dedicated hardware, its performance on platforms that
lack such hardware is considerably lower. Another problem is that many software
AES implementations are vulnerable to cache-collision timing attacks.

ChaCha20 is considerably faster than AES in software-only implementations,
making it around three times as fast on platforms that lack specialized AES
hardware. ChaCha20 is also not sensitive to timing attacks.

Poly1305 is a high-speed message authentication code.

The combination of the ChaCha20 stream cipher with the Poly1305 authenticator
was proposed in January 2014 as an alternative to the Salsa20-Poly1305
construction. ChaCha20-Poly1305 was implemented in major operating systems, web
browsers and crypto libraries shortly after. It eventually became an official
IETF standard in May 2015.

The ChaCha20-Poly1305 implementation in libsodium is portable across all
supported architectures.

### XChaCha20-Poly1305

XChaCha20-Poly1305 applies the construction described in Daniel Bernstein's
[Extending the Salsa20 nonce](https://cr.yp.to/snuffle/xsalsa-20081128.pdf)
paper to the ChaCha20 cipher in order to extend the nonce size to 192-bit.

This extended nonce size allows random nonces to be safely used, and also
facilitates the construction of misuse-resistant schemes.

The XChaCha20-Poly1305 implementation in libsodium is portable across all
supported architectures.

The main limitation of XChaCha20-Poly1305 is that it is not widely implemented
in other libraries yet. However, it will
[soon](https://tools.ietf.org/html/draft-arciszewski-xchacha-03) become an IETF
standard.

## Additional data

These functions accept an optional, arbitrary long "additional data" parameter.
These data are not present in the ciphertext, but are mixed in the computation
of the authentication tag.

A typical use for these data is to authenticate version numbers, timestamps or
monotonically increasing counters in order to discard previous messages and
prevent replay attacks.

## Robustness

Ciphertexts are expected to be decrypted and verified using the same key as the key initially used for encryption.

Trying to decrypt a ciphertext with a different key may still allow an authentication tag verification to pass.
Doing so would produce a different message, and would not compromise the security of the original message.

But this may be an issue if an attacker has the ability to force a recipient to use a different key.

If that turns out to be a concern, this can be solved in different ways:

- By incorporating a key identifier in the nonce
- By including a key identifier in the additional data
- By including a 128-bit fixed string in the message and verifying it during the decryption process

## References

* [Limits on Authenticated Encryption Use in TLS](http://www.isg.rhul.ac.uk/~kp/TLS-AEbounds.pdf)
  \(Atul Luykx, Kenneth G. Paterson\).
