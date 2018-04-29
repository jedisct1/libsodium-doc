# Elliptic curve point aritmhetic

A set of low-level APIs to perform computations over the edwards25519 curve, only useful to implement custom constructions.

Points are represented as their Y coordinate.

## Example

For a complete example using these functions, see the [SPAKE2+EE implementation](https://github.com/jedisct1/spake2-ee) for libsodium.

## Point validation

```c
int crypto_core_ed25519_is_valid_point(const unsigned char *p);
```

The `crypto_core_ed25519_is_valid_point()` function checks that `p` represents a point on the edwards25519 curve, in canonical form, on the main subgroup, and that the point doesn't have a small order.

It returns `1` on success, and `0` if the checks didn't pass.

## Hash-to-point (Elligator)

```c
int crypto_core_ed25519_from_uniform(unsigned char *p, const unsigned char *r);
```

The `crypto_core_ed25519_from_uniform()` function maps a 32 bytes vector `r` (usually the output of a hash function) to a point, and stores its compressed representation into `p`.

The point is guaranteed to be on the main subgroup.

## Scalar multiplication

```c
int crypto_scalarmult_ed25519(unsigned char *q, const unsigned char *n,
                              const unsigned char *p);
```

The `crypto_scalarmult_ed25519()` function multiplies a point `p` by a scalar `n` and puts the Y coordinate of the resulting point into `q`.

`q` should not be used as a shared key prior to hashing.

The function returns `0` on success, or `-1` if `n` is `0` or if `p` is not on the curve, not on the main subgroup, is a point of small order, or is not provided in canonical form.

Note that `n` is "clamped" (the 3 low bits are cleared to make it a multiple of the cofactor, bit 254 is set and bit 255 is cleared to respect the original design).

```c
int crypto_scalarmult_ed25519_base(unsigned char *q, const unsigned char *n);
```

The `crypto_scalarmult_ed25519_base(()` function multiplies the base point `(x, 4/5)` by a scalar `n` (clamped) and puts the Y coordinate of the resulting point into `q`.

The function returns `-1` if `n` is `0`, and `0` otherwise.

## Point addition/substraction

```c
int crypto_core_ed25519_add(unsigned char *r,
                            const unsigned char *p, const unsigned char *q);
```

The `crypto_core_ed25519_add()` function adds the point `p` to the point `q` and stores the resulting point into `r`.

The function returns `0` on success, or `-1` if `p` and/or `q` are not valid points.

```c
int crypto_core_ed25519_sub(unsigned char *r,
                            const unsigned char *p, const unsigned char *q);
```

The `crypto_core_ed25519_sub()` function substracts the point `p` to the point `q` and stores the resulting point into `r`.

The function returns `0` on success, or `-1` if `p` and/or `q` are not valid points.

## Constants

* `crypto_scalarmult_ed25519_BYTES`
* `crypto_scalarmult_ed25519_SCALARBYTES`
* `crypto_core_ed25519_BYTES`
* `crypto_core_ed25519_UNIFORMBYTES`

## Note

These functions were introduced in libsodium 1.0.16.
