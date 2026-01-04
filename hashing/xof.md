# Extendable output functions

An extendable output function (XOF) is similar to a hash function, but its output can be extended to any desired length.

Unlike a hash function where the output size is fixed, a XOF can produce output of arbitrary length from the same input, making it useful for key derivation, stream generation, and applications where variable-length output is needed.

libsodium provides two families of XOFs:

  - SHAKE: NIST-standardized XOFs from [FIPS 202](https://csrc.nist.gov/pubs/fips/202/final)
  - TurboSHAKE: Faster variants using reduced-round Keccak, standardized in [RFC 9861](https://www.rfc-editor.org/rfc/rfc9861.html)

## Single-part example

``` c
#define MESSAGE ((const unsigned char *) "Arbitrary data to hash")
#define MESSAGE_LEN 22

unsigned char out[64];

crypto_xof_shake256(out, sizeof out, MESSAGE, MESSAGE_LEN);
```

## Multi-part example

``` c
#define MESSAGE_PART1 \
    ((const unsigned char *) "Arbitrary data to hash")
#define MESSAGE_PART1_LEN 22

#define MESSAGE_PART2 \
    ((const unsigned char *) "is longer than expected")
#define MESSAGE_PART2_LEN 23

unsigned char out[64];
crypto_xof_shake256_state state;

crypto_xof_shake256_init(&state);

crypto_xof_shake256_update(&state, MESSAGE_PART1, MESSAGE_PART1_LEN);
crypto_xof_shake256_update(&state, MESSAGE_PART2, MESSAGE_PART2_LEN);

crypto_xof_shake256_squeeze(&state, out, sizeof out);
```

## Incremental output

Unlike regular hash functions, XOFs can be squeezed multiple times to produce additional output. The concatenation of all squeezed outputs is identical to squeezing the total length at once.

``` c
unsigned char seed[32];
randombytes_buf(seed, sizeof seed);

crypto_xof_shake256_state state;
crypto_xof_shake256_init(&state);
crypto_xof_shake256_update(&state, seed, sizeof seed);

unsigned char key1[32], key2[32], key3[32];
crypto_xof_shake256_squeeze(&state, key1, sizeof key1);
crypto_xof_shake256_squeeze(&state, key2, sizeof key2);
crypto_xof_shake256_squeeze(&state, key3, sizeof key3);
```

## Purpose

XOFs can be used as:

  - Hash functions: producing fixed-length digests
  - Key derivation functions: deriving multiple keys from a seed
  - Deterministic random generators: expanding a seed into arbitrary-length output
  - Domain-separated hashing: TurboSHAKE supports custom domain separators

## SHAKE

SHAKE128 and SHAKE256 are XOFs defined in FIPS 202, based on the Keccak permutation with 24 rounds.

### Single-part API

``` c
int crypto_xof_shake256(unsigned char *out, size_t outlen,
                        const unsigned char *in, unsigned long long inlen);

int crypto_xof_shake128(unsigned char *out, size_t outlen,
                        const unsigned char *in, unsigned long long inlen);
```

The `crypto_xof_shake256()` function hashes `inlen` bytes from `in` and writes `outlen` bytes into `out`.

The output length can be any value. Common choices are 32 or 64 bytes, but the output can be much longer when the XOF is used for key derivation or as a deterministic random generator.

### Multi-part API

``` c
int crypto_xof_shake256_init(crypto_xof_shake256_state *state);

int crypto_xof_shake256_update(crypto_xof_shake256_state *state,
                               const unsigned char *in,
                               unsigned long long inlen);

int crypto_xof_shake256_squeeze(crypto_xof_shake256_state *state,
                                unsigned char *out, size_t outlen);
```

The multi-part API allows hashing data provided in chunks, and squeezing output incrementally.

After calling `crypto_xof_shake256_init()`, `crypto_xof_shake256_update()` can be called repeatedly to absorb data. Once all data has been absorbed, `crypto_xof_shake256_squeeze()` can be called repeatedly to produce output.

After squeezing begins, no more data can be absorbed into the state.

SHAKE128 has equivalent functions with `shake128` instead of `shake256` in the names.

### Custom domain separation

``` c
int crypto_xof_shake256_init_with_domain(crypto_xof_shake256_state *state,
                                         unsigned char domain);
```

The `crypto_xof_shake256_init_with_domain()` function initializes the state with a custom domain separator instead of the standard one. This produces outputs unrelated to the standard variant, allowing different applications to use the same underlying XOF without risk of collisions.

The domain separator must be between `0x01` and `0x7F`.

### Constants

  - `crypto_xof_shake256_BLOCKBYTES` (136)
  - `crypto_xof_shake256_STATEBYTES` (256)
  - `crypto_xof_shake128_BLOCKBYTES` (168)
  - `crypto_xof_shake128_STATEBYTES` (256)

### Data types

  - `crypto_xof_shake256_state`
  - `crypto_xof_shake128_state`

## TurboSHAKE

TurboSHAKE128 and TurboSHAKE256 are faster variants of SHAKE that use 12 rounds of the Keccak permutation instead of 24. They are roughly twice as fast as SHAKE while maintaining the same security claims.

TurboSHAKE is the underlying function of KangarooTwelve. Both are standardized in RFC 9861.

### Single-part API

``` c
int crypto_xof_turboshake256(unsigned char *out, size_t outlen,
                             const unsigned char *in, unsigned long long inlen);

int crypto_xof_turboshake128(unsigned char *out, size_t outlen,
                             const unsigned char *in, unsigned long long inlen);
```

### Multi-part API

``` c
int crypto_xof_turboshake256_init(crypto_xof_turboshake256_state *state);

int crypto_xof_turboshake256_update(crypto_xof_turboshake256_state *state,
                                    const unsigned char *in,
                                    unsigned long long inlen);

int crypto_xof_turboshake256_squeeze(crypto_xof_turboshake256_state *state,
                                     unsigned char *out, size_t outlen);
```

TurboSHAKE128 has equivalent functions with `turboshake128` instead of `turboshake256` in the names.

### Custom domain separation

``` c
int crypto_xof_turboshake256_init_with_domain(crypto_xof_turboshake256_state *state,
                                              unsigned char domain);
```

Domain-separated hashing is useful for deriving independent functions from the same primitive:

``` c
#define DOMAIN_KEY_DERIVATION 0x01
#define DOMAIN_COMMITMENT     0x02

unsigned char master_secret[32];
/* ... */

/* Derive an encryption key */
unsigned char enc_key[32];
crypto_xof_turboshake256_state state;
crypto_xof_turboshake256_init_with_domain(&state, DOMAIN_KEY_DERIVATION);
crypto_xof_turboshake256_update(&state, master_secret, sizeof master_secret);
crypto_xof_turboshake256_squeeze(&state, enc_key, sizeof enc_key);

/* Compute a commitment (independent from the key derivation) */
unsigned char commitment[32];
crypto_xof_turboshake256_init_with_domain(&state, DOMAIN_COMMITMENT);
crypto_xof_turboshake256_update(&state, master_secret, sizeof master_secret);
crypto_xof_turboshake256_squeeze(&state, commitment, sizeof commitment);
```

The domain separator must be between `0x01` and `0x7F`.

### Constants

  - `crypto_xof_turboshake256_BLOCKBYTES` (136)
  - `crypto_xof_turboshake256_STATEBYTES` (256)
  - `crypto_xof_turboshake128_BLOCKBYTES` (168)
  - `crypto_xof_turboshake128_STATEBYTES` (256)

### Data types

  - `crypto_xof_turboshake256_state`
  - `crypto_xof_turboshake128_state`

## Which variant to use

  - SHAKE256: Maximum security (256-bit), NIST standardized, good default choice when compliance is required
  - SHAKE128: 128-bit security, slightly faster than SHAKE256
  - TurboSHAKE256: Maximum security with \~2x speed improvement over SHAKE256
  - TurboSHAKE128: Best performance, 128-bit security, good for high-throughput applications

For new applications where NIST compliance is not required, TurboSHAKE is recommended due to its better performance with equivalent security margins.

## Algorithm details

All four XOFs are based on the Keccak-p permutation:

| Function      | Security | Block size | Rounds |
| ------------- | -------- | ---------- | ------ |
| SHAKE128      | 128-bit  | 168 bytes  | 24     |
| SHAKE256      | 256-bit  | 136 bytes  | 24     |
| TurboSHAKE128 | 128-bit  | 168 bytes  | 12     |
| TurboSHAKE256 | 256-bit  | 136 bytes  | 12     |

The security level indicates resistance to generic attacks:

  - 128-bit security: collision resistance up to 2^64 work, preimage resistance up to 2^128 work
  - 256-bit security: collision resistance up to 2^128 work, preimage resistance up to 2^256 work

## Notes

XOFs differ from hash functions in an important way: for the same input, requesting different output lengths produces related outputs. Specifically, shorter outputs are prefixes of longer outputs. If this property is undesirable for your application, include the intended output length in the input.

The state should not be used after the object has been squeezed unless it is reinitialized using the `init` function.

These functions are deterministic: the same input always produces the same output. They are not suitable for password hashing. For that purpose, use the [password hashing](../password_hashing/README.md) API.

These functions were introduced in libsodium 1.0.21.
