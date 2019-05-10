# Finite field arithmetic

A set of low-level APIs to perform computations over the edwards25519 curve, only useful to implement custom constructions.

Points are represented as their Y coordinate.

## Example

Perform a secure two-party computation of `f(x) = p(x)^k`. `x` is the input sent to the second party by the first party after blinding it using a random invertible scalar `r`, and `k` is a secret key only known by the second party. `p(x)` is a hash-to-curve function.

```c
// -------- First party -------- Send blinded p(x)
unsigned char x[crypto_core_ed25519_UNIFORMBYTES];
randombytes_buf(x, sizeof x);

// Compute px = p(x), an EC point representative for x
unsigned char px[crypto_core_ed25519_BYTES];
crypto_core_ed25519_from_uniform(px, x);

// Compute a = p(x) * g^r
unsigned char r[crypto_core_ed25519_SCALARBYTES];
unsigned char gr[crypto_core_ed25519_BYTES];
unsigned char a[crypto_core_ed25519_BYTES];
crypto_core_ed25519_scalar_random(r);
crypto_scalarmult_ed25519_base_noclamp(gr, r);
crypto_core_ed25519_add(a, px, gr);

// -------- Second party -------- Send g^k and a^k
unsigned char k[crypto_core_ed25519_SCALARBYTES];
randombytes_buf(k, sizeof k);

// Compute v = g^k
unsigned char v[crypto_core_ed25519_BYTES];
crypto_scalarmult_ed25519_base(v, k);

// Compute b = a^k
unsigned char b[crypto_core_ed25519_BYTES];
if (crypto_scalarmult_ed25519(b, k, a) != 0) {
    return -1;
}

// -------- First party -------- Unblind f(x)
// Compute vir = v^(-r)
unsigned char ir[crypto_core_ed25519_SCALARBYTES];
unsigned char vir[crypto_core_ed25519_BYTES];
crypto_core_ed25519_scalar_negate(ir, r);
crypto_scalarmult_ed25519_noclamp(vir, ir, v);

// Compute f(x) = b * v^(-r) = (p(x) * g^r)^k * (g^k)^(-r)
//              = (p(x) * g)^k * g^(-k) = p(x)^k
unsigned char fx[crypto_core_ed25519_BYTES];
crypto_core_ed25519_add(fx, b, vir);
```

## Point validation

```c
int crypto_core_ed25519_is_valid_point(const unsigned char *p);
```

The `crypto_core_ed25519_is_valid_point()` function checks that `p` represents a point on the edwards25519 curve, in canonical form, on the main subgroup, and that the point doesn't have a small order.

It returns `1` on success, and `0` if the checks didn't pass.

## Random group element

```c
void crypto_core_ed25519_random(unsigned char *p);
```

Fills `p` with the representation of a random group element.

## Elligator2 map

```c
int crypto_core_ed25519_from_uniform(unsigned char *p, const unsigned char *r);
```

The `crypto_core_ed25519_from_uniform()` function maps a 32 bytes vector `r` to a point, and stores its compressed representation into `p`.

The point is guaranteed to be on the main subgroup.

This function directly exposes the inverse Elligator2 map, and uses the high bit to set the sign of the X coordinate.

## Hash-to-group

```c
int crypto_core_ed25519_from_hash(unsigned char *p, const unsigned char *r);
```

The `crypto_core_ed25519_from_hash()` function maps a 64 bytes vector `r` to a point, and stores its representation into `p`.

The vector `r` represents a value, usually the output of a hash function, encoded in big-endian order. The high bit (which, in big-endian order, is in the first element of the vector) sets the sign of the X coordinate.

The point is guaranteed to be on the main subgroup.

This function is similar to `crypto_core_ed25519_from_uniform()` but uses a larger input size, that some algorithms require.

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

## Scalar multiplication without clamping

In order to prevent attacks using small subgroups, the `scalarmult` functions above clear lower bits of the scalar. This may be indesirable to build protocols that requires `n` to be invertible.

The `noclamp` variants of these functions do not clear these bits, and do not set the high bit either. These variants expect a scalar in the `]0..L[` range.

```c
int crypto_scalarmult_ed25519_noclamp(unsigned char *q, const unsigned char *n,
                                      const unsigned char *p);
```

The function verifies that `p` is on the prime-order subgroup before performing the multiplication, and return `-1` if this is not the case or `n` is `0`.
It returns `0` on success.

```c
int crypto_scalarmult_ed25519_base_noclamp(unsigned char *q, const unsigned char *n);
```

The function returns `0` on success, or `-1` if `n` is `0`.

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

## Scalar arithmetic over L

Scalars should ideally be randomly chosen in the `[0..L[` interval, `L` being the order of the main subgroup (2^252 + 27742317777372353535851937790883648493).

