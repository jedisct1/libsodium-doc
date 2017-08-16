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

crypto_sign(signed_message, &signed_message_len,
            MESSAGE, MESSAGE_LEN, sk);

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

### Example (multi-part message)

```c
#define MESSAGE_PART1 \
    ((const unsigned char *) "Arbitrary data to hash")
#define MESSAGE_PART1_LEN 22

#define MESSAGE_PART2 \
    ((const unsigned char *) "is longer than expected")
#define MESSAGE_PART2_LEN 23

unsigned char pk[crypto_sign_PUBLICKEYBYTES];
unsigned char sk[crypto_sign_SECRETKEYBYTES];
crypto_sign_keypair(pk, sk);

crypto_sign_state state;
unsigned char sig[crypto_sign_BYTES];

/* signature creation */

crypto_sign_init(&state)
crypto_sign_update(&state, MESSAGE_PART1, MESSAGE_PART1_LEN);
crypto_sign_update(&state, MESSAGE_PART2, MESSAGE_PART2_LEN);
crypto_sign_final_create(&state, sig, NULL, sk);

/* signature verification */

crypto_sign_init(&state)
crypto_sign_update(&state, MESSAGE_PART1, MESSAGE_PART1_LEN);
crypto_sign_update(&state, MESSAGE_PART2, MESSAGE_PART2_LEN);
if (crypto_sign_final_verify(&state, sig, pk) != 0) {
    /* message forged! */
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

The signed message, which includes the signature + a plain copy of the message, is put into `sm`, and is `crypto_sign_BYTES + mlen` bytes long.

If `smlen` is not a `NULL` pointer, the actual length of the signed message is stored into `smlen`.

```c
int crypto_sign_open(unsigned char *m, unsigned long long *mlen,
                     const unsigned char *sm, unsigned long long smlen,
                     const unsigned char *pk);
```

The `crypto_sign_open()` function checks that the signed message `sm` whose length is `smlen` bytes has a valid signature for the public key `pk`.

If the signature is doesn't appear to be valid, the function returns `-1`.

On success, it puts the message with the signature removed into `m`, stores its length into `mlen` if `mlen` is not a `NULL` pointer, and returns `0`.

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

## Multi-part messages

If the message doesn't fit in memory, it can be provided as a sequence of arbitrarily-sized chunks.

This will use the Ed25519ph signature system, that pre-hashes the message. In other words, what gets signed is not the message itself, but its image through a hash function.

If the message _can_ fit in memory and can be supplied as a single chunk, the single-part API should be preferred.

```c
int crypto_sign_init(crypto_sign_state *state);
```

The `crypto_sign_init()` function initializes the state `state`. This function must be called before the first `crypto_sign_update()` call.

```c
int crypto_sign_update(crypto_sign_state *state,
                       const unsigned char *m, unsigned long long mlen);
```

Add a new chunk `m` of length `mlen` bytes to the message that will eventually be signed.

After all parts have been supplied, one of the following functions can be called:

```c
int crypto_sign_final_create(crypto_sign_state *state, unsigned char *sig,
                             unsigned long long *siglen_p,
                             const unsigned char *sk);
```

The `crypto_sign_final_create()` function computes a signature for the previously supplied message, using the secret key `sk` and puts it into `sig`.

If `siglen_p` is not `NULL`, the length of the signature is stored at this address.

It is safe to ignore `siglen` and always consider a signature as `crypto_sign_BYTES` bytes long: shorter signatures will be transparently padded with zeros if necessary.

```c
int crypto_sign_final_verify(crypto_sign_state *state, unsigned char *sig,
                             const unsigned char *pk);
```

The `crypto_sign_final_verify()` function verifies that `sig` is a valid signature for the message whose content has been previously supplied using `crypto_update()`, using the public key `pk`.

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

## Data structures

- `crypto_sign_state`, whose size can be retrieved using `crypto_sign_statebytes()`

## Constants

- `crypto_sign_PUBLICKEYBYTES`
- `crypto_sign_SECRETKEYBYTES`
- `crypto_sign_BYTES`
- `crypto_sign_SEEDBYTES`

## Algorithm details

- Single-part signature: Ed25519
- Multi-part signature: Ed25519ph

## Notes

`crypto_sign_verify()` and `crypto_sign_verify_detached()` are only designed to verify signatures computed using `crypto_sign()` and `crypto_sign_detached()`.

The original NaCl `crypto_sign_open()` implementation overwrote 64 bytes after the message. The libsodium implementation doesn't write past the end of the message.

Ed25519ph (used by the multi-part API) was implemented in libsodium 1.0.12.
