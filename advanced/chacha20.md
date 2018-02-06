# ChaCha20

ChaCha20 is a stream cipher developed by Daniel J. Bernstein. Its original
design expands a 256-bit key into 2^64 randomly accessible streams, each
containing 2^64 randomly accessible 64-byte (512 bits) blocks. It is a variant
of Salsa20 with better diffusion.

ChaCha20 doesn't require any lookup tables and avoids the possibility of timing
attacks.

Internally, ChaCha20 works like a block cipher used in counter mode. It includes
an internal block counter to avoid incrementing the nonce after each block.

Two variants of the ChaCha20 cipher are implemented in libsodium:

* The original ChaCha20 cipher with a 64-bit nonce and a 64-bit counter,
  allowing a practically unlimited amount of data to be encrypted with the same
  `(key, nonce)` pair.
* The IETF variant increases the nonce size to 96 bits, but reduces the counter
  size down to 32 bits, allowing only up to 256 GB of data to be safely
  encrypted with a given `(key, nonce)` pair.

These primitives should only be used to implement protocols that specifically
require them. For all other applications, it is recommended to use the
high-level `crypto_stream` API (XSalsa20) or the ChaCha20-based construction
with an extended nonce, XChaCha20 (`crypto_stream_xchacha20`).

## Usage (original construction)

```c
int crypto_stream_chacha20(unsigned char *c, unsigned long long clen,
                           const unsigned char *n, const unsigned char *k);
```

The `crypto_stream_chacha20()` function stores `clen` pseudo random bytes into
`c` using a nonce `n` (`crypto_stream_chacha20_NONCEBYTES` bytes) and a secret
key `k` (`crypto_stream_chacha20_KEYBYTES` bytes).

```c
int crypto_stream_chacha20_xor(unsigned char *c, const unsigned char *m,
                               unsigned long long mlen, const unsigned char *n,
                               const unsigned char *k);
```

The `crypto_stream_chacha20_xor()` function encrypts a message `m` of length
`mlen` using a nonce `n` (`crypto_stream_chacha20_NONCEBYTES` bytes) and a
secret key `k` (`crypto_stream_chacha20_KEYBYTES` bytes).

The ciphertext is put into `c`. The ciphertext is the message combined with the
output of the stream cipher using the XOR operation, and doesn't include any
authentication tag.

`m` and `c` can point to the same address (in-place encryption/decryption). If
they don't, the regions should not overlap.

```c
int crypto_stream_chacha20_xor_ic(unsigned char *c, const unsigned char *m,
                                  unsigned long long mlen,
                                  const unsigned char *n, uint64_t ic,
                                  const unsigned char *k);
```

The `crypto_stream_chacha20_xor_ic()` function is similar to
`crypto_stream_chacha20_xor()` but adds the ability to set the initial value of
the block counter to a non-zero value, `ic`.

This permits direct access to any block without having to compute the previous
ones.

`m` and `c` can point to the same address (in-place encryption/decryption). If
they don't, the regions should not overlap.

## Usage (IETF variant, message length limited to 256 GB)

```c
int crypto_stream_chacha20_ietf(unsigned char *c, unsigned long long clen,
                               const unsigned char *n, const unsigned char *k);
```

The `crypto_stream_chacha20_ietf()` function stores `clen` pseudo random bytes
into `c` using a nonce `n` (`crypto_stream_chacha20_ietf_NONCEBYTES` bytes) and
a secret key `k` (`crypto_stream_chacha20_ietf_KEYBYTES` bytes).

```c
int crypto_stream_chacha20_ietf_xor(unsigned char *c, const unsigned char *m,
                                    unsigned long long mlen, const unsigned char *n,
                                    const unsigned char *k);
```

The `crypto_stream_chacha20_ietf_xor()` function encrypts a message `m` of
length `mlen` using a nonce `n` (`crypto_stream_chacha20_ietf_NONCEBYTES` bytes)
and a secret key `k` (`crypto_stream_chacha20_ietf_KEYBYTES` bytes).

The ciphertext is put into `c`. The ciphertext is the message combined with the
output of the stream cipher using the XOR operation, and doesn't include any
authentication tag.

`m` and `c` can point to the same address (in-place encryption/decryption). If
they don't, the regions should not overlap.

```c
int crypto_stream_chacha20_ietf_xor_ic(unsigned char *c, const unsigned char *m,
                                       unsigned long long mlen,
                                       const unsigned char *n, uint64_t ic,
                                       const unsigned char *k);
```

The `crypto_stream_chacha20_ietf_xor_ic()` function is similar to
`crypto_stream_chacha20_ietf_xor()` but adds the ability to set the initial
value of the block counter to a non-zero value, `ic`.

This permits direct access to any block without having to compute the previous
ones.

`m` and `c` can point to the same address (in-place encryption/decryption). If
they don't, the regions should not overlap.

## Constants

* `crypto_stream_chacha20_KEYBYTES`
* `crypto_stream_chacha20_NONCEBYTES`
* `crypto_stream_chacha20_ietf_KEYBYTES`
* `crypto_stream_chacha20_ietf_NONCEBYTES`

## Notes

The nonce is short. In order to prevent nonce reuse, if a key is being reused,
it is recommended to increment the previous nonce instead of generating a random
nonce every time a new stream is required.

With the IETF variant, up to 256 GB can be produced from the a (`key`, `nonce`)
pair. The original design doesn't have this limitation.
