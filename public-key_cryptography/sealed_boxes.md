# Sealed boxes

## Example

```c
#define MESSAGE (const unsigned char *) "Message"
#define MESSAGE_LEN 7
#define CIPHERTEXT_LEN (crypto_box_SEALBYTES + MESSAGE_LEN)

/* Recipient creates a long-term key pair */
unsigned char recipient_pk[crypto_box_PUBLICKEYBYTES];
unsigned char recipient_sk[crypto_box_SECRETKEYBYTES];
crypto_box_keypair(recipient_pk, recipient_sk);

/* Anonymous sender encrypts a message using an ephemeral key pair
 * and the recipient's public key */
unsigned char ciphertext[CIPHERTEXT_LEN];
crypto_box_seal(ciphertext, MESSAGE, MESSAGE_LEN, recipient_pk);

/* Recipient decrypts the ciphertext */
unsigned char decrypted[MESSAGE_LEN];
if (crypto_box_seal_open(decrypted, ciphertext, CIPHERTEXT_LEN,
                         recipient_pk, recipient_sk) != 0) {
    /* message corrupted or not intended for this recipient */
}
```

## Purpose

Sealed boxes are designed to anonymously send messages to a recipient given its
public key.

Only the recipient can decrypt these messages, using its private key. While the
recipient can verify the integrity of the message, it cannot verify the identity
of the sender.

A message is encrypted using an ephemeral key pair, whose secret part is
destroyed right after the encryption process.

Without knowing the secret key used for a given message, the sender cannot
decrypt its own message later. And without additional data, a message cannot be
correlated with the identity of its sender.

## Usage

```c
int crypto_box_seal(unsigned char *c, const unsigned char *m,
                    unsigned long long mlen, const unsigned char *pk);
```

The `crypto_box_seal()` function encrypts a message `m` of length `mlen` for a
recipient whose public key is `pk`. It puts the ciphertext whose length is
`crypto_box_SEALBYTES + mlen` into `c`.

The function creates a new key pair for each message, and attaches the public
key to the ciphertext. The secret key is overwritten and is not accessible after
this function returns.

```c
int crypto_box_seal_open(unsigned char *m, const unsigned char *c,
                         unsigned long long clen,
                         const unsigned char *pk, const unsigned char *sk);
```

The `crypto_box_seal_open()` function decrypts the ciphertext `c` whose length
is `clen`, using the key pair (`pk`, `sk`), and puts the decrypted message into
`m` (`clen - crypto_box_SEALBYTES` bytes).

Key pairs are compatible with other `crypto_box_*` operations and can be created
using `crypto_box_keypair()` or `crypto_box_seed_keypair()`.

This function doesn't require passing the public key of the sender, as the
ciphertext already includes this information.

## Constants

* `crypto_box_SEALBYTES`

## Algorithm details

Sealed boxes leverage the `crypto_box` construction (X25519, XSalsa20-Poly1305).

The format of a sealed box is

```text
ephemeral_pk ‖ box(m, recipient_pk, ephemeral_sk, nonce=blake2b(ephemeral_pk ‖ recipient_pk))
```
