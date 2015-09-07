# The SHA-2 hash functions family

The SHA-256 and SHA-512 functions are provided for interoperability with other applications.

These functions are not keyed and are thus deterministic. In addition, they are vulnerable to length extension attacks.

A message can be hashed in a single pass, but a streaming API is also available to process a message as a sequence of multiple chunks.

If you are looking for a generic hash function and not specifically SHA-2, using `crypto_generichash()` (BLAKE2b) might be a better choice.

## Single-part SHA-256 example

```c
#define MESSAGE ((const unsigned char *) "test")
#define MESSAGE_LEN 4

unsigned char out[crypto_hash_sha256_BYTES];

crypto_hash_sha256(out, MESSAGE, MESSAGE_LEN);
```

## Multi-part SHA-256 example

```c
#define MESSAGE_PART1 \
    ((const unsigned char *) "Arbitrary data to hash")
#define MESSAGE_PART1_LEN 22

#define MESSAGE_PART2 \
    ((const unsigned char *) "is longer than expected")
#define MESSAGE_PART2_LEN 23

unsigned char out[crypto_hash_sha256_BYTES];
crypto_hash_sha256_state state;

crypto_hash_sha256_init(&state);

crypto_hash_sha256_update(&state, MESSAGE_PART1, MESSAGE_PART1_LEN);
crypto_hash_sha256_update(&state, MESSAGE_PART2, MESSAGE_PART2_LEN);

crypto_hash_sha256_final(&state, out);
```

## Usage

### SHA-256

Single-part:
```c
int crypto_hash_sha256(unsigned char *out, const unsigned char *in,
                       unsigned long long inlen);
```

Multi-part:
```c
int crypto_hash_sha256_init(crypto_hash_sha256_state *state);

int crypto_hash_sha256_update(crypto_hash_sha256_state *state,
                              const unsigned char *in,
                              unsigned long long inlen);

int crypto_hash_sha256_final(crypto_hash_sha256_state *state,
                             unsigned char *out);
```

### SHA-512

Single-part:
```c
int crypto_hash_sha512(unsigned char *out, const unsigned char *in,
                       unsigned long long inlen);
```

Multi-part:
```c
int crypto_hash_sha512_init(crypto_hash_sha512_state *state);

int crypto_hash_sha512_update(crypto_hash_sha512_state *state,
                              const unsigned char *in,
                              unsigned long long inlen);

int crypto_hash_sha512_final(crypto_hash_sha512_state *state,
                             unsigned char *out);
```

## Notes

The state must be initialized with `crypto_hash_sha*_init()` before updating or finalizing it.

After `crypto_hash_sha*_final()`, the state should not be used any more, unless it is reinitialized using `crypto_hash_sha*_init()`.

## Constants

- `crypto_hash_sha256_BYTES`
- `crypto_hash_sha512_BYTES`
- `crypto_hash_sha512256_BYTES`

## Data types

- `crypto_hash_sha256_state`
- `crypto_hash_sha512_state`
- `crypto_hash_sha512256_state`
