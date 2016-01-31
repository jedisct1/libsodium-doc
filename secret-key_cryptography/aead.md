# Authenticated Encryption with Additional Data

## Purpose

This operation:
- Encrypts a message with a key and a nonce to keep it confidential
- Computes an authentication tag. This tag is used to make sure that the message, as well as optional, non-confidential (non-encrypted) data, haven't been tampered with.

A typical use case for additional data is to store protocol-specific metadata about the message, such as its length and encoding.

## Supported constructions

Libsodium supports two popular constructions:

- [AES256-GCM](aes256-gcm.md) is only implemented for 