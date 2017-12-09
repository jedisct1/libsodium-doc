# Authenticated Encryption with Additional Data using ChaCha20-Poly1305

## Purpose

This operation:

* Encrypts a message with a key and a nonce to keep it confidential
* Computes an authentication tag. This tag is used to make sure that the
  message, as well as optional, non-confidential (non-encrypted) data, haven't
  been tampered with.

A typical use case for additional data is to store protocol-specific metadata
about the message, such as its length and encoding.

The chosen construction uses encrypt-then-MAC and decryption will never be
performed, even partially, before verification.

## Variants

libsodium implements three versions of the ChaCha20-Poly1305 construction:

* The original construction can safely encrypt up to 2^64 messages with the same
  key (even more with most protocols), without any practical limit to the size
  of a message (up to 2^64 bytes for a 128-bit tag).
* The IETF variant. It can safely encrypt a pratically unlimited number of
  messages, but individual messages cannot exceed 64\*(2^32)-64 bytes
  (approximatively 256 GB).
* The XChaCha20 variant, introduced in libsodium 1.0.12. It can safely encrypt a
  practically unlimited number of messages of any sizes, and random nonces are
  safe to use.

The first two variants are fully interoperable with other crypto libaries. The
XChaCha20 variant is currently only implemented in libsodium, but is the
recommended option if interoperability is not a concern.

They all share the same security properties when used properly, and are
accessible via a similar API.

The `crypto_aead_chacha20poly1305_*()` set of functions implements the original
construction, the `crypto_aead_chacha20poly1305_ietf_*()` functions implement
the IETF version, and the `crypto_aead_xchacha20poly1305_ietf_*()` functions
implement the XChaCha20 variant.

The constants are the same, except for the nonce size.
