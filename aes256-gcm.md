# Authenticated Encryption with Additional Data using AES-GCM

## Example

```c
#include <sodium.h>

#define MESSAGE (const unsigned char *) "test"
#define MESSAGE_LEN 4
#define ADDITIONAL_DATA (const unsigned char *) "123456"
#define ADDITIONAL_DATA_LEN 6

unsigned char nonce[crypto_aead_aes256gcm_NPUBBYTES];
unsigned char key[crypto_aead_aes256gcm_KEYBYTES];
unsigned char ciphertext[MESSAGE_LEN + crypto_aead_aes256gcm_ABYTES];
unsigned long long ciphertext_len;

sodium_init();
if (crypto_aead_aes256gcm_is_available() == 0) {
    abort(); /* Not available on this CPU */
}

randombytes_buf(key, sizeof key);
randombytes_buf(nonce, sizeof nonce);

crypto_aead_aes256gcm_encrypt(ciphertext, &ciphertext_len,
                              MESSAGE, MESSAGE_LEN,
                              ADDITIONAL_DATA, ADDITIONAL_DATA_LEN,
                              NULL, nonce, key);

unsigned char decrypted[MESSAGE_LEN];
unsigned long long decrypted_len;
if (crypto_aead_aes256gcm_decrypt(decrypted, &decrypted_len,
                                  NULL,
                                  ciphertext, ciphertext_len,
                                  ADDITIONAL_DATA,
                                  ADDITIONAL_DATA_LEN,
                                  nonce, key) != 0) {
    /* message forged! */
}
```

## Purpose

This operation:
- Encrypts a message with a key and a nonce to keep it confidential
- Computes an authentication tag. This tag is used to make sure that the message, as well as optional, non-confidential (non-encrypted) data, haven't been tampered with.

A typical use case for additional data is to store protocol-specific metadata about the message, such as its length and encoding.

It can also be used as a MAC, with an empty message.

Decryption will never be performed, even partially, before verification.

When supported by the CPU, AES-GCM is the fastest AEAD cipher available in this library.

## Limitations

The current implementation of this construction is hardware-accelerated and requires the Intel SSSE3 extensions, and the `aesni` and `pclmul` instructions.

Intel Westmere processors (introduced in 2010) and newer meet the requirements.

There are no plans to support non hardware-accelerated implementations of AES-GCM. If portability is a concern, use ChaCha20-Poly1305 instead.

## Usage

```c
int crypto_aes_aes256gcm_is_available(void);
```

Returns `1` if the current CPU supports the AES256-GCM implementation, and `0` if it doesn't.

The library must have been initialized with `sodium_init()` prior to calling this function. 

```c
int crypto_aead_aes256gcm_encrypt(unsigned char *c,
                                  unsigned long long *clen,
                                  const unsigned char *m,
                                  unsigned long long mlen,
                                  const unsigned char *ad,
                                  unsigned long long adlen,
                                  const unsigned char *nsec,
                                  const unsigned char *npub,
                                  const unsigned char *k);
```

The `crypto_aead_aes256gcm_encrypt()` function encrypts a message `m` whose length is `mlen` bytes using a secret key `k` (`crypto_aead_aes256gcm_KEYBYTES` bytes) and a public nonce `npub` (`crypto_aead_aes256gcm_NPUBBYTES` bytes).

The encrypted message, as well as a tag authenticating both the confidential message `m` and `adlen` bytes of non-confidential data `ad`, are put into `c`.

`ad` can also be a `NULL` pointer if no additional data are required.

At most `mlen + crypto_aead_aes256gcm_ABYTES` bytes are put into `c`, and the actual number of bytes is stored into `clen` if `clen` is not a `NULL` pointer.

`nsec` is not used by this particular construction and should always be `NULL`.

The public nonce `npub` should never ever be reused with the same key. The recommended way to generate it is to use `randombytes_buf()` for the first message, and increment it for each subsequent message using the same key.

```c
int crypto_aead_aes256gcm_decrypt(unsigned char *m,
                                  unsigned long long *mlen,
                                  unsigned char *nsec,
                                  const unsigned char *c,
                                  unsigned long long clen,
                                  const unsigned char *ad,
                                  unsigned long long adlen,
                                  const unsigned char *npub,
                                  const unsigned char *k);
```

The `crypto_aead_aes256gcm_decrypt()` function verifies that the ciphertext `c` (as produced by `crypto_aead_aes256gcm_encrypt()`) includes a valid tag using a secret key `k`, a public nonce `npub`, and additional data `ad` (`adlen` bytes).

`ad` can be a `NULL` pointer if no additional data are required.

`nsec` is not used by this particular construction and should always be `NULL`.

The function returns `-1` is the verification fails.

If the verification succeeds, the function returns `0`, puts the decrypted message into `m` and stores its actual number of bytes into `mlen` if `mlen` is not a `NULL` pointer.

At most `clen - crypto_aead_aes256gcm_ABYTES` bytes will be put into `m`.

## Precalculation interface

Applications that encrypt several messages using the same key can gain speed by expanding the AES key only once, via the precalculation interface.

```
int crypto_aead_aes256gcm_beforenm(crypto_aead_aes256gcm_state *ctx_,
                                   const unsigned char *k);
```

The `crypto_aead_aes256gcm_beforenm()` function initializes a context `ctx` by expanding the key `k`.

A 16 bytes alignment is required for the address of `ctx`. The size of this value can be obtained using `sizeof(crypto_aead_aes256gcm_state)`, or `crypto_aead_aes256gcm_statebytes()`.

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

## Constants

- `crypto_aead_aes256gcm_KEYBYTES`
- `crypto_aead_aes256gcm_NPUBBYTES`
- `crypto_aead_aes256gcm_ABYTES`

## Data types

- `crypto_aead_aes256gcm_state`

## Notes

The nonce is 192 bits long and doesn't have to be confidential, but it should be used with just one message for a particular pair of public and secret keys. Avoid nonce reuse is essential for this construction.

One easy way to generate a nonce is to use `randombytes_buf()`; considering the size of nonces the risk of any random collisions is negligible. For some applications, if you wish to use nonces to detect missing messages or to ignore replayed messages, it is also acceptable to use a simple incrementing counter as a nonce.

When doing so you must ensure that the same value can never be re-used (for example you may have multiple threads or even hosts generating messages using the same key pairs).