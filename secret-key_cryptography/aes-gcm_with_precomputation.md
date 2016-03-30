# AES256-GCM with precomputation


Applications that encrypt several messages using the same key can gain a little speed by expanding the AES key only once, via the precalculation interface.

```
int crypto_aead_aes256gcm_beforenm(crypto_aead_aes256gcm_state *ctx_,
                                   const unsigned char *k);
```

The `crypto_aead_aes256gcm_beforenm()` function initializes a context `ctx` by expanding the key `k` and always returns `0`.

A 16 bytes alignment is required for the address of `ctx`. The size of this value can be obtained using `sizeof(crypto_aead_aes256gcm_state)`, or `crypto_aead_aes256gcm_statebytes()`.

### Combined mode with precalculation

```c
int crypto_aead_aes256gcm_encrypt_afternm(unsigned char *c,
                                          unsigned long long *clen_p,
                                          const unsigned char *m,
                                          unsigned long long mlen,
                                          const unsigned char *ad,
                                          unsigned long long adlen,
                                          const unsigned char *nsec,
                                          const unsigned char *npub,
                                          const crypto_aead_aes256gcm_state *ctx_);
```

```c
int crypto_aead_aes256gcm_decrypt_afternm(unsigned char *m,
                                          unsigned long long *mlen_p,
                                          unsigned char *nsec,
                                          const unsigned char *c,
                                          unsigned long long clen,
                                          const unsigned char *ad,
                                          unsigned long long adlen,
                                          const unsigned char *npub,
                                          const crypto_aead_aes256gcm_state *ctx_);
```

The `crypto_aead_aes256gcm_encrypt_afternm()` and `crypto_aead_aes256gcm_decrypt_afternm()` functions are identical to `crypto_aead_aes256gcm_encrypt()` and `crypto_aead_aes256gcm_decrypt()`, but accept a previously initialized context `ctx` instead of a key.

### Detached mode with precalculation

```c
int crypto_aead_aes256gcm_encrypt_detached_afternm(unsigned char *c,
                                                   unsigned char *mac,
                                                   unsigned long long *maclen_p,
                                                   const unsigned char *m,
                                                   unsigned long long mlen,
                                                   const unsigned char *ad,
                                                   unsigned long long adlen,
                                                   const unsigned char *nsec,
                                                   const unsigned char *npub,
                                                   const crypto_aead_aes256gcm_state *ctx_);
```

```c
int crypto_aead_aes256gcm_decrypt_detached_afternm(unsigned char *m,
                                                   unsigned char *nsec,
                                                   const unsigned char *c,
                                                   unsigned long long clen,
                                                   const unsigned char *mac,
                                                   const unsigned char *ad,
                                                   unsigned long long adlen,
                                                   const unsigned char *npub,
                                                   const crypto_aead_aes256gcm_state *ctx_)
```

The `crypto_aead_aes256gcm_encrypt_detached_afternm()` and `crypto_aead_aes256gcm_decrypt_detached_afternm()` functions are identical to `crypto_aead_aes256gcm_encrypt_detached()` and `crypto_aead_aes256gcm_decrypt_detached()`, but accept a previously initialized context `ctx` instead of a key.

## Constants

- `crypto_aead_aes256gcm_KEYBYTES`
- `crypto_aead_aes256gcm_NPUBBYTES`
- `crypto_aead_aes256gcm_ABYTES`

## Data types

- `crypto_aead_aes256gcm_state`

## Notes

The nonce is 96 bits long. In order to prevent nonce reuse, if a key is being reused, it is recommended to increment the previous nonce instead of generating a random nonce for each message.
To prevent nonce reuse in a client-server protocol, either use different keys for each direction, or make sure that a bit is masked in one direction, and set in the other.

It is recommended to split message larger than 2 Gb into smaller chunks.

Support for AES256-GCM was introduced in Libsodium 1.0.4.

The detached API was introduced in Libsodium 1.0.9.