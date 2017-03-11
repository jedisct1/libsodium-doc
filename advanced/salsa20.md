# Salsa20

Salsa20 is a stream cipher developed by Daniel J. Bernstein that expands a 256-bit key into 2^64 randomly accessible streams, each containing 2^64 randomly accessible 64-byte (512 bits) blocks.

Salsa20 doesn't require any lookup tables and avoids the possibility of timing attacks.

Internally, Salsa20 works like a block cipher used in counter mode. It uses a dedicated 64-bit block counter to avoid incrementing the nonce after each block.

## Usage

```c
int crypto_stream_salsa20(unsigned char *c, unsigned long long clen,
                          const unsigned char *n, const unsigned char *k);
```

The `crypto_stream_salsa20()` function stores `clen` pseudo random bytes into `c` using a nonce `n` (`crypto_stream_salsa20_NONCEBYTES` bytes) and a secret key `k` (`crypto_stream_salsa20_KEYBYTES` bytes).

```c
int crypto_stream_salsa20_xor(unsigned char *c, const unsigned char *m,
                              unsigned long long mlen, const unsigned char *n,
                              const unsigned char *k);
```

The `crypto_stream_salsa20_xor()` function encrypts a message `m` of length `mlen` using a nonce `n` (`crypto_stream_salsa20_NONCEBYTES` bytes) and a secret key `k` (`crypto_stream_salsa20_KEYBYTES` bytes).

The ciphertext is put into `c`. The ciphertext is the message combined with the output of the stream cipher using the XOR operation, and doesn't include any authentication tag.

`m` and `c` can point to the same address (in-place encryption/decryption). If they don't, the regions should not overlap.

```c
int crypto_stream_salsa20_xor_ic(unsigned char *c, const unsigned char *m,
                                 unsigned long long mlen,
                                 const unsigned char *n, uint64_t ic,
                                 const unsigned char *k);
```

The `crypto_stream_salsa20_xor_ic()` function is similar to `crypto_stream_salsa20_xor()` but adds the ability to set the initial value of the block counter to a non-zero value, `ic`.

This permits direct access to any block without having to compute the previous ones.

`m` and `c` can point to the same address (in-place encryption/decryption). If they don't, the regions should not overlap.

```c
void crypto_stream_salsa20_keygen(unsigned char k[crypto_stream_salsa20_KEYBYTES]);
```

This helper function introduced in libsodium 1.0.12 creates a random key `k`.

It is equivalent to calling `randombytes_buf()` but improves code clarity and can prevent misuse by ensuring that the provided key length is always be correct.

## Constants

- `crypto_stream_salsa20_KEYBYTES`
- `crypto_stream_salsa20_NONCEBYTES`

## Notes

The nonce is 64 bits long. In order to prevent nonce reuse, if a key is being reused, it is recommended to increment the previous nonce instead of generating a random nonce every time a new stream is required.

Alternatively, XSalsa20, a variant of Salsa20 with a longer nonce, can be used.

The functions described above perform 20 rounds of Salsa20.

Faster, reduced-rounds versions are also available:

* Salsa20 reduced to 12 rounds:

```c
int crypto_stream_salsa2012(unsigned char *c, unsigned long long clen,
                            const unsigned char *n, const unsigned char *k);

int crypto_stream_salsa2012_xor(unsigned char *c, const unsigned char *m,
                                unsigned long long mlen, const unsigned char *n,
                                const unsigned char *k);

void crypto_stream_salsa2012_keygen(unsigned char k[crypto_stream_salsa2012_KEYBYTES]);
```

* Salsa20 reduced to 8 rounds:

```c
int crypto_stream_salsa208(unsigned char *c, unsigned long long clen,
                           const unsigned char *n, const unsigned char *k);

int crypto_stream_salsa208_xor(unsigned char *c, const unsigned char *m,
                               unsigned long long mlen, const unsigned char *n,
                               const unsigned char *k);

void crypto_stream_salsa208_keygen(unsigned char k[crypto_stream_salsa208_KEYBYTES]);
```

Although the best known attack against Salsa20-8 is not practical, the full-round version provides a highest security margin while still being fast enough for most purposes.
