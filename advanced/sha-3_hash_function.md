# The SHA-3 hash functions family

The SHA3-256 and SHA3-512 functions are provided for interoperability with other applications and protocols. If you are looking for a general-purpose hash function and not specifically SHA-3, using [`crypto_generichash()`](../hashing/generic_hashing.md) (BLAKE2b) is usually a better choice.

These functions are also not suitable for hashing passwords or deriving keys from passwords. Use one of the [password hashing](../password_hashing/README.md) APIs instead.

These functions are not keyed and are thus deterministic.

A message can be hashed in a single pass, but a streaming API is also available to process a message as a sequence of multiple chunks.

All these functions return `0` on success.

## Single-part SHA3-256 example

``` c
#define MESSAGE ((const unsigned char *) "test")
#define MESSAGE_LEN 4

unsigned char out[crypto_hash_sha3256_BYTES];

crypto_hash_sha3256(out, MESSAGE, MESSAGE_LEN);
```

## Single-part SHA3-512 example

``` c
#define MESSAGE ((const unsigned char *) "test")
#define MESSAGE_LEN 4

unsigned char out[crypto_hash_sha3512_BYTES];

crypto_hash_sha3512(out, MESSAGE, MESSAGE_LEN);
```

## Multi-part SHA3-256 example

``` c
#define MESSAGE_PART1 \
    ((const unsigned char *) "Arbitrary data to hash")
#define MESSAGE_PART1_LEN 22

#define MESSAGE_PART2 \
    ((const unsigned char *) "is longer than expected")
#define MESSAGE_PART2_LEN 23

unsigned char out[crypto_hash_sha3256_BYTES];
crypto_hash_sha3256_state state;

crypto_hash_sha3256_init(&state);

crypto_hash_sha3256_update(&state, MESSAGE_PART1, MESSAGE_PART1_LEN);
crypto_hash_sha3256_update(&state, MESSAGE_PART2, MESSAGE_PART2_LEN);

crypto_hash_sha3256_final(&state, out);
```

## Usage

### SHA3-256

Single-part:

``` c
int crypto_hash_sha3256(unsigned char *out, const unsigned char *in,
                        unsigned long long inlen);
```

Multi-part:

``` c
int crypto_hash_sha3256_init(crypto_hash_sha3256_state *state);

int crypto_hash_sha3256_update(crypto_hash_sha3256_state *state,
                               const unsigned char *in,
                               unsigned long long inlen);

int crypto_hash_sha3256_final(crypto_hash_sha3256_state *state,
                              unsigned char *out);
```

### SHA3-512

Single-part:

``` c
int crypto_hash_sha3512(unsigned char *out, const unsigned char *in,
                        unsigned long long inlen);
```

Multi-part:

``` c
int crypto_hash_sha3512_init(crypto_hash_sha3512_state *state);

int crypto_hash_sha3512_update(crypto_hash_sha3512_state *state,
                               const unsigned char *in,
                               unsigned long long inlen);

int crypto_hash_sha3512_final(crypto_hash_sha3512_state *state,
                              unsigned char *out);
```

## Notes

The state must be initialized with `crypto_hash_sha3*_init()` before updating or finalizing it.

After `crypto_hash_sha3*_final()`, the state should not be used any more, unless it is reinitialized using `crypto_hash_sha3*_init()`.

The `crypto_hash_sha3256_statebytes()` and `crypto_hash_sha3512_statebytes()` helper functions return the size of the corresponding state structures and are useful when state objects need to be allocated dynamically.

These functions were introduced in libsodium 1.0.22.

## Constants

  - `crypto_hash_sha3256_BYTES`
  - `crypto_hash_sha3512_BYTES`

## Data types

  - `crypto_hash_sha3256_state`
  - `crypto_hash_sha3512_state`
