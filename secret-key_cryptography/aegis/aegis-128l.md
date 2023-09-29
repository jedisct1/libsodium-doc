# AEGIS-128L

AEGIS-128L is a modern AES-based cipher with unique properties making it easier and safer to use than common alternatives:

  - 256-bit authentication tags, ensuring collision resistance within a given key; a tag can thus be used as a unique identifier for a message.
  - It can safely encrypt a practically unlimited number of messages, without any practical limits on their lengths.
  - It has a 128 bit nonce size, allowing random nonces to be safely used up to 2^48 messages for a single key.
  - It has a better security margin than AES-GCM
  - Leaking the state doesn’t leak the key
  - It is assumed to be key-committing, preventing partitioning attacks affecting other ciphers when used with low-entropy keys such as passwords. Namely, it is difficult to find distinct keys that successfully verify the same `(nonce, AD, ciphertext, tag)` tuple.

AEGIS-128L is also extremely fast on recent CPUs with AES pipelines, with lower memory usage than AES-GCM.

However, on platforms without hardware AES support, it is slow and not guaranteed to be protected against side channels. In that scenario, XChaCha20-Poly1305 is a better choice.

Unlike all other ciphers in libsodium, AEGIS-128L uses a 128 bit key.

## Example (combined mode)

``` c
#define MESSAGE (const unsigned char *) "test"
#define MESSAGE_LEN 4
#define ADDITIONAL_DATA (const unsigned char *) "123456"
#define ADDITIONAL_DATA_LEN 6

unsigned char nonce[crypto_aead_aegis128l_NPUBBYTES];
unsigned char key[crypto_aead_aegis128l_KEYBYTES];
unsigned char ciphertext[MESSAGE_LEN + crypto_aead_aegis128l_ABYTES];
unsigned long long ciphertext_len;

crypto_aead_aegis128l_keygen(key);
randombytes_buf(nonce, sizeof nonce);

crypto_aead_aegis128l_encrypt(ciphertext, &ciphertext_len,
                              MESSAGE, MESSAGE_LEN,
                              ADDITIONAL_DATA, ADDITIONAL_DATA_LEN,
                              NULL, nonce, key);

unsigned char decrypted[MESSAGE_LEN];
unsigned long long decrypted_len;
if (crypto_aead_aegis128l_decrypt(decrypted, &decrypted_len,
                                  NULL,
                                  ciphertext, ciphertext_len,
                                  ADDITIONAL_DATA,
                                  ADDITIONAL_DATA_LEN,
                                  nonce, key) != 0) {
    /* message forged! */
}
```

## Combined mode

In combined mode, the authentication tag is directly appended to the encrypted message. This is usually what you want.

``` c
int crypto_aead_aegis128l_encrypt(unsigned char *c,
                                  unsigned long long *clen_p,
                                  const unsigned char *m,
                                  unsigned long long mlen,
                                  const unsigned char *ad,
                                  unsigned long long adlen,
                                  const unsigned char *nsec,
                                  const unsigned char *npub,
                                  const unsigned char *k);
```

The `crypto_aead_aegis128l_encrypt()` function encrypts a message `m` whose length is `mlen` bytes using a secret key `k` (`crypto_aead_aegis128l_KEYBYTES` bytes) and public nonce `npub` (`crypto_aead_aegis128l_NPUBBYTES` bytes).

The encrypted message, as well as a tag authenticating both the confidential message `m` and `adlen` bytes of non-confidential data `ad`, are put into `c`.

`ad` can be a `NULL` pointer with `adlen` equal to `0` if no additional data are required.

At most `mlen + crypto_aead_aegis128l_ABYTES` bytes are put into `c`, and the actual number of bytes is stored into `clen` unless `clen` is a `NULL` pointer.

`nsec` is not used by this particular construction and should always be `NULL`.

The public nonce `npub` should never ever be reused with the same key. The recommended way to generate it is to use `randombytes_buf()` for the first message, and increment it for each subsequent message using the same key.

