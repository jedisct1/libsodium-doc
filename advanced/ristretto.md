# Ristretto

[Ristretto](https://ristretto.group) is a new unified point compression format for curves over large-characteristic fields, which divides the curve’s cofactor by 4 or 8 at very little cost of performance, efficiently implementing a prime-order group.

libsodium 1.0.18+ implements Ristretto on top of the Curve25519 curve.

Compared to Curve25519 points encoded as their coordinates, Ristretto makes it easier to safely implement protocols originally designed for prime-order groups.

## Example

Perform a secure two-party computation of `f(x) = p(x)^k`. `x` is the input sent to the second party by the first party after blinding it using a random invertible scalar `r`, and `k` is a secret key only known by the second party. `p(x)` is a hash-to-group function.

```c
// -------- First party -------- Send blinded p(x)
unsigned char x[crypto_core_ristretto255_HASHBYTES];
randombytes_buf(x, sizeof x);

// Compute px = p(x), an EC point representative for x
unsigned char px[crypto_core_ristretto255_BYTES];
crypto_core_ristretto255_from_hash(px, x);

// Compute a = p(x) * g^r
unsigned char r[crypto_core_ristretto255_SCALARBYTES];
unsigned char gr[crypto_core_ristretto255_BYTES];
unsigned char a[crypto_core_ristretto255_BYTES];
crypto_core_ristretto255_scalar_random(r);
crypto_scalarmult_ristretto255_base(gr, r);
crypto_core_ristretto255_add(a, px, gr);

// -------- Second party -------- Send g^k and a^k
unsigned char k[crypto_core_ristretto255_SCALARBYTES];
randombytes_buf(k, sizeof k);

// Compute v = g^k
unsigned char v[crypto_core_ristretto255_BYTES];
crypto_scalarmult_ristretto255_base(v, k);

// Compute b = a^k
unsigned char b[crypto_core_ristretto255_BYTES];
if (crypto_scalarmult_ristretto255(b, k, a) != 0) {
    return -1;
}

// -------- First party -------- Unblind f(x)
// Compute vir = v^(-r)
unsigned char ir[crypto_core_ristretto255_SCALARBYTES];
unsigned char vir[crypto_core_ristretto255_BYTES];
crypto_core_ristretto255_scalar_negate(ir, r);
crypto_scalarmult_ristretto255(vir, ir, v);

// Compute f(x) = b * v^(-r) = (p(x) * g^r)^k * (g^k)^(-r)
//              = (p(x) * g)^k * g^(-k) = p(x)^k
unsigned char fx[crypto_core_ristretto255_BYTES];
crypto_core_ristretto255_add(fx, b, vir);
```

## Encoding validation

```c
int crypto_core_ristretto255_is_valid_point(const unsigned char *p);
```

The `crypto_core_ristretto255_is_valid_point()` function checks that `p` is a valid ristretto255 representative.

This operation only checks that `p` is in canonical form.

Unlike the ed25519 encoding scheme, there is no need to verify that the point is on the prime-order group.

The function returns `1` on success, and `0` if the checks didn't pass.

## Random group element

```c
void crypto_core_ristretto255_random(unsigned char *p);
```

Fills `p` with the representation of a random group element.

## Hash-to-group

```c
int crypto_core_ristretto255_from_hash(unsigned char *p, const unsigned char *r);
```

The `crypto_core_ristretto255_from_hash()` function maps a 64 bytes vector `r` (usually the output of a hash function) to a point, and stores its compressed representation into `p`.

## Scalar multiplication

```c
int crypto_scalarmult_ristretto255(unsigned char *q, const unsigned char *n,
                                   const unsigned char *p);
```

The `crypto_scalarmult_ristretto255()` function multiplies a point represented by `p` by a scalar `n` (in the `[0..L[` range) and puts the resulting compressed point into `q`.

`q` should not be used as a shared key prior to hashing.

The function returns `0` on success, or `-1` if `p` is the point at infinity.

```c
int crypto_scalarmult_ristretto255_base(unsigned char *q, const unsigned char *n);
```

The `crypto_scalarmult_ristretto255_base()` function multiplies the base point by a scalar `n` (`[0..L[` range) and puts the resulting compressed point into `q`.

The function returns `-1` if `n` is `0`, and `0` otherwise.

## Point addition/substraction

```c
int crypto_core_ristretto255_add(unsigned char *r,
                                 const unsigned char *p, const unsigned char *q);
```

The `crypto_core_ristretto255_add()` function adds the point represented by `p` to the point `q` and stores the resulting point into `r`.

The function returns `0` on success, or `-1` if `p` and/or `q` are not valid compressed points.

```c
int crypto_core_ristretto255_sub(unsigned char *r,
                                 const unsigned char *p, const unsigned char *q);
```

The `crypto_core_ristretto255_sub()` function substracts the point represented by `p` to the point `q` and stores the resulting point into `r`.

The function returns `0` on success, or `-1` if `p` and/or `q` are not valid compressed points.

## Scalar arithmetic over L

Scalars should ideally be randomly chosen in the `[0..L[` interval, `L` being the order of the group (2^252 + 27742317777372353535851937790883648493).

This can be achieved with the following function:

```c
void crypto_core_ristretto255_scalar_random(unsigned char *r);
```

`crypto_core_ristretto255_scalar_random()` fills `r` with a `crypto_core_ristretto255_SCALARBYTES` bytes representation of the scalar in the `]0..L[` interval.

A scalar in the `[0..L[` interval can also be obtained by reducing a possibly larger value:

```c
void crypto_core_ristretto255_scalar_reduce(unsigned char *r, const unsigned char *s);
```

The `crypto_core_ristretto255_scalar_reduce()` function reduces `s` to `s mod L` and puts the `crypto_core_ristretto255_SCALARBYTES` integer into `r`.

Note that `s` is much larger than `r` (64 bytes vs 32 bytes). Bits of `s` can be left to `0`, but the interval `s` is sampled from should be at least 317 bits to ensure almost uniformity of `r` over `L`.

```c
int crypto_core_ristretto255_scalar_invert(unsigned char *recip, const unsigned char *s);
```

The `crypto_core_ristretto255_scalar_invert()` function computes the multiplicative inverse of `s` over `L`, and puts it into `recip`.

```c
void crypto_core_ristretto255_scalar_negate(unsigned char *neg, const unsigned char *s);
```

The `crypto_core_ristretto255_scalar_negate()` function returns `neg` so that `s + neg = 0 (mod L)`.

```c
void crypto_core_ristretto255_scalar_complement(unsigned char *comp, const unsigned char *s);
```

The `crypto_core_ristretto255_scalar_complement()` function returns `comp` so that `s + comp = 1 (mod L)`.

```c
void crypto_core_ristretto255_scalar_add(unsigned char *z,
                                         const unsigned char *x, const unsigned char *y);
```

The `crypto_core_ristretto255_scalar_add()` function stores `x + y (mod L)` into `z`.

```c
void crypto_core_ristretto255_scalar_sub(unsigned char *z,
                                         const unsigned char *x, const unsigned char *y);
```

The `crypto_core_ristretto255_scalar_sub()` function stores `x - y (mod L)` into `z`.

```c
void crypto_core_ristretto255_scalar_mul(unsigned char *z,
                                         const unsigned char *x, const unsigned char *y);
```

The `crypto_core_ristretto255_scalar_mul()` function stores `x * y (mod L)` into `z`.

## Constants

* `crypto_scalarmult_ristretto255_BYTES`
* `crypto_scalarmult_ristretto255_SCALARBYTES`
* `crypto_core_ristretto255_BYTES`
* `crypto_core_ristretto255_HASHBYTES`
* `crypto_core_ristretto255_SCALARBYTES`
* `crypto_core_ristretto255_NONREDUCEDSCALARBYTES`

## Algorithms

* `ristretto255`

## Reference

* [Ristretto](https://ristretto.group)
* [Decaf: Eliminating cofactors through point compression](https://eprint.iacr.org/2015/673.pdf)

## Note

These functions were introduced in libsodium 1.0.18.
