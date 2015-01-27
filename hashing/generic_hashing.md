# Generic hashing

## Single-part example without a key

```c
#define MESSAGE ((const unsigned char *) "Arbitrary data to hash")
#define MESSAGE_LEN 22

unsigned char hash[crypto_generichash_BYTES];

crypto_generichash(hash, sizeof hash,
                   MESSAGE, MESSAGE_LEN,
                   NULL, 0);
```

## Single-part example with a key

```c
#define MESSAGE ((const unsigned char *) "Arbitrary data to hash")
#define MESSAGE_LEN 22

unsigned char hash[crypto_generichash_BYTES];
unsigned char key[crypto_generichash_KEYBYTES];

randombytes_buf(key, sizeof key);

crypto_generichash(hash, sizeof hash,
                   MESSAGE, MESSAGE_LEN,
                   key, sizeof key);
```

## Multi-part example with a key

```c
#define MESSAGE_PART1 \
    ((const unsigned char *) "Arbitrary data to hash")
#define MESSAGE_PART1_LEN 22

#define MESSAGE_PART2 \
    ((const unsigned char *) "is longer than expected")
#define MESSAGE_PART2_LEN 23

unsigned char hash[crypto_generichash_BYTES];
unsigned char key[crypto_generichash_KEYBYTES];
crypto_generichash_state state;

randombytes_buf(key, sizeof key);

crypto_generichash_init(&state, key, sizeof key, sizeof hash);

crypto_generichash_update(&state, MESSAGE_PART1, MESSAGE_PART1_LEN);
crypto_generichash_update(&state, MESSAGE_PART2, MESSAGE_PART2_LEN);

crypto_generichash_final(&state, hash, sizeof hash);
```

## Purpose

This function computes a fixed-length fingerprint for an arbitrary long message.

Sample use cases:
- File integrity checking
- Creating unique identifiers to index arbitrary long data

## Usage

```c
int crypto_generichash(unsigned char *out, size_t outlen,
                       const unsigned char *in, unsigned long long inlen,
                       const unsigned char *key, size_t keylen);
```

The `crypto_generichash()` function puts a fingerprint of the message `in` whose length is `inlen` bytes into `out`.
The output size can be chosen by the application.

The minimum recommended output size is `crypto_generichash_BYTES`. This size makes it practically impossible for two messages to produce the same fingerprint.

But for specific use cases, the size can be any value between `crypto_generichash_BYTES_MIN` (included) and `crypto_generichash_BYTES_MAX` (included).

`key` can be `NULL` and `keylen` can be `0`. In this case, a message will always have the same fingerprint, similar to the `MD5` or `SHA-1` functions for which `crypto_generichash()` is a faster and more secure alternative.

But a key can also be specified. A message will always have the same fingerprint for a given key, but different keys used to hash the same message are very likely to produce distinct fingerprints.

In particular, the key can be used to make sure that different applications generate different fingerprints even if they process the same data.

The recommended key size is `crypto_generichash_KEYBYTES` bytes.

However, the key size can by any value between `crypto_generichash_KEYBYTES_MIN` (included) and `crypto_generichash_KEYBYTES_MAX` (included).

```c
int crypto_generichash_init(crypto_generichash_state *state,
                            const unsigned char *key,
                            const size_t keylen, const size_t outlen);

int crypto_generichash_update(crypto_generichash_state *state,
                              const unsigned char *in,
                              unsigned long long inlen);

int crypto_generichash_final(crypto_generichash_state *state,
                             unsigned char *out, const size_t outlen);
```

The message doesn't have to be provided as a single chunk. The `generichash` operation also supports a streaming API.

The `crypto_generichash_init()` function initializes a state `state` with a key `key` (that can be `NULL`) of length `keylen` bytes, in order to eventually produce `outlen` bytes of output.

Each chunk of the complete message can then be sequentially processed by calling `crypto_generichash_update()`, providing the previously initialized state `state`, a pointer to the chunk `in` and the length of the chunk in bytes, `inlen`.

The `crypto_generichash_final()` function completes the operation and puts the final fingerprint into `out` as `outlen` bytes.

This alternative API is especially useful to process very large files and data streams.

## State structure alignment

The `crypto_generichash_state` structure is packed and its length is either 357 or 361 bytes. For this reason, when using `sodium_malloc()` to allocate a `crypto_generichash_state` structure, padding must be added in order to ensure proper alignment:

```c
state = sodium_malloc((sizeof(crypto_generichash_state)
                           + (size_t) 63U) & ~(size_t) 63U);
```

## Constants

- `crypto_generichash_BYTES`
- `crypto_generichash_BYTES_MIN`
- `crypto_generichash_BYTES_MAX`
- `crypto_generichash_KEYBYTES`
- `crypto_generichash_KEYBYTES_MIN`
- `crypto_generichash_KEYBYTES_MAX`

## Data types

- `crypto_generichash_state`

## Algorithm details

Blake2b

## Notes

Unlike functions such as MD5, SHA-1 and SHA-256, this function is safe against hash length extension attacks.

Blake2b's salt and personalisation parameters are accessible through the lower-level functions whose prototypes are defined in `crypto_generichash_blake2b.h`.
