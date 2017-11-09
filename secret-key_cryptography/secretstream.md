# Stream encryption/file encryption

This high-level API encrypts a sequence of messages, or a single message split into an arbitrary number of chunks, using a secret key, with the following properties:

- Messages cannot be truncated, removed, reordered, duplicated or modified without this being detected by the decryption functions.
- The same sequence encrypted twice will produce different ciphertexts.
- An authentication tag is added to each encrypted message: stream corruption will be detected early, without having to read the stream until the end.
- Each message can include additional data (ex: timestamp, protocol version) in the computation of the authentication tag.
- Messages can have different sizes.
- There are no practical limits to the total length of the stream, or to the total number of individual messages.
- Ratcheting: at any point in the stream, it is possible to "forget" the key used to encrypt the previous messages, and switch to a new key.

This API can be used to securely send an ordered sequence of messages to a peer. Since the length of the stream is not limited, it can also be used to encrypt files regardless of their size.

It transparently generates nonces and automatically handles key rotation.

The `crypto_secretstream_*()` API was introduced in libsodium 1.0.14.

## Example (stream encryption)

```c
#define MESSAGE_PART1 (const unsigned char *) "Arbitrary data to encrypt"
#define MESSAGE_PART1_LEN    25
#define CIPHERTEXT_PART1_LEN MESSAGE_PART1_LEN + crypto_secretstream_xchacha20poly1305_ABYTES

#define MESSAGE_PART2 (const unsigned char *) "split into"
#define MESSAGE_PART2_LEN    10
#define CIPHERTEXT_PART2_LEN MESSAGE_PART2_LEN + crypto_secretstream_xchacha20poly1305_ABYTES

#define MESSAGE_PART3 (const unsigned char *) "three messages"
#define MESSAGE_PART3_LEN    14
#define CIPHERTEXT_PART3_LEN MESSAGE_PART3_LEN + crypto_secretstream_xchacha20poly1305_ABYTES

crypto_secretstream_xchacha20poly1305_state state;
unsigned char key[crypto_secretstream_xchacha20poly1305_KEYBYTES];
unsigned char header[crypto_secretstream_xchacha20poly1305_HEADERBYTES];
unsigned char c1[CIPHERTEXT_PART1_LEN],
              c2[CIPHERTEXT_PART2_LEN],
              c3[CIPHERTEXT_PART3_LEN];

/* Shared secret key required to encrypt/decrypt the stream */
crypto_secretstream_xchacha20poly1305_keygen(key);

/* Set up a new stream: initialize the state and create the header */
crypto_secretstream_xchacha20poly1305_init_push(&state, header, key);

/* Now, encrypt the first chunk. `c1` will contain an encrypted,
 * authenticated representation of `MESSAGE_PART1`. */
crypto_secretstream_xchacha20poly1305_push
 (&state, c1, NULL, MESSAGE_PART1, MESSAGE_PART1_LEN, NULL, 0, 0);

/* Encrypt the second chunk. `c2` will contain an encrypted, authenticated
 * representation of `MESSAGE_PART2`. */
crypto_secretstream_xchacha20poly1305_push
 (&state, c2, NULL, MESSAGE_PART2, MESSAGE_PART2_LEN, NULL, 0, 0);

/* Encrypt the last chunk, and store the ciphertext into `c3`.
 * Note the `TAG_FINAL` tag to indicate that this is the final chunk. */
crypto_secretstream_xchacha20poly1305_push
 (&state, c3, NULL, MESSAGE_PART3, MESSAGE_PART3_LEN, NULL, 0,
  crypto_secretstream_xchacha20poly1305_TAG_FINAL);
```

## Example (stream decryption)

