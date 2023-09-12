# Short-input hashing

## Example

``` c
#define SHORT_DATA ((const unsigned char *) "Sparkling water")
#define SHORT_DATA_LEN 15

unsigned char hash[crypto_shorthash_BYTES];
unsigned char key[crypto_shorthash_KEYBYTES];

crypto_shorthash_keygen(key);
crypto_shorthash(hash, SHORT_DATA, SHORT_DATA_LEN, key);
```

## Purpose

Many applications and programming language implementations were recently found to be vulnerable to denial-of-service (DoS) attacks when a hash function with weak security guarantees, such as MurmurHash3, was used to construct a hash table.

To address this, Sodium provides the `crypto_shorthash()` function, which outputs short but unpredictable (without knowing the secret key) values suitable for picking a list in a hash table for a given key.

This function is optimized for short inputs.

The output of this function is only 64 bits. Therefore, it should *not* be considered collision-resistant.

Use cases:

  - Hash tables
  - Probabilistic data structures, such as Bloom filters
  - Integrity checking in interactive protocols

## Usage

``` c
int crypto_shorthash(unsigned char *out, const unsigned char *in,
                     unsigned long long inlen, const unsigned char *k);
```

Compute a fixed-size (`crypto_shorthash_BYTES` bytes) fingerprint for the message `in` whose length is `inlen` bytes, using the key `k`.

The `k` is `crypto_shorthash_KEYBYTES` bytes and can be created using `crypto_shorthash_keygen()`.

The same message hashed with the same key will always produce the same output.

## Constants

  - `crypto_shorthash_BYTES`
  - `crypto_shorthash_KEYBYTES`

## Algorithm details

SipHash-2-4

## Notes

  - The key must remain secret. This function will not provide any mitigations against DoS attacks if the key is known from attackers.
  - When building hash tables, it is recommended to use a prime number for the table size. This ensures that all bits from the output of the hash function are being used. Mapping the range of the hash function to `[0..N)` can be done efficiently [without modulo reduction](http://lemire.me/blog/2016/06/27/a-fast-alternative-to-the-modulo-reduction/).
  - libsodium \>= 1.0.12 also implements a variant of SipHash with the same key size but a 128-bit output, accessible as `crypto_shorthash_siphashx24()`.
