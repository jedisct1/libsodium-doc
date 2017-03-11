# Authenticated Encryption with Additional Data using AES-GCM

## Example \(combined mode\)

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
if (ciphertext_len < crypto_aead_aes256gcm_ABYTES ||
    crypto_aead_aes256gcm_decrypt(decrypted, &decrypted_len,
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

* Encrypts a message with a key and a nonce to keep it confidential
* Computes an authentication tag. This tag is used to make sure that the message, as well as optional, non-confidential \(non-encrypted\) data, haven't been tampered with.

A typical use case for additional data is to store protocol-specific metadata about the message, such as its length and encoding.

It can also be used as a MAC, with an empty message.

Decryption will never be performed, even partially, before verification.

When supported by the CPU, AES-GCM is the fastest AEAD cipher available in this library.

## Limitations

The current implementation of this construction is hardware-accelerated and requires the Intel SSSE3 extensions, as well as the `aesni` and `pclmul` instructions.

Intel Westmere processors \(introduced in 2010\) and newer meet the requirements.

There are no plans to support non hardware-accelerated implementations of AES-GCM. If portability is a concern, use ChaCha20-Poly1305 instead.

Before using the functions below, hardware support for AES can be checked with:

```c
int crypto_aead_aes256gcm_is_available(void);
```

The function returns `1` if the current CPU supports the AES256-GCM implementation, and `0` if it doesn't.

The library must have been initialized with `sodium_init()` prior to calling this function.

## Combined mode

In combined mode, the authentication tag and the encrypted message are stored together. This is usually what you want.

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

The function `crypto_aead_aes256gcm_encrypt()` encrypts a message `m` whose length is `mlen` bytes using a secret key `k` \(`crypto_aead_aes256gcm_KEYBYTES` bytes\) and a public nonce `npub` \(`crypto_aead_aes256gcm_NPUBBYTES` bytes\).

The encrypted message, as well as a tag authenticating both the confidential message `m` and `adlen` bytes of non-confidential data `ad`, are put into `c`.

`ad` can also be a `NULL` pointer if no additional data are required.

At most `mlen + crypto_aead_aes256gcm_ABYTES` bytes are put into `c`, and the actual number of bytes is stored into `clen` if `clen` is not a `NULL` pointer.

`nsec` is not used by this particular construction and should always be `NULL`.

The function always returns `0`.

The public nonce `npub` should never ever be reused with the same key. The recommended way to generate it is to use `randombytes_buf()` for the first message, and then to increment it for each subsequent message using the same key.

```c
int crypto_aead_aes256gcm_decrypt(unsigned char *m,
                                  unsigned long long *mlen_p,
                                  unsigned char *nsec,
                                  const unsigned char *c,
                                  unsigned long long clen,
                                  const unsigned char *ad,
                                  unsigned long long adlen,
                                  const unsigned char *npub,
                                  const unsigned char *k);
```

The function `crypto_aead_aes256gcm_decrypt()` verifies that the ciphertext `c` \(as produced by `crypto_aead_aes256gcm_encrypt()`\), includes a valid tag using a secret key `k`, a public nonce `npub`, and additional data `ad` \(`adlen` bytes\).  
`clen` is the ciphertext length in bytes with the authenticator, so it has to be at least `aead_aes256gcm_ABYTES`.

`ad` can be a `NULL` pointer if no additional data are required.

`nsec` is not used by this particular construction and should always be `NULL`.

The function returns `-1` is the verification fails.

If the verification succeeds, the function returns `0`, puts the decrypted message into `m` and stores its actual number of bytes into `mlen` if `mlen` is not a `NULL` pointer.

At most `clen - crypto_aead_aes256gcm_ABYTES` bytes will be put into `m`.

## Detached mode

Some applications may need to store the authentication tag and the encrypted message at different locations.

For this specific use case, "detached" variants of the functions above are available.

```c
int crypto_aead_aes256gcm_encrypt_detached(unsigned char *c,
                                           unsigned char *mac,
                                           unsigned long long *maclen_p,
                                           const unsigned char *m,
                                           unsigned long long mlen,
                                           const unsigned char *ad,
                                           unsigned long long adlen,
                                           const unsigned char *nsec,
                                           const unsigned char *npub,
                                           const unsigned char *k);
```

`crypto_aead_aes256gcm_encrypt_detached()` encrypts a message `m` whose length is `mlen` bytes using a secret key `k` \(`crypto_aead_aes256gcm_KEYBYTES` bytes\) and a public nonce `npub` \(`crypto_aead_aes256gcm_NPUBBYTES` bytes\).

The encrypted message in put into `c`. A tag authenticating both the confidential message `m` and `adlen` bytes of non-confidential data `ad` is put into `mac`.

`ad` can also be a `NULL` pointer if no additional data are required.

`crypto_aead_aes256gcm_ABYTES` bytes are put into `mac`, and the actual number of bytes required for verification is stored into `maclen_p`, unless `maclen_p` is `NULL` pointer.

`nsec` is not used by this particular construction and should always be `NULL`.

The function always returns `0`.

```c
int crypto_aead_aes256gcm_decrypt_detached(unsigned char *m,
                                           unsigned char *nsec,
                                           const unsigned char *c,
                                           unsigned long long clen,
                                           const unsigned char *mac,
                                           const unsigned char *ad,
                                           unsigned long long adlen,
                                           const unsigned char *npub,
                                           const unsigned char *k);
```

The function `crypto_aead_aes256gcm_decrypt_detached()` verifies that the tag `mac` is valid for the the ciphertext `c` using a secret key `k`, a public nonce `npub`, and additional data `ad` \(`adlen` bytes\).

`clen` is the ciphertext length in bytes.

`ad` can be a `NULL` pointer if no additional data are required.

`nsec` is not used by this particular construction and should always be `NULL`.

The function returns `-1` is the verification fails.

If the verification succeeds, the function returns `0`, and puts the decrypted message into `m`, whose length is equal to the length of the ciphertext.

```c
void crypto_aead_aes256gcm_keygen(unsigned char k[crypto_aead_aes256gcm_KEYBYTES]);
```

This helper function introduced in Libsodium 1.0.12 creates a random key `k`.

It is equivalent to calling `randombytes_buf()` but improves code clarity and can prevent misuse by ensuring that the provided key length is always be correct.

## Constants

* `crypto_aead_aes256gcm_KEYBYTES`
* `crypto_aead_aes256gcm_NPUBBYTES`
* `crypto_aead_aes256gcm_ABYTES`

## Notes

The nonce is 96 bits long. In order to prevent nonce reuse, if a key is being reused, it is recommended to increment the previous nonce instead of generating a random nonce for each message.  
To prevent nonce reuse in a client-server protocol, either use different keys for each direction, or make sure that a bit is masked in one direction, and set in the other.

When using AES-GCM, it is also recommended to switch to a new key before reaching ~350 MB encrypted with the same key.  
If frequent rekeying is not an option, use \(X\)ChaCha20-Poly1305 instead.

Support for AES256-GCM was introduced in Libsodium 1.0.4.

The detached API was introduced in Libsodium 1.0.9.



