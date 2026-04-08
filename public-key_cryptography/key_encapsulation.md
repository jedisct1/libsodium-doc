# Key encapsulation

## Example

``` c
unsigned char pk[crypto_kem_PUBLICKEYBYTES];
unsigned char sk[crypto_kem_SECRETKEYBYTES];
unsigned char ciphertext[crypto_kem_CIPHERTEXTBYTES];
unsigned char client_key[crypto_kem_SHAREDSECRETBYTES];
unsigned char server_key[crypto_kem_SHAREDSECRETBYTES];

crypto_kem_keypair(pk, sk);

if (crypto_kem_enc(ciphertext, client_key, pk) != 0) {
    /* error */
}
if (crypto_kem_dec(server_key, ciphertext, sk) != 0) {
    /* error */
}
```

## Purpose

A key encapsulation mechanism creates a shared secret for a recipient using that recipient’s public key.

The sender obtains the shared secret directly during encapsulation. The recipient obtains the same shared secret by decapsulating the ciphertext with the secret key.

This is useful for bootstrapping session keys or building hybrid encryption schemes.

For most applications, the high-level `crypto_kem_*()` API should be preferred. In libsodium, it uses X-Wing, a hybrid post-quantum KEM combining ML-KEM768 and X25519.

## Usage

``` c
int crypto_kem_keypair(unsigned char *pk, unsigned char *sk);
```

The `crypto_kem_keypair()` function creates a new key pair. It puts the public key into `pk` and the secret key into `sk`.

``` c
int crypto_kem_seed_keypair(unsigned char *pk, unsigned char *sk,
                            const unsigned char *seed);
```

The `crypto_kem_seed_keypair()` function computes a deterministic key pair from `seed` (`crypto_kem_SEEDBYTES` bytes).

``` c
int crypto_kem_enc(unsigned char *ct, unsigned char *ss,
                   const unsigned char *pk);
```

The `crypto_kem_enc()` function creates a ciphertext `ct` for the recipient public key `pk` and stores the shared secret into `ss`.

It returns `0` on success and `-1` on failure.

``` c
int crypto_kem_dec(unsigned char *ss, const unsigned char *ct,
                   const unsigned char *sk);
```

The `crypto_kem_dec()` function verifies and decapsulates the ciphertext `ct` using the recipient secret key `sk`, and stores the shared secret into `ss`.

It returns `0` on success and `-1` on failure.

## Using the shared secret

The shared secret is `crypto_kem_SHAREDSECRETBYTES` bytes long.

In many protocols, the shared secret is immediately fed to a KDF in order to derive multiple context-specific keys. [HKDF](../key_derivation/hkdf.md) is a good fit for this.

## Algorithm details

The high-level `crypto_kem_*()` API uses X-Wing and reports `"xwing"` via `crypto_kem_PRIMITIVE`.

X-Wing combines ML-KEM768 with X25519 in order to provide protection against both classical and quantum adversaries.

For libsodium applications, it should be the default choice.

## Constants

  - `crypto_kem_PUBLICKEYBYTES`
  - `crypto_kem_SECRETKEYBYTES`
  - `crypto_kem_CIPHERTEXTBYTES`
  - `crypto_kem_SHAREDSECRETBYTES`
  - `crypto_kem_SEEDBYTES`
  - `crypto_kem_PRIMITIVE`

## Notes

Unlike traditional Diffie-Hellman style key exchange, encapsulation is asymmetric: only the recipient needs a long-term key pair, and the sender does not need to publish a public key in order to create a shared secret.

If the application needs sender authentication in addition to confidentiality, combine key encapsulation with a signature scheme or an authenticated key exchange.

This API was introduced in libsodium 1.0.22.
