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
