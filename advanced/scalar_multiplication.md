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
Given a user's secret key `n` and another user's public key `p`, the `crypto_scalarmult()` function computes a secret shared by the two users and puts it into `q`. This secret can then be used to authenticate and encrypt messages between the two users.

`n` and `p` are `crypto_scalarmult_SCALARBYTES` bytes long, and the output size is `crypto_scalarmult_BYTES` bytes.

## Constants

- `crypto_scalarmult_BYTES`
- `crypto_scalarmult_SCALARBYTES`

## Algorithm details

- Curve25519
