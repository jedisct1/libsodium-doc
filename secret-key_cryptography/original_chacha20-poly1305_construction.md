# The original ChaCha20-Poly1305 construction

The original ChaCha20-Poly1305 construction can safely encrypt a pratically
unlimited number of messages with the same key, without any practical limit to
the size of a message (up to ~ 2^64 bytes).

## Example (combined mode)

```c
#define MESSAGE (const unsigned char *) "test"
#define MESSAGE_LEN 4
#define ADDITIONAL_DATA (const unsigned char *) "123456"
#define ADDITIONAL_DATA_LEN 6

unsigned char nonce[crypto_aead_chacha20poly1305_NPUBBYTES];
unsigned char key[crypto_aead_chacha20poly1305_KEYBYTES];
unsigned char ciphertext[MESSAGE_LEN + crypto_aead_chacha20poly1305_ABYTES];
unsigned long long ciphertext_len;

crypto_aead_chacha20poly1305_keygen(key);
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

## Combined mode

In combined mode, the authentication tag is directly appended to the
encrypted message. This is usually what you want.

```c
int crypto_aead_chacha20poly1305_encrypt(unsigned char *c,
                                         unsigned long long *clen_p,
                                         const unsigned char *m,
                                         unsigned long long mlen,
                                         const unsigned char *ad,
                                         unsigned long long adlen,
                                         const unsigned char *nsec,
                                         const unsigned char *npub,
                                         const unsigned char *k);
```

The `crypto_aead_chacha20poly1305_encrypt()` function encrypts a message `m`
whose length is `mlen` bytes using a secret key `k`
(`crypto_aead_chacha20poly1305_KEYBYTES` bytes) and public nonce `npub`
(`crypto_aead_chacha20poly1305_NPUBBYTES` bytes).

The encrypted message, as well as a tag authenticating both the confidential
message `m` and `adlen` bytes of non-confidential data `ad`, are put into `c`.

`ad` can be a `NULL` pointer with `adlen` equal to `0` if no additional data are
required.

At most `mlen + crypto_aead_chacha20poly1305_ABYTES` bytes are put into `c`, and
the actual number of bytes is stored into `clen` unless `clen` is a `NULL`
pointer.

`nsec` is not used by this particular construction and should always be `NULL`.

The public nonce `npub` should never ever be reused with the same key. The
recommended way to generate it is to use `randombytes_buf()` for the first
message, and increment it for each subsequent message using the same key.

```c
int crypto_aead_chacha20poly1305_decrypt(unsigned char *m,
                                         unsigned long long *mlen_p,
                                         unsigned char *nsec,
                                         const unsigned char *c,
                                         unsigned long long clen,
                                         const unsigned char *ad,
                                         unsigned long long adlen,
                                         const unsigned char *npub,
                                         const unsigned char *k);
```

The `crypto_aead_chacha20poly1305_decrypt()` function verifies that the
ciphertext `c` (as produced by `crypto_aead_chacha20poly1305_encrypt()`)
includes a valid tag using a secret key `k`, a public nonce `npub`, and
additional data `ad` (`adlen` bytes).

`ad` can be a `NULL` pointer with `adlen` equal to `0` if no additional data are
required.

`nsec` is not used by this particular construction and should always be `NULL`.

The function returns `-1` if the verification fails.

If the verification succeeds, the function returns `0`, puts the decrypted
message into `m` and stores its actual number of bytes into `mlen` if `mlen` is
not a `NULL` pointer.

At most `clen - crypto_aead_chacha20poly1305_ABYTES` bytes will be put into `m`.

## Detached mode

Some applications may need to store the authentication tag and the encrypted
message at different locations.

For this specific use case, "detached" variants of the functions above are
available.

```c
int crypto_aead_chacha20poly1305_encrypt_detached(unsigned char *c,
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

The `crypto_aead_chacha20poly1305_encrypt_detached()` function encrypts a
message `m` with a key `k` and a nonce `npub`. It puts the resulting ciphertext,
whose length is equal to the message, into `c`.

It also computes a tag that authenticates the ciphertext as well as optional,
additional data `ad` of length `adlen`. This tag is put into `mac`, and its
length is `crypto_aead_chacha20poly1305_ABYTES` bytes.

`nsec` is not used by this particular construction and should always be `NULL`.

```c
int crypto_aead_chacha20poly1305_decrypt_detached(unsigned char *m,
                                                  unsigned char *nsec,
                                                  const unsigned char *c,
                                                  unsigned long long clen,
                                                  const unsigned char *mac,
                                                  const unsigned char *ad,
                                                  unsigned long long adlen,
                                                  const unsigned char *npub,
                                                  const unsigned char *k);
```

The `crypto_aead_chacha20poly1305_decrypt_detached()` function verifies that the
authentication tag `mac` is valid for the ciphertext `c` of length `clen` bytes,
the key `k` , the nonce `npub` and optional, additional data `ad` of length
`adlen` bytes.

If the tag is not valid, the function returns `-1` and doesn't do any further
processing.

If the tag is valid, the ciphertext is decrypted and the plaintext is put into
`m`. The length is equal to the length of the ciphertext.

`nsec` is not used by this particular construction and should always be `NULL`.

```c
void crypto_aead_chacha20poly1305_keygen(unsigned char k[crypto_aead_chacha20poly1305_KEYBYTES]);
```

This helper function introduced in libsodium 1.0.12 creates a random key `k`.

It is equivalent to calling `randombytes_buf()` but improves code clarity and
can prevent misuse by ensuring that the provided key length is always be
correct.

## Constants

* `crypto_aead_chacha20poly1305_KEYBYTES`
* `crypto_aead_chacha20poly1305_NPUBBYTES`
* `crypto_aead_chacha20poly1305_ABYTES`

## Algorithm details

* Encryption: ChaCha20 stream cipher
* Authentication: Poly1305 MAC

## Notes

In order to prevent nonce reuse, if a key is being reused, it is recommended to
increment the previous nonce instead of generating a random nonce for each
message.

To prevent nonce reuse in a client-server protocol, either use different keys
for each direction, or make sure that a bit is masked in one direction, and set
in the other.

The API conforms to the proposed API for the CAESAR competition.

A high-level `crypto_aead_*()` API is intentionally not defined until the
[CAESAR](http://competitions.cr.yp.to/caesar.html) competition is over.

## See also

* [ChaCha20 and Poly1305 based Cipher Suites for TLS](https://tools.ietf.org/html/draft-agl-tls-chacha20poly1305-04) -
  Specification of the original construction