```c
unsigned char tag;
unsigned char m1[MESSAGE_PART1_LEN],
              m2[MESSAGE_PART2_LEN],
              m3[MESSAGE_PART3_LEN];

/* Decrypt the stream: initializes the state, using the key and a header */
if (crypto_secretstream_xchacha20poly1305_init_pull(&state, header, key) != 0) {
    /* Invalid header, no need to go any further */
}

/* Decrypt the first chunk. A real application would probably use
 * a loop, that reads data from the network or from disk, and exits after
 * an error, or after the last chunk (with a `TAG_FINAL` tag) has been
 * decrypted. */
if (crypto_secretstream_xchacha20poly1305_pull
    (&state, m1, NULL, &tag, c1, CIPHERTEXT_PART1_LEN, NULL, 0) != 0) {
   /* Invalid/incomplete/corrupted ciphertext - abort */
}
assert(tag == 0); /* The tag is the one we attached to this chunk: 0 */

/* Decrypt the second chunk, store the result into `m2` */
if (crypto_secretstream_xchacha20poly1305_pull
    (&state, m2, NULL, &tag, c2, CIPHERTEXT_PART2_LEN, NULL, 0) != 0) {
    /* Invalid/incomplete/corrupted ciphertext - abort */
}
assert(tag == 0); /* Not the end of the stream yet */

/* Decrypt the last chunk, store the result into `m3` */
if (crypto_secretstream_xchacha20poly1305_pull
    (&state, m3, NULL, &tag, c3, CIPHERTEXT_PART3_LEN, NULL, 0) != 0) {
    /* Invalid/incomplete/corrupted ciphertext - abort */
}
/* The tag indicates that this is the final chunk, no need to read and decrypt more */
assert(tag == crypto_secretstream_xchacha20poly1305_TAG_FINAL);
```

See down below for a complete example of file encryption/decryption using the secretstream API.

## Usage

The `crypto_secretstream_*_push()` functions set creates an encrypted stream. The `crypto_secretstream_*_pull()` functions set is the decryption counterpart.

An encrypted stream starts with a short header, whose size is `crypto_secretstream_xchacha20poly1305_HEADERBYTES` bytes. That header must be sent/stored before the sequence of encrypted messages, as it is required to decrypt the stream.

A tag is attached to each message. That tag can be any of:
- `0`, or `crypto_secretstream_xchacha20poly1305_TAG_MESSAGE`: the most common tag, that doesn't add any information about the nature of the message.
- `crypto_secretstream_xchacha20poly1305_TAG_FINAL`: indicates that the message marks the end of the stream, and erases the secret key used to encrypt the previous sequence.
- `crypto_secretstream_xchacha20poly1305_TAG_PUSH`: indicates that the message marks the end of a set of messages, but not the end of the stream. For example, a huge JSON string sent as multiple chunks can use this tag to indicate to the application that the string is complete and that it can be decoded. But the stream itself is not closed, and more data may follow.
- `crypto_secretstream_xchacha20poly1305_TAG_REKEY`: "forget" the key used to encrypt this message and the previous ones, and derive a new secret key.

A typical encrypted stream simply attaches `0` as a tag to all messages, except the last one which is tagged as `TAG_FINAL`.

Note that tags are encrypted; encrypted streams do not reveal any information about sequence boundaries (`PUSH` and `REKEY` tags).

For each message, additional data can be included in the computation of the authentication tag. With this API, additional data is rarely required, and most applications can just use `NULL` and a length of `0` instead.

### Encryption

```c
void crypto_secretstream_xchacha20poly1305_keygen
   (unsigned char k[crypto_secretstream_xchacha20poly1305_KEYBYTES]);
```

Creates a random, secret key to encrypt a stream, and stores it into `k`.

Note that using this function is not required to obtain a suitable key: the `secretstream` API can use any secret key whose size is `crypto_secretstream_xchacha20poly1305_KEYBYTES` bytes.

Network protocols can leverage the key exchange API in order to get a shared key that can be used to encrypt streams. Similarly, file encryption applications can use the password hashing API to get a key that can be used with the functions below.

```c
int crypto_secretstream_xchacha20poly1305_init_push
   (crypto_secretstream_xchacha20poly1305_state *state,
    unsigned char header[crypto_secretstream_xchacha20poly1305_HEADERBYTES],
    const unsigned char k[crypto_secretstream_xchacha20poly1305_KEYBYTES]);
```

The `crypto_secretstream_xchacha20poly1305_init_push()` function initializes a state `state` using the key `k` and an internal, automatically generated initialization vector. It then stores the stream header into `header` (`crypto_secretstream_xchacha20poly1305_HEADERBYTES` bytes).

This is the first function to call in order to create an encrypted stream. The key `k` will not be required any more for subsequent operations.

```c
int crypto_secretstream_xchacha20poly1305_push
   (crypto_secretstream_xchacha20poly1305_state *state,
    unsigned char *c, unsigned long long *clen_p,
    const unsigned char *m, unsigned long long mlen,
    const unsigned char *ad, unsigned long long adlen, unsigned char tag);
```

