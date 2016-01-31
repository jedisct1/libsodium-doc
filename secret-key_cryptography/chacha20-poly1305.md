# Authenticated Encryption with Additional Data using ChaCha20-Poly1305

## Example

```c
#define MESSAGE (const unsigned char *) "test"
#define MESSAGE_LEN 4
#define ADDITIONAL_DATA (const unsigned char *) "123456"
#define ADDITIONAL_DATA_LEN 6

unsigned char nonce[crypto_aead_chacha20poly1305_NPUBBYTES];
unsigned char key[crypto_aead_chacha20poly1305_KEYBYTES];
unsigned char ciphertext[MESSAGE_LEN + crypto_aead_chacha20poly1305_ABYTES];
unsigned long long ciphertext_len;

randombytes_buf(key, sizeof key);
randombytes_buf(nonce, sizeof nonce);

crypto_aead_chacha20poly1305_encrypt(ciphertext, &ciphertext_len,
                                     MESSAGE, MESSAGE_LEN,
                                     ADDITIONAL_DATA, ADDITIONAL_DATA_LEN,
                                     NULL, nonce, key);

unsigned char decrypted[MESSAGE_LEN];
unsigned long long decrypted_len;
if (crypto_aead_chacha20poly1305_decrypt(decrypted, &decrypted_len,
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

The chosen construction uses encrypt-then-MAC and decryption will never be performed, even partially, before verification.

## Variants

Libsodium implements two versions of the ChaCha20-Poly1305 construction:
- The original construction can safely encrypt up to 2^64 messages with the same key, without any practical limit to the size of a message (up to 2^70 bytes).
- The IETF variant can safely encrypt a pratically unlimited number of messages (2^96), but individual messages cannot exceed 1 terabyte. 

Both are interoperable with other crypto libaries, share the same security properties and are accessible via a similar API.

The `crypto_aead_chacha20poly1305_*()` set of functions implements the original construction, while the `crypto_aead_chacha20poly1305_ietf_*()` functions implement the IETF version.
The constants are the same, except for the nonce size.

## Usage

```c
int crypto_aead_chacha20poly1305_encrypt(unsigned char *c,
                                         unsigned long long *clen,
                                         const unsigned char *m,
                                         unsigned long long mlen,
                                         const unsigned char *ad,
                                         unsigned long long adlen,
                                         const unsigned char *nsec,
                                         const unsigned char *npub,
                                         const unsigned char *k);
```

```c
int crypto_aead_chacha20poly1305_ietf_encrypt(unsigned char *c,
                                              unsigned long long *clen,
                                              const unsigned char *m,
                                              unsigned long long mlen,
                                              const unsigned char *ad,
                                              unsigned long long adlen,
                                              const unsigned char *nsec,
                                              const unsigned char *npub,
                                              const unsigned char *k);
```

The `crypto_aead_chacha20poly1305_encrypt()` function encrypts a message `m` whose length is `mlen` bytes using a secret key `k` (`crypto_aead_chacha20poly1305_KEYBYTES` bytes), a public nonce `npub` (`crypto_aead_chacha20poly1305_NPUBBYTES` bytes) and the original construction.

The `crypto_aead_chacha20poly1305_ietf_encrypt()` function encrypts a message `m` whose length is `mlen` bytes using a secret key `k` (`crypto_aead_chacha20poly1305_KEYBYTES` bytes), a public nonce `npub` (`crypto_aead_chacha20poly1305_IETF_NPUBBYTES` bytes), and the IETF variant.

The encrypted message, as well as a tag authenticating both the confidential message `m` and `adlen` bytes of non-confidential data `ad`, are put into `c`.

`ad` can also be a `NULL` pointer if no additional data are required.

At most `mlen + crypto_aead_chacha20poly1305_ABYTES` bytes are put into `c`, and the actual number of bytes is stored into `clen` if `clen` is not a `NULL` pointer.

`nsec` is not used by this particular construction and should always be `NULL`.

The public nonce `npub` should never ever be reused with the same key. The recommended way to generate it is to use `randombytes_buf()` for the first message, and increment it for each subsequent message using the same key.

```c
int crypto_aead_chacha20poly1305_decrypt(unsigned char *m,
                                         unsigned long long *mlen,
                                         unsigned char *nsec,
                                         const unsigned char *c,
                                         unsigned long long clen,
                                         const unsigned char *ad,
                                         unsigned long long adlen,
                                         const unsigned char *npub,
                                         const unsigned char *k);
```

```c
int crypto_aead_chacha20poly1305_ietf_decrypt(unsigned char *m,
                                              unsigned long long *mlen,
                                              unsigned char *nsec,
                                              const unsigned char *c,
                                              unsigned long long clen,
                                              const unsigned char *ad,
                                              unsigned long long adlen,
                                              const unsigned char *npub,
                                              const unsigned char *k);
```

The `crypto_aead_chacha20poly1305_decrypt()` function verifies that the ciphertext `c` (as produced by `crypto_aead_chacha20poly1305_encrypt()`) includes a valid tag using a secret key `k`, a public nonce `npub`, and additional data `ad` (`adlen` bytes).

The `crypto_aead_chacha20poly1305_ietf_decrypt()` function implements the IETF variant instead of the original construction.

`ad` can be a `NULL` pointer if no additional data are required.

`nsec` is not used by this particular construction and should always be `NULL`.

The function returns `-1` is the verification fails.

If the verification succeeds, the function returns `0`, puts the decrypted message into `m` and stores its actual number of bytes into `mlen` if `mlen` is not a `NULL` pointer.

At most `clen - crypto_aead_chacha20poly1305_ABYTES` bytes will be put into `m`.

## Constants

- `crypto_aead_chacha20poly1305_KEYBYTES`
- `crypto_aead_chacha20poly1305_NPUBBYTES`
- `crypto_aead_chacha20poly1305_ABYTES`
- `crypto_aead_chacha20poly1305_IETF_NPUBBYTES`

## Algorithm details

- Encryption: ChaCha20 stream cipher
- Authentication: Poly1305 MAC

## Notes

In order to prevent nonce reuse, if a key is being reused, it is recommended to increment the previous nonce instead of generating a random nonce for each message.

To prevent nonce reuse in a client-server protocol, either use different keys for each direction, or make sure that a bit is masked in one direction, and set in the other.

The API conforms to the proposed API for the CAESAR competition.

A high-level `crypto_aead_*()` API is intentionally not defined until the [CAESAR](http://competitions.cr.yp.to/caesar.html) competition is over.

## See also

- [ChaCha20 and Poly1305 based Cipher Suites for TLS](https://tools.ietf.org/html/draft-agl-tls-chacha20poly1305-04)
- [ChaCha20 and Poly1305 for IETF protocols](https://tools.ietf.org/html/rfc7539)
