# ML-KEM768

The `crypto_kem_mlkem768_*()` functions expose the ML-KEM768 key encapsulation primitive.

This is a low-level API. For most applications, use the high-level [`crypto_kem_*()`](../public-key_cryptography/key_encapsulation.md) API instead.

## Example

``` c
unsigned char pk[crypto_kem_mlkem768_PUBLICKEYBYTES];
unsigned char sk[crypto_kem_mlkem768_SECRETKEYBYTES];
unsigned char ciphertext[crypto_kem_mlkem768_CIPHERTEXTBYTES];
unsigned char client_key[crypto_kem_mlkem768_SHAREDSECRETBYTES];
unsigned char server_key[crypto_kem_mlkem768_SHAREDSECRETBYTES];

crypto_kem_mlkem768_keypair(pk, sk);

if (crypto_kem_mlkem768_enc(ciphertext, client_key, pk) != 0) {
    /* error */
}
if (crypto_kem_mlkem768_dec(server_key, ciphertext, sk) != 0) {
    /* error */
}
```

## Purpose

ML-KEM768 is a post-quantum key encapsulation mechanism standardized by NIST.

It can be used to create a shared secret for a recipient using only the public key of that recipient.

For libsodium applications, the high-level `crypto_kem_*()` API is usually a better choice because it uses X-Wing, which combines ML-KEM768 with X25519.

## Usage

``` c
int crypto_kem_mlkem768_keypair(unsigned char *pk, unsigned char *sk);
```

The `crypto_kem_mlkem768_keypair()` function creates a new key pair. It puts the public key into `pk` and the secret key into `sk`.

``` c
int crypto_kem_mlkem768_seed_keypair(unsigned char *pk, unsigned char *sk,
                                     const unsigned char *seed);
```

The `crypto_kem_mlkem768_seed_keypair()` function computes a deterministic key pair from `seed` (`crypto_kem_mlkem768_SEEDBYTES` bytes).

``` c
int crypto_kem_mlkem768_enc(unsigned char *ct, unsigned char *ss,
                            const unsigned char *pk);
```

The `crypto_kem_mlkem768_enc()` function creates a ciphertext `ct` for the recipient public key `pk` and stores the shared secret into `ss`.

It returns `0` on success and `-1` on failure.

``` c
int crypto_kem_mlkem768_enc_deterministic(unsigned char *ct,
                                          unsigned char *ss,
                                          const unsigned char *pk,
                                          const unsigned char *seed);
```

The `crypto_kem_mlkem768_enc_deterministic()` function is similar to `crypto_kem_mlkem768_enc()`, but takes an explicit 32-byte seed instead of using internal randomness.

This is mainly useful for reproducible test vectors.

It returns `0` on success and `-1` on failure.

``` c
int crypto_kem_mlkem768_dec(unsigned char *ss, const unsigned char *ct,
                            const unsigned char *sk);
```

The `crypto_kem_mlkem768_dec()` function verifies and decapsulates the ciphertext `ct` using the recipient secret key `sk`, and stores the shared secret into `ss`.

It returns `0` on success and `-1` on failure.

## Constants

  - `crypto_kem_mlkem768_PUBLICKEYBYTES`
  - `crypto_kem_mlkem768_SECRETKEYBYTES`
  - `crypto_kem_mlkem768_CIPHERTEXTBYTES`
  - `crypto_kem_mlkem768_SHAREDSECRETBYTES`
  - `crypto_kem_mlkem768_SEEDBYTES`

## Notes

Unlike the high-level `crypto_kem_*()` API, this primitive does not combine ML-KEM768 with a classical key exchange algorithm.

If long-term interoperability is not required, prefer the high-level `crypto_kem_*()` API.

These functions were introduced in libsodium 1.0.22.
