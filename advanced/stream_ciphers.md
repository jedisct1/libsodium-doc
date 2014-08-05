# Stream ciphers

Sodium includes implementations of AES-128 in counter mode, as well as the Salsa20/8, Salsa20/12, Salsa20/20, XSalsa20/20 and ChaCha20/20 stream ciphers.

These functions are stream ciphers. They do not provide authenticated encryption.

They can be used to generate pseudo-random data from a key, or as building blocks for implementing custom constructions, but they are not alternatives to `crypto_secretbox_*()`.