The `crypto_secretstream_xchacha20poly1305_push()` function encrypts a message `m` of length `mlen` bytes using the state `state` and the tag `tag`.

Additional data `ad` of length `adlen` can be included in the computation of the authentication tag. If no additional data is required, `ad` can be `NULL` and `adlen` set to `0`.

The ciphertext is put into `c`.

If `clen_p` is not `NULL`, the ciphertext length will be stored at that address. But with this particular construction, the ciphertext length is guaranteed to always be `mlen + crypto_secretstream_xchacha20poly1305_ABYTES`.

The maximum length of an individual message is `crypto_secretstream_xchacha20poly1305_MESSAGEBYTES_MAX` bytes (~ 256 GB).

### Decryption

```c
int crypto_secretstream_xchacha20poly1305_init_pull
   (crypto_secretstream_xchacha20poly1305_state *state,
    const unsigned char header[crypto_secretstream_xchacha20poly1305_HEADERBYTES],
    const unsigned char k[crypto_secretstream_xchacha20poly1305_KEYBYTES]);
```

The `crypto_secretstream_xchacha20poly1305_init_pull()` function initializes a state given a secret key `k` and a header `header`. The key `k` will not be required any more for subsequent operations.

It returns `0` on success, or `-1` if the header is invalid.

```c
int crypto_secretstream_xchacha20poly1305_pull
   (crypto_secretstream_xchacha20poly1305_state *state,
    unsigned char *m, unsigned long long *mlen_p, unsigned char *tag_p,
    const unsigned char *c, unsigned long long clen,
    const unsigned char *ad, unsigned long long adlen);
```

The `crypto_secretstream_xchacha20poly1305_pull()` function verifies that `c` (a sequence of `clen` bytes) contains a valid ciphertext and authentication tag for the given state `state` and optional authenticated data `ad` of length `adlen` bytes.

If the ciphertext appears to be invalid, the function returns `-1`.

If the authentication tag appears to be correct, the decrypted message is put into `m`.

If `tag_p` is not `NULL`, the tag attached to the message is stored at that address.

If `mlen_p` is not `NULL`, the message length is stored at that address. But with this particular construction, it is guaranteed to always be `clen - crypto_secretstream_xchacha20poly1305_ABYTES` bytes.

Applications will typically call this function in a loop, until a message with the `crypto_secretstream_xchacha20poly1305_TAG_FINAL` tag is found.

### Rekeying

Rekeying happens automatically and transparently, before the internal counter of the underlying cipher wraps.
Therefore, streams can be arbitrary large.

Optionally, applications for which forward secrecy is critical can attach the ``crypto_secretstream_xchacha20poly1305_TAG_REKEY` tag to a message in order to trigger an explicit rekeying. The decryption API will automatically update the key if this tag is found attached to a message.

Explicit rekeying can also be performed without adding a tag, by calling the `crypto_secretstream_xchacha20poly1305_rekey()` function:

```c
void crypto_secretstream_xchacha20poly1305_rekey
    (crypto_secretstream_xchacha20poly1305_state *state);
```

This updates the state, but doesn't add any information about the key change to the stream. If this function is used to create an encrypted stream, the decryption process must call that function at the exact same stream location.

## Constants

- `crypto_secretstream_xchacha20poly1305_ABYTES`
- `crypto_secretstream_xchacha20poly1305_HEADERBYTES`
- `crypto_secretstream_xchacha20poly1305_KEYBYTES`
- `crypto_secretstream_xchacha20poly1305_MESSAGEBYTES_MAX`
- `crypto_secretstream_xchacha20poly1305_TAG_MESSAGE`
- `crypto_secretstream_xchacha20poly1305_TAG_PUSH`
- `crypto_secretstream_xchacha20poly1305_TAG_REKEY`
- `crypto_secretstream_xchacha20poly1305_TAG_FINAL`

## Algorithm

Initialization (`secretstream_init`): a subkey `k` and a 64-bit nonce `n` are derived from a key `K` and a 192-bit random nonce `N`, using the same algorithm as XChaCha20.
`i` is a 32-bit counter.

```text
k <- HChaCha20(K, n[0..16])
n <- N[16..24]
i <- 1
```

`secretstream_init_push()` outputs `N`.

Encryption:

For every message `M` with a tag `T`:

```text
c, mac <- ChaCha20Poly1305-IETF-XOR(key = k, nonce = i || n, msg = T || {0} * 63 || M)
n <- n ^ mac
i <- (i + 1) & 0xffffffff
if i = 0:
  rekey()
