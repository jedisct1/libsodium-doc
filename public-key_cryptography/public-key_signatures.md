# Public-key signatures

## Example (combined mode)

```c
#define MESSAGE (const unsigned char *) "test"
#define MESSAGE_LEN 4

unsigned char pk[crypto_sign_PUBLICKEYBYTES];
unsigned char sk[crypto_sign_SECRETKEYBYTES];
crypto_sign_keypair(pk, sk);

unsigned char signed_message[crypto_sign_BYTES + MESSAGE_LEN];
unsigned long long signed_message_len;

if (crypto_sign(signed_message, &signed_message_len,
                MESSAGE, MESSAGE_LEN, sk) != 0) {
    /* Error */            
}

unsigned char unsigned_message[MESSAGE_LEN];
unsigned long long unsigned_message_len;
if (crypto_sign_open(unsigned_message, &unsigned_message_len,
                     signed_message, signed_message_len, pk) != 0) {
    /* Incorrect signature! */
}
```

### Example (detached mode)

```c
#define MESSAGE (const unsigned char *) "test"
#define MESSAGE_LEN 4

unsigned char pk[crypto_sign_PUBLICKEYBYTES];
unsigned char sk[crypto_sign_SECRETKEYBYTES];
crypto_sign_keypair(pk, sk);

unsigned char sig[crypto_sign_BYTES];
crypto_sign_detached(sig, NULL, MESSAGE, MESSAGE_LEN, sk);

if (crypto_sign_verify_detached(sig, MESSAGE, MESSAGE_LEN, pk) != 0) {
    /* Incorrect signature! */
}
```

## Purpose

In this system, a signer generates a key pair:
- a secret key, that will be used to append a signature to any number of messages
- a public key, that anybody can use to verify that the signature appended to a message was actually issued by the creator of the public key.

Verifiers need to already know and ultimately trust a public key before messages signed using it can be verified.

*Warning:* this is different from authenticated encryption. Appending a signature does not change the representation of the message itself.

## Key pair generation

```c
int crypto_sign_keypair(unsigned char *pk, unsigned char *sk);
```

The `crypto_sign_keypair()` function randomly generates a secret key and a corresponding public key. The public key is put into `pk` (`crypto_sign_PUBLICKEYBYTES` bytes) and the secret key into `sk` (`crypto_sign_SECRETKEYBYTES` bytes).

```c
int crypto_sign_seed_keypair(unsigned char *pk, unsigned char *sk,
                             const unsigned char *seed);
```

Using `crypto_sign_seed_keypair()`, the key pair can also be deterministically derived from a single key `seed` (`crypto_sign_SEEDBYTES` bytes).

## Combined mode

```c
int crypto_sign(unsigned char *sm, unsigned long long *smlen,
                const unsigned char *m, unsigned long long mlen,
                const unsigned char *sk);
```

The `crypto_sign()` function prepends a signature to a message `m` whose length is `mlen` bytes, using the secret key `sk`.

The signed message, which includes the signature + a plain copy of the message, is put into `sm`, and can be up to `crypto_sign_BYTES + mlen` bytes long.

The actual length of the signed message is stored into `smlen`.

```c
int crypto_sign_open(unsigned char *m, unsigned long long *mlen,
                     const unsigned char *sm, unsigned long long smlen,
                     const unsigned char *pk);
```

The `crypto_sign_open()` function checks that the signed message `sm` whose length is `smlen` bytes has a valid signature for the public key `pk`.

If the signature is doesn't appear to be valid, the function returns `-1`.

On success, it puts the message with the signature removed into `m`, stores its length into `mlen` and returns `0`.

## Detached mode

In detached mode, the signature is stored without attaching a copy of the original message to it.

```c
int crypto_sign_detached(unsigned char *sig, unsigned long long *siglen,
                         const unsigned char *m, unsigned long long mlen,
                         const unsigned char *sk);
```

The `crypto_sign_detached()` function signs the message `m` whose length is `mlen` bytes, using the secret key `sk`, and puts the signature into `sig`, which can be up to `crypto_sign_BYTES` bytes long.

The actual length of the signature is put into `siglen` if `siglen` is not `NULL`.

It is safe to ignore `siglen` and always consider a signature as `crypto_sign_BYTES` bytes long: shorter signatures will be transparently padded with zeros if necessary.

```c
int crypto_sign_verify_detached(const unsigned char *sig,
                                const unsigned char *m,
                                unsigned long long mlen,
                                const unsigned char *pk);
```

The `crypto_sign_verify_detached()` function verifies that `sig` is a valid signature for the message `m` whose length is `mlen` bytes, using the signer's public key `pk`.

It returns `-1` if the signature fails verification, or `0` on success.

## Extracting the seed and the public key from the secret key

The secret key actually includes the seed (either a random seed or the one given to `crypto_sign_seed_keypair()`) as well as the public key.

While the public key can always be derived from the seed, the precomputation saves a significant amount of CPU cycles when signing.

If required, Sodium provides two functions to extract the seed and the public key from the secret key:

```c
int crypto_sign_ed25519_sk_to_seed(unsigned char *seed,
                                   const unsigned char *sk);

int crypto_sign_ed25519_sk_to_pk(unsigned char *pk, const unsigned char *sk);
```

The `crypto_sign_ed25519_sk_to_seed()` function extracts the seed from the secret key `sk` and copies it into `seed` (`crypto_sign_SEEDBYTES` bytes).

The `crypto_sign_ed25519_sk_to_pk()` function extracts the public key from the secret key `sk` and copies it into `pk` (`crypto_sign_PUBLICKEYBYTES` bytes).

## Constants

- `crypto_sign_PUBLICKEYBYTES`
- `crypto_sign_SECRETKEYBYTES`
- `crypto_sign_BYTES`
- `crypto_sign_SEEDBYTES`

## Algorithm details

- Signature: Ed25519

## Notes

`crypto_sign_verify()` and `crypto_sign_verify_detached()` are only
designed to verify signatures computed using `crypto_sign()` and
`crypto_sign_detached()`.
