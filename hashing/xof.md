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

unsigned char out[32];

crypto_xof_turboshake128(out, sizeof out, MESSAGE, MESSAGE_LEN);
```

## Multi-part example

``` c
#define MESSAGE_PART1 \
    ((const unsigned char *) "Arbitrary data to hash")
#define MESSAGE_PART1_LEN 22

#define MESSAGE_PART2 \
    ((const unsigned char *) "is longer than expected")
#define MESSAGE_PART2_LEN 23

unsigned char out[32];
crypto_xof_turboshake128_state state;

crypto_xof_turboshake128_init(&state);

crypto_xof_turboshake128_update(&state, MESSAGE_PART1, MESSAGE_PART1_LEN);
crypto_xof_turboshake128_update(&state, MESSAGE_PART2, MESSAGE_PART2_LEN);

crypto_xof_turboshake128_squeeze(&state, out, sizeof out);
```

## Incremental output

Unlike regular hash functions, XOFs can be squeezed multiple times to produce additional output. The concatenation of all squeezed outputs is identical to squeezing the total length at once.

``` c
unsigned char seed[32];
randombytes_buf(seed, sizeof seed);

crypto_xof_turboshake128_state state;
crypto_xof_turboshake128_init(&state);
crypto_xof_turboshake128_update(&state, seed, sizeof seed);

unsigned char key1[32], key2[32], key3[32];
crypto_xof_turboshake128_squeeze(&state, key1, sizeof key1);
crypto_xof_turboshake128_squeeze(&state, key2, sizeof key2);
crypto_xof_turboshake128_squeeze(&state, key3, sizeof key3);
```

## Purpose

XOFs can be used as:

  - Hash functions: producing fixed-length digests
  - Key derivation functions: deriving multiple keys from a seed
  - Deterministic random generators: expanding a seed into arbitrary-length output
  - Domain-separated hashing: using custom domain separators

## Real-world use cases

### Deriving multiple keys from a master secret

XOFs naturally support deriving multiple independent keys by squeezing repeatedly:

``` c
unsigned char master_key[32];
/* ... master_key is established via key exchange or similar ... */

crypto_xof_turboshake128_state state;
crypto_xof_turboshake128_init(&state);
crypto_xof_turboshake128_update(&state, master_key, sizeof master_key);

/* Derive independent keys for different purposes */
unsigned char encryption_key[32];
unsigned char mac_key[32];
unsigned char iv[16];

crypto_xof_turboshake128_squeeze(&state, encryption_key, sizeof encryption_key);
crypto_xof_turboshake128_squeeze(&state, mac_key, sizeof mac_key);
crypto_xof_turboshake128_squeeze(&state, iv, sizeof iv);
```

### Generating deterministic test vectors

Expand a short seed into reproducible test data:

``` c
unsigned char seed[16] = "test_vector_seed";
unsigned char test_data[10000];

crypto_xof_turboshake128(test_data, sizeof test_data, seed, sizeof seed);
```

### Hashing with context/domain separation

Use domain separators to create independent hash functions from the same primitive:

``` c
#define DOMAIN_FILE_ID    0x01
#define DOMAIN_SESSION_ID 0x02

/* Hash a file with domain separation */
unsigned char file_hash[32];
crypto_xof_turboshake128_state state;
crypto_xof_turboshake128_init_with_domain(&state, DOMAIN_FILE_ID);
crypto_xof_turboshake128_update(&state, file_contents, file_len);
crypto_xof_turboshake128_squeeze(&state, file_hash, sizeof file_hash);

/* Hash session data - independent from file hashing even with same input */
unsigned char session_id[16];
crypto_xof_turboshake128_init_with_domain(&state, DOMAIN_SESSION_ID);
crypto_xof_turboshake128_update(&state, session_data, session_len);
crypto_xof_turboshake128_squeeze(&state, session_id, sizeof session_id);
```

### Hash-to-curve or hash-to-field

XOFs simplify protocols that need to hash into mathematical structures by providing arbitrary-length output without awkward padding or multiple hash calls:

``` c
/* Generate enough random bytes to reduce bias when mapping to a field */
unsigned char uniform_bytes[64];
crypto_xof_turboshake128(uniform_bytes, sizeof uniform_bytes,
                          input, input_len);
/* ... use uniform_bytes to derive a field element ... */
```

### Replacing HKDF-Expand

When you have a uniformly random key and need to derive multiple outputs, a XOF is simpler than HKDF:

``` c
/* Instead of multiple HKDF-Expand calls with different info strings,
   just squeeze the outputs you need */
unsigned char prk[32]; /* pseudorandom key from key exchange */

crypto_xof_turboshake128_state state;
crypto_xof_turboshake128_init(&state);
crypto_xof_turboshake128_update(&state, prk, sizeof prk);
crypto_xof_turboshake128_update(&state, context, context_len);

