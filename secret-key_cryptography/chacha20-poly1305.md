# Authenticated Encryption with Additional Data using ChaCha20-Poly1305

## Purpose

This operation:
- Encrypts a message with a key and a nonce to keep it confidential
- Computes an authentication tag. This tag is used to make sure that the message, as well as optional, non-confidential (non-encrypted) data, haven't been tampered with.

A typical use case for additional data is to store protocol-specific metadata about the message, such as its length and encoding.

The chosen construction uses encrypt-then-MAC and decryption will never be performed, even partially, before verification.

## Variants

Libsodium implements two versions of the ChaCha20-Poly1305 construction:
- The original construction can safely encrypt up to 2^64 messages with the same key, without any practical limit to the size of a message (up to 2^70 bytes).
- The IETF variant can safely encrypt a pratically unlimited number of messages (2^96), but individual messages cannot exceed 1 terabyte. 

Both are interoperable with other crypto libaries, share the same security properties and are accessible via a similar API.

The `crypto_aead_chacha20poly1305_*()` set of functions implements the original construction, while the `crypto_aead_chacha20poly1305_ietf_*()` functions implement the IETF version.
The constants are the same, except for the nonce size.

## Notes

In order to prevent nonce reuse, if a key is being reused, it is recommended to increment the previous nonce instead of generating a random nonce for each message.

To prevent nonce reuse in a client-server protocol, either use different keys for each direction, or make sure that a bit is masked in one direction, and set in the other.

The API conforms to the proposed API for the CAESAR competition.

A high-level `crypto_aead_*()` API is intentionally not defined until the [CAESAR](http://competitions.cr.yp.to/caesar.html) competition is over.

## See also

- [ChaCha20 and Poly1305 based Cipher Suites for TLS](https://tools.ietf.org/html/draft-agl-tls-chacha20poly1305-04)
- [ChaCha20 and Poly1305 for IETF protocols](https://tools.ietf.org/html/rfc7539)
