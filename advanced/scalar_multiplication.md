# Diffie-Hellman function

Sodium provides Curve25519, a state-of-the-art Diffie-Hellman function suitable for a wide variety of applications.

## Usage

```c
int crypto_scalarmult_base(unsigned char *q, const unsigned char *n);
```

Given a user's secret key `n` (`crypto_scalarmult_SCALARBYTES` bytes), the `crypto_scalarmult_base()` function computes the user's public key and puts it into `q` (`crypto_scalarmult_BYTES` bytes).

`crypto_scalarmult_BYTES` and `crypto_scalarmult_SCALARBYTES` are provided for consistency, but it is safe to assume that `crypto_scalarmult_BYTES == crypto_scalarmult_SCALARBYTES`.

```c
int crypto_scalarmult(unsigned char *q, const unsigned char *sk1,
                      const unsigned char *pk2);
```
This function can be used to compute a shared secret given a user's secret key `sk1` and another user's public key `pk2`.

`sk1` and `pk2` are `crypto_scalarmult_SCALARBYTES` bytes long, and the output size is `crypto_scalarmult_BYTES` bytes.

Instead of directly using the output of the multiplication `q` as a shared secret, it is recommended to use `h(q || pk1 || pk2)`, with `pk1'` being the public key derived from `sk1`.

## Constants

- `crypto_scalarmult_BYTES`
- `crypto_scalarmult_SCALARBYTES`

## Algorithm details

- Curve25519