unsigned char derived[96]; /* 3 x 32-byte keys */
crypto_xof_turboshake128_squeeze(&state, derived, sizeof derived);
```

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

Calling `crypto_xof_shake256_init()` is equivalent to calling `crypto_xof_shake256_init_with_domain()` with `crypto_xof_shake256_DOMAIN_STANDARD`.

### Constants

  - `crypto_xof_shake256_BLOCKBYTES` (136)
  - `crypto_xof_shake256_STATEBYTES` (256)
  - `crypto_xof_shake256_DOMAIN_STANDARD` (0x1F): the domain separator used by `crypto_xof_shake256_init()`
  - `crypto_xof_shake128_BLOCKBYTES` (168)
  - `crypto_xof_shake128_STATEBYTES` (256)
  - `crypto_xof_shake128_DOMAIN_STANDARD` (0x1F): the domain separator used by `crypto_xof_shake128_init()`

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

Calling `crypto_xof_turboshake256_init()` is equivalent to calling `crypto_xof_turboshake256_init_with_domain()` with `crypto_xof_turboshake256_DOMAIN_STANDARD`.

### Constants

  - `crypto_xof_turboshake256_BLOCKBYTES` (136)
  - `crypto_xof_turboshake256_STATEBYTES` (256)
  - `crypto_xof_turboshake256_DOMAIN_STANDARD` (0x1F): the domain separator used by `crypto_xof_turboshake256_init()`
  - `crypto_xof_turboshake128_BLOCKBYTES` (168)
  - `crypto_xof_turboshake128_STATEBYTES` (256)
  - `crypto_xof_turboshake128_DOMAIN_STANDARD` (0x1F): the domain separator used by `crypto_xof_turboshake128_init()`

### Data types

  - `crypto_xof_turboshake256_state`
  - `crypto_xof_turboshake128_state`

## Which variant to use

TurboSHAKE128 is the recommended choice for most applications. It offers:

  - Great performance (\~2x faster than SHAKE)
  - 128-bit security, which is more than sufficient for virtually all use cases
  - Built-in domain separation support
  - Standardized in RFC 9861

Use a different variant only if you have specific requirements:

  - SHAKE256 or TurboSHAKE256: When you need 256-bit collision resistance
  - SHAKE128/SHAKE256: When NIST FIPS 202 compliance is mandated

The “128” and “256” in the names refer to security levels, not output sizes. All variants can produce output of any length.

Security considerations:

When using a XOF as a hash function (collision resistance matters), the output should be at least twice the security level. TurboSHAKE128 with a 32-byte output provides full 128-bit collision resistance. Shorter outputs reduce collision resistance proportionally: a 16-byte output only provides 64-bit collision resistance.

When using a XOF for key derivation or as a PRF (preimage resistance matters), the output length doesn’t affect security as long as you’re using it correctly. TurboSHAKE128 provides 128-bit preimage resistance regardless of output length.

``` c
/* TurboSHAKE128 producing a 256-bit hash - full 128-bit security */
unsigned char hash[32];
crypto_xof_turboshake128(hash, 32, message, message_len);

/* TurboSHAKE128 deriving a 256-bit key - full 128-bit security */
unsigned char key[32];
crypto_xof_turboshake128(key, 32, seed, seed_len);

/* TurboSHAKE128 generating 1KB of deterministic randomness */
unsigned char random_data[1024];
crypto_xof_turboshake128(random_data, 1024, seed, seed_len);
```

## Algorithm details

All four XOFs are based on the Keccak-p (SHA-3) permutation:

| Function | Security | Block size | Rounds |
| --- | --- | --- | --- |
| SHAKE128 | 128-bit | 168 bytes | 24 |
| SHAKE256 | 256-bit | 136 bytes | 24 |
| TurboSHAKE128 | 128-bit | 168 bytes | 12 |
| TurboSHAKE256 | 256-bit | 136 bytes | 12 |

The security level indicates resistance to generic attacks:

  - 128-bit security: collision resistance up to 2^64 work, preimage resistance up to 2^128 work
  - 256-bit security: collision resistance up to 2^128 work, preimage resistance up to 2^256 work

## Notes

XOFs differ from hash functions in an important way: for the same input, requesting different output lengths produces related outputs. Specifically, shorter outputs are prefixes of longer outputs. If this property is undesirable for your application, include the intended output length in the input.

The state should not be used after the object has been squeezed unless it is reinitialized using the `init` function.

These functions are deterministic: the same input always produces the same output. They are not suitable for password hashing. For that purpose, use the [password hashing](../password_hashing/README.md) API.

These functions were introduced in libsodium 1.0.21.
