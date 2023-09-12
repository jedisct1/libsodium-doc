# HMAC-SHA-2

The keyed message authentication codes HMAC-SHA-256, HMAC-SHA-512 and
HMAC-SHA512-256 (truncated HMAC-SHA-512) are provided.

The [`crypto_auth`](../secret-key_cryptography/secret-key_authentication.md)
API provides a simplified interface for message authentication.

If required, a streaming API is available to process a message as a sequence of
multiple chunks.

## Single-part example

```c
#define MESSAGE ((const unsigned char *) "Arbitrary data to hash")
#define MESSAGE_LEN 22

unsigned char hash[crypto_auth_hmacsha512_BYTES];
unsigned char key[crypto_auth_hmacsha512_KEYBYTES];

crypto_auth_hmacsha512_keygen(key);
crypto_auth_hmacsha512(hash, MESSAGE, MESSAGE_LEN, key);
```

## Multi-part example

```c
#define MESSAGE_PART1 \
    ((const unsigned char *) "Arbitrary data to hash")
#define MESSAGE_PART1_LEN 22

#define MESSAGE_PART2 \
    ((const unsigned char *) "is longer than expected")
#define MESSAGE_PART2_LEN 23

unsigned char hash[crypto_auth_hmacsha512_BYTES];
unsigned char key[crypto_auth_hmacsha512_KEYBYTES];
crypto_auth_hmacsha512_state state;

crypto_auth_hmacsha512_keygen(key);

crypto_auth_hmacsha512_init(&state, key, sizeof key);

crypto_auth_hmacsha512_update(&state, MESSAGE_PART1, MESSAGE_PART1_LEN);
crypto_auth_hmacsha512_update(&state, MESSAGE_PART2, MESSAGE_PART2_LEN);

crypto_auth_hmacsha512_final(&state, hash);
```

## Usage

### HMAC-SHA-256

```c
int crypto_auth_hmacsha256(unsigned char *out,
                           const unsigned char *in,
                           unsigned long long inlen,
                           const unsigned char *k);
```

The `crypto_auth_hmacsha256()` function authenticates a message `in` whose
length is `inlen` using the secret key `k` whose length is
`crypto_auth_hmacsha256_KEYBYTES`, and puts the authenticator into `out`
(`crypto_auth_hmacsha256_BYTES` bytes).

```c
int crypto_auth_hmacsha256_verify(const unsigned char *h,
                                  const unsigned char *in,
                                  unsigned long long inlen,
                                  const unsigned char *k);
```

The `crypto_auth_hmacsha256_verify()` function verifies in constant time that
`h` is a correct authenticator for the message `in` whose length is `inlen`
under a secret key `k` (`crypto_auth_hmacsha256_KEYBYTES` bytes).

It returns `-1` if the verification fails, and `0` on success.

A multi-part (streaming) API can be used instead of `crypto_auth_hmacsha256()`:

```c
int crypto_auth_hmacsha256_init(crypto_auth_hmacsha256_state *state,
                                const unsigned char *key,
                                size_t keylen);
```

```c
int crypto_auth_hmacsha256_update(crypto_auth_hmacsha256_state *state,
                                  const unsigned char *in,
                                  unsigned long long inlen);
```

```c
int crypto_auth_hmacsha256_final(crypto_auth_hmacsha256_state *state,
                                 unsigned char *out);
```

This alternative API supports a key of arbitrary length `keylen`.

However, please note that in the HMAC construction, a key larger than the block
size gets reduced to `h(key)`.

```c
void crypto_auth_hmacsha256_keygen(unsigned char k[crypto_auth_hmacsha256_KEYBYTES]);
```

This helper function introduced in libsodium 1.0.12 creates a random key `k`.

It is equivalent to calling `randombytes_buf()` but improves code clarity and
can prevent misuse by ensuring that the provided key length is always be
correct.

### HMAC-SHA-512

Similarily to the `crypto_auth_hmacsha256_*()` set of functions, the
`crypto_auth_hmacsha512_*()` set of functions implements HMAC-SHA512:

```c
int crypto_auth_hmacsha512(unsigned char *out,
                           const unsigned char *in,
                           unsigned long long inlen,
                           const unsigned char *k);
```

```c
int crypto_auth_hmacsha512_verify(const unsigned char *h,
                                  const unsigned char *in,
                                  unsigned long long inlen,
                                  const unsigned char *k);
```

```c
int crypto_auth_hmacsha512_init(crypto_auth_hmacsha512_state *state,
                                const unsigned char *key,
                                size_t keylen);
```

```c
int crypto_auth_hmacsha512_update(crypto_auth_hmacsha512_state *state,
                                  const unsigned char *in,
                                  unsigned long long inlen);
```

```c
int crypto_auth_hmacsha512_final(crypto_auth_hmacsha512_state *state,
                                 unsigned char *out);
```

```c
void crypto_auth_hmacsha512_keygen(unsigned char k[crypto_auth_hmacsha512_KEYBYTES]);
```

### HMAC-SHA-512-256

HMAC-SHA-512-256 is implemented as HMAC-SHA-512 with the output truncated to 256
bits. This is slightly faster than HMAC-SHA-256.
Note that this construction is not the same as HMAC-SHA-512/256,
which is HMAC using the SHA-512/256 function.

```c
int crypto_auth_hmacsha512256(unsigned char *out,
                              const unsigned char *in,
                              unsigned long long inlen,
                              const unsigned char *k);
```

```c
int crypto_auth_hmacsha512256_verify(const unsigned char *h,
                                     const unsigned char *in,
                                     unsigned long long inlen,
                                     const unsigned char *k);
```

```c
int crypto_auth_hmacsha512256_init(crypto_auth_hmacsha512256_state *state,
                                   const unsigned char *key,
                                   size_t keylen);
```

```c
int crypto_auth_hmacsha512256_update(crypto_auth_hmacsha512256_state *state,
                                     const unsigned char *in,
                                     unsigned long long inlen);
```

```c
int crypto_auth_hmacsha512256_final(crypto_auth_hmacsha512256_state *state,
                                    unsigned char *out);
```

```c
void crypto_auth_hmacsha512256_keygen(unsigned char k[crypto_auth_hmacsha512256_KEYBYTES]);
```

## Constants

* `crypto_auth_hmacsha256_BYTES`
* `crypto_auth_hmacsha256_KEYBYTES`
* `crypto_auth_hmacsha512_BYTES`
* `crypto_auth_hmacsha512_KEYBYTES`
* `crypto_auth_hmacsha512256_BYTES`
* `crypto_auth_hmacsha512256_KEYBYTES`

## Data types

* `crypto_auth_hmacsha256_state`
* `crypto_auth_hmacsha512_state`
* `crypto_auth_hmacsha512256_state`

## Notes

* The state must be initialized with `crypto_auth_hmacsha*_init()` before
  updating or finalizing it. After `crypto_auth_hmacsha*_final()` returns, the
  state should not be used any more, unless it is reinitialized using
  `crypto_auth_hmacsha*_init()`.

* Arbitrary key lengths are supported using the multi-part interface.

* `crypto_auth_hmacsha256_*()` can be used to create AWS HMAC-SHA256 request
  signatures.

* Only use these functions for interoperability with 3rd party services. For
  everything else, you should probably use
  `crypto_auth()`/`crypto_auth_verify()` or `crypto_generichash_*()` instead.
