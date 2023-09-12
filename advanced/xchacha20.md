# XChaCha20

XChaCha20 is a variant of ChaCha20 with an extended nonce, allowing random nonces to be safe.

XChaCha20 doesn’t require any lookup tables and avoids the possibility of timing attacks.

Internally, XChaCha20 works like a block cipher used in counter mode. It uses the HChaCha20 hash function to derive a subkey and a subnonce from the original key and extended nonce, and a dedicated 64-bit block counter to avoid incrementing the nonce after each block.

XChaCha20 is generally recommended over plain ChaCha20 due to its extended nonce size, and its comparable performance. However, XChaCha20 is currently not widely implemented outside the libsodium library, due to the absence of formal specification.

## Usage

``` c
int crypto_stream_xchacha20(unsigned char *c, unsigned long long clen,
                            const unsigned char *n, const unsigned char *k);
```

The `crypto_stream_xchacha20()` function stores `clen` pseudo random bytes into `c` using a nonce `n` (`crypto_stream_xchacha20_NONCEBYTES` bytes) and a secret key `k` (`crypto_stream_xchacha20_KEYBYTES` bytes).

``` c
int crypto_stream_xchacha20_xor(unsigned char *c, const unsigned char *m,
                                unsigned long long mlen, const unsigned char *n,
                                const unsigned char *k);
```

The `crypto_stream_xchacha20_xor()` function encrypts a message `m` of length `mlen` using a nonce `n` (`crypto_stream_xchacha20_NONCEBYTES` bytes) and a secret key `k` (`crypto_stream_xchacha20_KEYBYTES` bytes).

The ciphertext is put into `c`. The ciphertext is the message combined with the output of the stream cipher using the XOR operation, and doesn’t include any authentication tag.

`m` and `c` can point to the same address (in-place encryption/decryption). If they don’t, the regions should not overlap.

``` c
int crypto_stream_xchacha20_xor_ic(unsigned char *c, const unsigned char *m,
                                   unsigned long long mlen,
                                   const unsigned char *n, uint64_t ic,
                                   const unsigned char *k);
```

The `crypto_stream_xchacha20_xor_ic()` function is similar to `crypto_stream_xchacha20_xor()` but adds the ability to set the initial value of the block counter to a non-zero value, `ic`.

This permits direct access to any block without having to compute the previous ones.

`m` and `c` can point to the same address (in-place encryption/decryption). If they don’t, the regions should not overlap.

``` c
void crypto_stream_xchacha20_keygen(unsigned char k[crypto_stream_xchacha20_KEYBYTES]);
```

This helper function introduced in libsodium 1.0.12 creates a random key `k`.

It is equivalent to calling `randombytes_buf()` but improves code clarity and can prevent misuse by ensuring that the provided key length is always be correct.

## Constants

  - `crypto_stream_xchacha20_KEYBYTES`
  - `crypto_stream_xchacha20_NONCEBYTES`

## Notes

Unlike plain ChaCha20, the nonce is 192 bits long, so that generating a random nonce for every message is safe. If the output of the PRNG is indistinguishable from random data, the probability for a collision to happen is negligible.

XChaCha20 was implemented in libsodium 1.0.12.