```

`secretstream_push()` outputs `c` with the first block truncated to the tag size: `c[0] || c[64..] || mac`

Encrypting a unique message using `secretstream` is equivalent to `XChaCha20Poly1305-IETF-XOR(key = k, nonce = 0 || n, T || {0} * 63 || M)`.

Rekeying:

```text
k || n <- ChaCha20-IETF-XOR(key = k, nonce = i || n, msg = k || n)
i <- 1
```

A `FINAL` tag performs an implicit rekeying.

## File encryption example code

```c
#include <stdio.h>
#include <sodium.h>

#define CHUNK_SIZE 4096

static int
encrypt(const char *target_file, const char *source_file,
        const unsigned char key[crypto_secretstream_xchacha20poly1305_KEYBYTES])
{
    unsigned char  buf_in[CHUNK_SIZE];
    unsigned char  buf_out[CHUNK_SIZE + crypto_secretstream_xchacha20poly1305_ABYTES];
    unsigned char  header[crypto_secretstream_xchacha20poly1305_HEADERBYTES];
    crypto_secretstream_xchacha20poly1305_state st;
    FILE          *fp_t, *fp_s;
    unsigned long long out_len;
    size_t         rlen;
    int            eof;
    unsigned char  tag;

    fp_s = fopen(source_file, "rb");
    fp_t = fopen(target_file, "wb");
    crypto_secretstream_xchacha20poly1305_init_push(&st, header, key);
    fwrite(header, 1, sizeof header, fp_t);
    do {
        rlen = fread(buf_in, 1, sizeof buf_in, fp_s);
        eof = feof(fp_s);
        tag = eof ? crypto_secretstream_xchacha20poly1305_TAG_FINAL : 0;
        crypto_secretstream_xchacha20poly1305_push(&st, buf_out, &out_len, buf_in, rlen,
                                                   NULL, 0, tag);
        fwrite(buf_out, 1, (size_t) out_len, fp_t);
    } while (! eof);
    fclose(fp_t);
    fclose(fp_s);
    return 0;
}

static int
decrypt(const char *target_file, const char *source_file,
        const unsigned char key[crypto_secretstream_xchacha20poly1305_KEYBYTES])
{
    unsigned char  buf_in[CHUNK_SIZE + crypto_secretstream_xchacha20poly1305_ABYTES];
    unsigned char  buf_out[CHUNK_SIZE];
    unsigned char  header[crypto_secretstream_xchacha20poly1305_HEADERBYTES];
    crypto_secretstream_xchacha20poly1305_state st;
    FILE          *fp_t, *fp_s;
    unsigned long long out_len;
    size_t         rlen;
    int            eof;
    int            ret = -1;
    unsigned char  tag;

    fp_s = fopen(source_file, "rb");
    fp_t = fopen(target_file, "wb");
    fread(header, 1, sizeof header, fp_s);
    if (crypto_secretstream_xchacha20poly1305_init_pull(&st, header, key) != 0) {
        goto ret; /* incomplete header */
    }
    do {
        rlen = fread(buf_in, 1, sizeof buf_in, fp_s);
        eof = feof(fp_s);
        if (crypto_secretstream_xchacha20poly1305_pull(&st, buf_out, &out_len, &tag,
                                                       buf_in, rlen, NULL, 0) != 0) {
            goto ret; /* corrupted chunk */
        }
        if (tag == crypto_secretstream_xchacha20poly1305_TAG_FINAL && ! eof) {
            goto ret; /* premature end (end of file reached before the end of the stream) */
        }
        fwrite(buf_out, 1, (size_t) out_len, fp_t);
    } while (! eof);

    ret = 0;
ret:
    fclose(fp_t);
    fclose(fp_s);
    return ret;
}

int
main(void)
{
    unsigned char key[crypto_secretstream_xchacha20poly1305_KEYBYTES];

    if (sodium_init() != 0) {
        return 1;
    }
    crypto_secretstream_xchacha20poly1305_keygen(key);
    if (encrypt("/tmp/encrypted", "/tmp/original", key) != 0) {
        return 1;
    }
    if (decrypt("/tmp/decrypted", "/tmp/encrypted", key) != 0) {
        return 1;
    }
    return 0;
}
```
