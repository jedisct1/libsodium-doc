# Diffie-Hellman function

Sodium provides Curve25519, a state-of-the-art Diffie-Hellman function suitable for a wide variety of applications.

## Usage

```c
int crypto_scalarmult_base(unsigned char *q, const unsigned char *n);
```

Given a user's secret key `n` (`crypto_scalarmult_SCALARBYTES` bytes), the `crypto_scalarmult_base()` function computes the user's public key and puts it into `q` (`crypto_scalarmult_BYTES` bytes).

`crypto_scalarmult_BYTES` and `crypto_scalarmult_SCALARBYTES` are provided for consistency, but it is safe to assume that `crypto_scalarmult_BYTES == crypto_scalarmult_SCALARBYTES`.

```c
int crypto_scalarmult(unsigned char *q, const unsigned char *n,
                      const unsigned char *p);
```
This function can be used to compute a shared secret given a user's secret key and another user's public key.

`n` and `p` are `crypto_scalarmult_SCALARBYTES` bytes long, and the output size is `crypto_scalarmult_BYTES` bytes.

Instead of directly using the output of the multiplication `q` as a shared secret, it is recommended to use `h(q || pk1 || pk2)`, with `pk1` and `pk2` being the public keys.

```c
    unsigned char alice_publickey[crypto_box_PUBLICKEYBYTES];
    unsigned char alice_secretkey[crypto_box_SECRETKEYBYTES];
    unsigned char bob_publickey[crypto_box_PUBLICKEYBYTES];
    unsigned char bob_secretkey[crypto_box_SECRETKEYBYTES];
    unsigned char scalarmult_res_by_alice[crypto_scalarmult_BYTES];
    unsigned char scalarmult_res_by_bob[crypto_scalarmult_BYTES];
    unsigned char sharedkey_by_alice[crypto_generichash_BYTES];
    unsigned char sharedkey_by_bob[crypto_generichash_BYTES];
    crypto_generichash_state h;

    /* Create Alice's secret and public keys */
    randombytes(alice_secretkey, sizeof alice_secretkey);
    crypto_scalarmult_base(alice_publickey, alice_secretkey);

    /* Create Bob's secret and public keys */
    randombytes(bob_secretkey, sizeof bob_secretkey);
    crypto_scalarmult_base(bob_publickey, bob_secretkey);

    /* Alice derives a shared key from her secret key and Bob's public key */
    crypto_scalarmult(scalarmult_res_by_alice, alice_secretkey, bob_publickey);
    crypto_generichash_init(&h, NULL, 0U, crypto_generichash_BYTES);
    crypto_generichash_update(&h, scalarmult_res_by_alice, sizeof scalarmult_res_by_alice);
    crypto_generichash_update(&h, alice_publickey, sizeof alice_publickey);
    crypto_generichash_update(&h, bob_publickey, sizeof bob_publickey);
    crypto_generichash_final(&h, sharedkey_by_alice, sizeof sharedkey_by_alice);

    /* Alice derives a shared key from her secret key and Bob's public key */
    crypto_scalarmult(scalarmult_res_by_bob, bob_secretkey, alice_publickey);
    crypto_generichash_init(&h, NULL, 0U, crypto_generichash_BYTES);
    crypto_generichash_update(&h, scalarmult_res_by_bob, sizeof scalarmult_res_by_bob);
    crypto_generichash_update(&h, alice_publickey, sizeof alice_publickey);
    crypto_generichash_update(&h, bob_publickey, sizeof bob_publickey);
    crypto_generichash_final(&h, sharedkey_by_bob, sizeof sharedkey_by_bob);

    /* sharedkey_by_alice and sharedkey_by_bob are identical */
```

## Constants

- `crypto_scalarmult_BYTES`
- `crypto_scalarmult_SCALARBYTES`

## Algorithm details

- Curve25519
