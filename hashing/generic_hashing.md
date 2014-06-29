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

`key` can be `NULL` and `keylen` can be `0`. In this case, a message will always have the same fingerprint, similar to the `MD5` or `SHA1` functions for which `crypto_generichash()` is a faster and more secure alternative.

But a key can also be specified. A message will always have the same fingerprint for a given key, but different keys used to hash the same message are very likely to produce distinct fingerprints.

In particular, the key can be used to make sure that different applications generate different fingerprints even if they process the same data.

The recommended key size is `crypto_generichash_KEYBYTES` bytes.

However, the key size can by any value between `crypto_generichash_KEYBYTES_MIN` (included) and `crypto_generichash_KEYBYTES_MAX` (included).

## Constants

- `crypto_generichash_BYTES`
- `crypto_generichash_BYTES_MIN`
- `crypto_generichash_BYTES_MAX`
- `crypto_generichash_KEYBYTES`
- `crypto_generichash_KEYBYTES_MIN`
- `crypto_generichash_KEYBYTES_MAX`

## Algorithm details

Blake2b

## Notes

Unlike functions such as MD5, SHA1 and SHA256, this function is safe against hash length extension attacks.
