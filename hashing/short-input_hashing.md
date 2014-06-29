# Short-input hashing

## Example

```c
#define SHORT_DATA ((const unsigned char *) "Sparkling water")
#define SHORT_DATA_LEN 15

unsigned char hash[crypto_shorthash_BYTES];
unsigned char key[crypto_shorthash_KEYBYTES];

randombytes_buf(key, sizeof key);
crypto_shorthash(hash, SHORT_DATA, SHORT_DATA_LEN, key);
```

## Purpose

A lot of applications and programming language implementations have
been recently found to be vulnerable to denial-of-service attacks when
a hash function with weak security guarantees, such as Murmurhash 3, was
used to construct a hash table.

In order to address this, Sodium provides the “shorthash” function, whith outputs short, but unpredictable (without knowing the secret key)
values suitable for picking a list in a hash table for a given key.

This function is optimized for short inputs.

The output of this function is only 64 bits. Therefore, it should *not* be considered collision-resistant.

Use cases:
- Hash tables
- Probabilistic data structures such as Bloom filters
- Integrity checking in interactive protocols

## Usage

```c
int crypto_shorthash(unsigned char *out, const unsigned char *in,
                     unsigned long long inlen, const unsigned char *k);
```

Compute a fixed-size (`crypto_shorthash_BYTES` bytes) fingerprint for the message `in` whose length is `inlen` bytes, using the key `k`.

The `k` is `crypto_shorthash_KEYBYTES` bytes and can be created using `randombytes_buf()`.

The same message hashed with the same key will always produce the same output.

## Constants

- `crypto_shorthash_BYTES`
- `crypto_shorthash_KEYBYTES`

## Algorithm details

SipHash-2-4

