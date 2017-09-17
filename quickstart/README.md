# Quickstart / Libsodium FAQ

## Boilerplate

A project using libsodium should include the `sodium.h` header. Including individual headers is neither required nor recommended.

The `sodium_init()` function should then be called before any other function. It is safe to call `sodium_init()` multiple times, or from different threads; it will immediately return `1` without doing anything if the library had already been initialized.

```c
#include <sodium.h>

int main(void)
{
    if (sodium_init() < 0) {
        /* panic! the library couldn't be initialized, it is not safe to use */
    }
    return 0;
}
```

## How do I generate random numbers that are safe to use for cryptography?

Use the [`randombytes` API](../generating_random_data/README.md).

## How do I compute a hash?

Use the [`crypto_generichash` API](../hashing/generic_hashing.md).

## How do I encrypt some data?

### One-shot encryption, where everything fits in memory

- Create a secret key using `crypto_secretbox_keygen()`
- Create a nonce using `randombytes_buf(nonce, sizeof nonce)`
- Use `crypto_secretbox()` to encrypt the message, and send/store the resulting ciphertext along with the nonce. Unlike the key, the nonce doesn't have to be secret.
- Use `crypto_secretbox_open()` to decrypt the ciphertext using the same key and nonce.

### If everything doesn't fit in memory, or is not available as a single chunk

- With libsodium 1.0.14 and beyond, use the [`crypto_secretstream` API](../secret-key_cryptography/secretstream.md).
- Otherwise, read the guide to [encrypting a set of messages](../secret-key_cryptography/secret-key_authentication.md)

## How do I safely store and later verify a password?

- Use the `crypto_pwhash_str()` and `crypto_pwhash_str_verify()` functions, described in the [`password hashing guide`](../password_hashing/the_argon2i_function.md).

## How do I encrypt a file using a password?

- Derive an encryption key from the password using [`crypto_pwhash()`](../password_hashing/the_argon2i_function.md).
- Use that key with the [`crypto_secretstream` API](../secret-key_cryptography/secretstream.md).
- File metadata should probably be part of the encrypted data, or, if it is not secret, included as additional data.

## How can `A` and `B` securely communicate without a pre-shared secret key?

Use the [key exchange API](../key_exchange/README.md):

- `A` and `B` both call `crypto_kx_keypair()` to create their own key pair. Secret keys have to remain secret, but `A` can send its public key to `B` or even make it available to everyone. The same applies to `B`'s public key.
- `A` uses `crypto_kx_client_session_keys()` along with `B`'s public key and its key pair to create a set of shared keys to communicate with `B`.
- `B` uses `crypto_kx_server_session_keys()` along with `A`'s public key and its key pair to create a set of shared keys to communicate with `A`.

The shared keys computed by `A` and `B` will be identical. There are two of them. One can be used to encrypt and decrypt message in one direction (from `A` to `B`) and the other one to encrypt and decrypt messages in the other direction (from `B` to `A`).

## Shall I call `crypto_generichash_blake2b` or just `crypto_generichash`?

Always use the high-level API if one is available. The low-level API it is based on is guaranteed not to change before a major revision of the library. And if a high-level API needs to use a different construction, it will expose a different set of functions.

This is true for all APIs provided by the library.

## I want to write bindings for my favorite language, where should I start?

Start with the `crypto_generichash` and with the `crypto_secretstream` APIs. These are the trickiest to implement bindings for, and will provide good insights about how to design your bindings.