``` c
int crypto_aead_aegis128l_decrypt(unsigned char *m,
                                  unsigned long long *mlen_p,
                                  unsigned char *nsec,
                                  const unsigned char *c,
                                  unsigned long long clen,
                                  const unsigned char *ad,
                                  unsigned long long adlen,
                                  const unsigned char *npub,
                                  const unsigned char *k);
```

The `crypto_aead_aegis128l_decrypt()` function verifies that the ciphertext `c` (as produced by `crypto_aead_aegis128l_encrypt()`) includes a valid tag using a secret key `k`, a public nonce `npub`, and additional data `ad` (`adlen` bytes).

`ad` can be a `NULL` pointer with `adlen` equal to `0` if no additional data are required.

`nsec` is not used by this particular construction and should always be `NULL`.

The function returns `-1` if the verification fails.

If the verification succeeds, the function returns `0`, puts the decrypted message into `m` and stores its actual number of bytes into `mlen` if `mlen` is not a `NULL` pointer.

At most `clen - crypto_aead_aegis128l_ABYTES` bytes will be put into `m`.

## Detached mode

Some applications may need to store the authentication tag and the encrypted message at different locations.

For this specific use case, “detached” variants of the functions above are available.

``` c
int crypto_aead_aegis128l_encrypt_detached(unsigned char *c,
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

The `crypto_aead_aegis128l_encrypt_detached()` function encrypts a message `m` with a key `k` and a nonce `npub`. It puts the resulting ciphertext, whose length is equal to the message, into `c`.

It also computes a tag that authenticates the ciphertext as well as optional, additional data `ad` of length `adlen`. This tag is put into `mac`, and its length is `crypto_aead_aegis128l_ABYTES` bytes.

`nsec` is not used by this particular construction and should always be `NULL`.

``` c
int crypto_aead_aegis128l_decrypt_detached(unsigned char *m,
                                           unsigned char *nsec,
                                           const unsigned char *c,
                                           unsigned long long clen,
                                           const unsigned char *mac,
                                           const unsigned char *ad,
                                           unsigned long long adlen,
                                           const unsigned char *npub,
                                           const unsigned char *k);
```

The `crypto_aead_aegis128l_decrypt_detached()` function verifies that the authentication tag `mac` is valid for the ciphertext `c` of length `clen` bytes, the key `k` , the nonce `npub` and optional, additional data `ad` of length `adlen` bytes.

If the tag is not valid, the function returns `-1` and doesn’t do any further processing.

If the tag is valid, the ciphertext is decrypted and the plaintext is put into `m`. The length is equal to the length of the ciphertext.

`nsec` is not used by this particular construction and should always be `NULL`.

``` c
void crypto_aead_aegis128l_keygen(unsigned char k[crypto_aead_aegis128l_KEYBYTES]);
```

This is equivalent to calling `randombytes_buf()` but improves code clarity and can prevent misuse by ensuring that the provided key length is always be correct.

## Constants

  - `crypto_aead_aegis128l_ABYTES`
  - `crypto_aead_aegis128l_KEYBYTES`
  - `crypto_aead_aegis128l_NPUBBYTES`

## Notes

- The key size is 128 bits (16 bytes), unlike all other ciphers in this library.
- Unique nonces are required for each messsages.
- AEGIS can also be used as a very fast MAC, by encrypting an empty message, and putting the actual message to be authenticated in the `ad` parameter, which can be up to 2^61 bytes long.
- Unlike AES-GCM and Salsa/ChaChaPoly1305, it is believed to be impractical to find multiple AEGIS keys that successfully decrypt a given `(ad, ciphertext, tag)` tuple (_r-BIND_ security). However, this security property doesn't hold true any more if the associated data inputs can be freely chosen in addition to the keys (_FROB_ security).
- AEGIS was added in libsodium version 1.0.19.

## See also

  - [The AEGIS Family Of Authenticated Encryption Algorithms](https://datatracker.ietf.org/doc/draft-irtf-cfrg-aegis-aead) - AEGIS specification
  - [Reference implementations](https://github.com/jedisct1/draft-aegis-aead/tree/main/reference-implementations)
  - [libaegis](https://github.com/jedisct1/libaegis) - A more extensive C library for AEGIS variants