This can be achieved with the following function, introduced in libsodium 1.0.17:

```c
void crypto_core_ed25519_scalar_random(unsigned char *r);
```

`crypto_core_ed25519_scalar_random()` fills `r` with a `crypto_core_ed25519_SCALARBYTES` bytes representation of the scalar in the `]0..L[` interval.

A scalar in the `[0..L[` interval can also be obtained by reducing a possibly larger value:

```c
void crypto_core_ed25519_scalar_reduce(unsigned char *r, const unsigned char *s);
```

The `crypto_core_ed25519_scalar_reduce()` function reduces `s` to `s mod L` and puts the `crypto_core_ed25519_SCALARBYTES` integer into `r`.

Note that `s` is much larger than `r` (64 bytes vs 32 bytes). Bits of `s` can be left to `0`, but the interval `s` is sampled from should be at least 317 bits to ensure almost uniformity of `r` over `L`.

```c
int crypto_core_ed25519_scalar_invert(unsigned char *recip, const unsigned char *s);
```

The `crypto_core_ed25519_scalar_invert()` function computes the multiplicative inverse of `s` over `L`, and puts it into `recip`.

```c
void crypto_core_ed25519_scalar_negate(unsigned char *neg, const unsigned char *s);
```

The `crypto_core_ed25519_scalar_negate()` function returns `neg` so that `s + neg = 0 (mod L)`.

```c
void crypto_core_ed25519_scalar_complement(unsigned char *comp, const unsigned char *s);
```

The `crypto_core_ed25519_scalar_complement()` function returns `comp` so that `s + comp = 1 (mod L)`.

```c
void crypto_core_ed25519_scalar_add(unsigned char *z,
                                    const unsigned char *x, const unsigned char *y);
```

The `crypto_core_ed25519_scalar_add()` function stores `x + y (mod L)` into `z`.

```c
void crypto_core_ed25519_scalar_sub(unsigned char *z,
                                    const unsigned char *x, const unsigned char *y);
```

The `crypto_core_ed25519_scalar_sub()` function stores `x - y (mod L)` into `z`.

```c
void crypto_core_ed25519_scalar_mul(unsigned char *z,
                                    const unsigned char *x, const unsigned char *y);
```

The `crypto_core_ed25519_scalar_mul()` function stores `x * y (mod L)` into `z`.

## Constants

* `crypto_scalarmult_ed25519_BYTES`
* `crypto_scalarmult_ed25519_SCALARBYTES`
* `crypto_core_ed25519_BYTES`
* `crypto_core_ed25519_HASHBYTES`
* `crypto_core_ed25519_UNIFORMBYTES`
* `crypto_core_ed25519_SCALARBYTES`
* `crypto_core_ed25519_NONREDUCEDSCALARBYTES`

## Note

These functions were introduced in libsodium 1.0.16, 1.0.17 and 1.0.18.

For a complete example using these functions, see the [SPAKE2+EE implementation](https://github.com/jedisct1/spake2-ee) for libsodium.

`crypto_core_ed25519_from_uniform()` exposes the Elligator2 inverse map, using the high bit for the sign of the X coordinate.

Since version 1.0.18, `crypto_core_ed25519_from_hash()` implements the `hash2curve` method from the `irtf-cfrg-hash-to-curve` draft, which is similar to the algorithm used by `crypto_core_ed25519_from_uniform()`, but uses a 512-bit hash as an input to further reduce the output bias.

For protocols mandating a hash function that behaves as a random oracle, the `H2C-0005` suite can be trivially implemented as follows:

```c
void h2c_005_ro(unsigned char p[crypto_core_ed25519_BYTES],
                const unsigned char h[64])
{
    struct {
        unsigned char d[3 + 38 + 4];
        unsigned char h[64];
        unsigned char i;
    } in;
    unsigned char h0[crypto_hash_sha512_BYTES],  h1[crypto_hash_sha512_BYTES];
    unsigned char p0[crypto_core_ed25519_BYTES], p1[crypto_core_ed25519_BYTES];

    memcpy(in.d, "h2c" "H2C-Curve25519-SHA512-Elligator2-FFSTV" "\0\0\0\x41", sizeof in.d);
    memcpy(in.h, h, sizeof in.h);
    in.i = 0x02;
    crypto_hash_sha512(h0, (const unsigned char *) &in, sizeof in);
    in.i = 0x03;
    crypto_hash_sha512(h1, (const unsigned char *) &in, sizeof in);
    crypto_core_ed25519_from_hash(p0, h0);
    crypto_core_ed25519_from_hash(p1, h1);
    crypto_core_ed25519_add(p, p0, p1);
}
```
