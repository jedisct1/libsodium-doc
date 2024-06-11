# HKDF key derivation function

HKDF (HMAC-based Extract-and-Expand Key Derivation Function) is a key derivation function used by many standard protocols.

It actually includes two operations:

  - **extract:** this operation absorbs an arbitrary-long sequence of bytes and outputs a fixed-size master key (also known as `PRK`), suitable for use with the second function (*expand*).
  - **expand:** this operation generates an variable size subkey given a master key (also known as `PRK`) and a description of a key (or “context”) to derive from it. That operation can be repeated with different descriptions in order to derive as many keys as necessary.

The latter can be used without the former, if a randomly sampled key of the right size is already available.

## Deriving keys from a master key

Example:

``` c
unsigned char prk[crypto_kdf_hkdf_sha256_KEYBYTES];
unsigned char subkey1[32];
unsigned char subkey2[32];
unsigned char subkey3[64];

crypto_kdf_hkdf_sha256_keygen(prk);

crypto_kdf_hkdf_sha256_expand(subkey1, sizeof subkey1,
                              "key for encryption",
                              (sizeof "key for encryption") - 1,
                              prk);
crypto_kdf_hkdf_sha256_expand(subkey2, sizeof subkey2,
                              "key for signatures",
                              (sizeof "key for signatures") - 1,
                              prk);
crypto_kdf_hkdf_sha256_expand(subkey3, sizeof subkey3,
                              "key for something else",
                              (sizeof "key for something else") - 1,
                              prk);
```

Usage:

``` c
int crypto_kdf_hkdf_sha256_expand(
    unsigned char *out, size_t out_len,
    const char *ctx, size_t ctx_len,
    const unsigned char prk[crypto_kdf_hkdf_sha256_KEYBYTES]);
```

The `crypto_kdf_hkdf_sha256_expand()` function derives a subkey from a context/description `ctx` of length `ctx_len` bytes and a master key `prk` of length `crypto_kdf_hkdf_sha256_KEYBYTES` bytes.

The key is stored into `out` whose length is `out_len` bytes.

Up to `crypto_kdf_hkdf_sha256_BYTES_MAX` bytes can be produced.

The generated keys satisfy the typical requirements of keys used for symmetric cryptography. In particular, they appear to be sampled from a uniform distribution over the entire range of possible keys.

Contexts don’t have to be secret. They just need to be distinct in order to produce distinct keys from the same master key.

Any `crypto_kdf_hkdf_sha256_KEYBYTES` bytes key that appears to be sampled from a uniform distribution can be used for the `prk`. For example, the output of a key exchange mechanism (such as `crypto_kx_*`) can be used as a master key.

For convenience, the `crypto_kdf_hkdf_sha256_keygen()` function creates a random `prk`.

The master key should remain secret.

`crypto_kdf_hkdf_sha256_expand()` is effectively a standard alternative to `crypto_kdf_derive_from_key()`. It is slower, but the context can be of any size.

## Creating a master key from input keying material

Example:

``` c
#define APPLICATION_UUID "6723D3AA-C6CA-4F3C-8F24-94B550C5F10A"
#define IKM "John Doe - 951a 6158 4fe0 8a0b ad7c b57b 7687 09b6"

crypto_kdf_hkdf_sha256_extract(prk,
                               (const unsigned char *) APPLICATION_UUID,
                               (sizeof APPLICATION_UUID) - 1,
                               (const unsigned char *) IKM,
                               (sizeof IKM) - 1);
```

Usage:

``` c
int crypto_kdf_hkdf_sha256_extract(unsigned char prk[crypto_kdf_hkdf_sha256_KEYBYTES],
                                   const unsigned char *salt, size_t salt_len,
                                   const unsigned char *ikm, size_t ikm_len);
```

The `crypto_kdf_hkdf_sha256_extract()` function creates a master key (`prk`) given an optional salt `salt` (which can be `NULL`, or `salt_len` bytes), and input keying material `ikm` of size `ikm_len` bytes.

`salt` is optional. It can be a public, unique identifier for a protocol or application. Its purpose is to ensure that distinct keys will be created even if the input keying material is accidentally reused across protocols.

A UUID is a decent example of a `salt`. There is no minimum length.

If input keying material cannot be accidentally reused, using an empty (`NULL`) salt is perfectly acceptable.

`ikm` (Input Keying Material) is an arbitrary-long byte sequence. The bytes don’t have to be sampled from a uniform distribution. It can be any combination of text and binary data.

But the overall sequence needs to include some entropy.

The resulting PRK will roughly have the same entropy. The “extract” operation effectively extracts the entropy and packs it into a fixed-size key, but it doesn’t *add* any entropy.

## Incremental entropy extraction

Example:

``` c
#define IKM1 "John Doe - "
#define IKM2 "951a 6158 4fe0 8a0b ad7c b57b 7687 09b6"

crypto_kdf_hkdf_sha256_extract_init(&st, NULL, 0);
crypto_kdf_hkdf_sha256_extract_update(&st,
                                      (const unsigned char *) IKM1,
                                      (sizeof IKM1) - 1);
crypto_kdf_hkdf_sha256_extract_update(&st,
                                      (const unsigned char *) IKM2,
                                      (sizeof IKM2) - 1);
crypto_kdf_hkdf_sha256_extract_final(&st, prk);
```

Usage:

``` c
int crypto_kdf_hkdf_sha256_extract_init(
    crypto_kdf_hkdf_sha256_state *state,
    const unsigned char *salt, size_t salt_len);

int crypto_kdf_hkdf_sha256_extract_update(
    crypto_kdf_hkdf_sha256_state *state,
    const unsigned char *ikm, size_t ikm_len);

int crypto_kdf_hkdf_sha256_extract_final(
    crypto_kdf_hkdf_sha256_state *state,
    unsigned char prk[crypto_kdf_hkdf_sha256_KEYBYTES]);
```

Instead of a one-shot call to `crypto_kdf_hkdf_sha256_extract()`, it is possible to feed the input keying material incrementally.

In order to do so, initialize a state with `crypto_kdf_hkdf_sha256_extract_init()`, then call `crypto_kdf_hkdf_sha256_extract_update()` as many times as required, and finally generate the key with `crypto_kdf_hkdf_sha256_extract_final()`.

## HKDF-SHA256 and HKDF-SHA512

Both the `SHA256` and the `SHA512` instantiations are supported.

The functions documented above use `HKDF-SHA256`, but the `HKDF-SHA512` can be used simply by replacing the `crypto_kdf_hkdf_sha256` prefix with `crypto_kdf_hkdf_sha512`.

`HKDF-SHA512` is present for consistency and compatibility with existing protocols, but it doesn’t have practical security benefits over `HKDF-SHA256`.

Therefore, the `SHA256` instantiation is generally recommended.

## Constants

  - `crypto_kdf_hkdf_sha256_KEYBYTES`
  - `crypto_kdf_hkdf_sha256_BYTES_MIN`
  - `crypto_kdf_hkdf_sha256_BYTES_MAX`
  - `crypto_kdf_hkdf_sha512_KEYBYTES`
  - `crypto_kdf_hkdf_sha512_BYTES_MIN`
  - `crypto_kdf_hkdf_sha512_BYTES_MAX`

## Algorithm details

  - [RFC5869 - HMAC-based Extract-and-Expand Key Derivation Function](https://www.rfc-editor.org/rfc/rfc5869.html)

## Notes

HKDF was added in libsodium version 1.0.19.
