# XSalsa20

XSalsa20 is a stream cipher based upon Salsa20 but with a much longer nonce: 192 bits instead of 64 bits.

XSalsa20 uses a 256-bit key as well as the first 128 bits of the nonce in order to compute a subkey. This subkey, as well as the remaining 64 bits of the nonce, are the parameters of the Salsa20 function used to actually generate the stream.

Like Salsa20, XSalsa20 is immune to timing attacks and provides its own 64-bit block counter to avoid incrementing the nonce after each block.

But with XSalsa20's longer nonce, it is safe to generate nonces using `randombytes_buf()` for every message encrypted with the same key without having to worry about a collision.

Sodium exposes XSalsa20 with 20 rounds as the `crypto_stream` operation.

## Usage

```c
int crypto_stream(unsigned char *c, unsigned long long clen,
                  const unsigned char *n, const unsigned char *k);
```

The `crypto_stream()` function stores `clen` pseudo random bytes into `c` using a nonce `n` (`crypto_stream_NONCEBYTES` bytes) and a secret key `k` (`crypto_stream_KEYBYTES` bytes).

```c
int crypto_stream_xor(unsigned char *c, const unsigned char *m,
                      unsigned long long mlen, const unsigned char *n,
                      const unsigned char *k);
```

The `crypto_stream_xor()` function encrypts a message `m` of length `mlen` using a nonce `n` (`crypto_stream_NONCEBYTES` bytes) and a secret key `k` (`crypto_stream_KEYBYTES` bytes).

The ciphertext is put into `c`. The ciphertext is the message combined with the output of the stream cipher using the XOR operation, and doesn't include any authentication tag.

`m` and `c` can point to the same address (in-place encryption/decryption). If they don't, the regions should not overlap.

```c
void crypto_stream_keygen(unsigned char k[crypto_stream_KEYBYTES]);
```

This helper function introduced in libsodium 1.0.12 creates a random key `k`.

It is equivalent to calling `randombytes_buf()` but improves code clarity and can prevent misuse by ensuring that the provided key length is always be correct.

## Constants

- `crypto_stream_KEYBYTES`
- `crypto_stream_NONCEBYTES`
- `crypto_stream_PRIMITIVE`
