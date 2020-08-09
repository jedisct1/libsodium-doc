# Encrypting a sequence or a set of dependent messages

The `crypto_secretbox`, `crypto_box` and `crypto_seal` APIs are designed to
encrypt **independent** messages.

However, applications may wish to encrypt a set of messages with the following
constraints:

* If a sequence of messages is encrypted, the decryption system must ensure that
the complete, unmodified sequence has been properly received. In particular,
it must guarantee that messages haven't been added, removed, duplicated,
truncated or reordered.
* If an unordered set of encrypted messages is transmitted (for example when
using a protocol such as UDP), the decryption system must be able to reorder
the messages.

Simply encrypting individual messages with a random nonce doesn't respect these
constraints.

For sequences of messages, libsodium 1.0.14 and beyond implement the
[`crypto_secretstream` API](secretstream.md) that satisfies the above
constraints. This API is recommended to encrypt files or for secure
communications over a reliable protocol with ordering guarantees, such as TCP.

On older versions of the library, and with transport protocols featuring weaker
ordering and reliability guarantees, these constraints can be satisfied using
AEAD (Authenticated Encryption with Additional Data) constructions.

Recommended API:
[`crypto_aead_xchacha20poly1305_ietf_*()`](xchacha20-poly1305_construction.md).

## Initialization vector

The same key will be used to encrypt a set of messages. This is perfectly
acceptable as long as that key is combined with a unique nonce for each message.

The easiest way to achieve this is to choose a random initial nonce, and to
increment it after each message:

```c
unsigned char nonce[NPUBBYTES];

randombytes_buf(nonce, sizeof nonce);

encrypt(c1, m1, key, nonce);
sodium_increment(nonce, sizeof nonce);
encrypt(c2, m2, key, nonce);
sodium_increment(nonce, sizeof nonce);
...
```

Although the terms "nonce" and "initialization vector" are frequently used
interchangeably, in this documentation, we use the term "initialization vector"
to describe the first nonce used to encrypt a set of messages.

A random initialization vector ensures that even if the key is reused to encrypt
a different set of messages, two messages will not be encrypted using the same
nonce, which, for most constructions, is critical for security.

This assumes that the size of the nonce is big enough that the probability of a
nonce reuse is negligible. With a 192-bit nonce size, the XChaCha20 and XSalsa20
ciphers fit in this category. The AES and ChaCha20 (not XChaCha20) ciphers do
_not_ fit in this category. Please refer to the "short nonces" section below for
recommendations about using such ciphers, if you really have to use these.

In order for the set of messages to be decrypted, the initialization vector must
be transmitted. Unlike the key, it doesn't have to be secret, so it can be
prepended to the ciphertext, before the first message.

## Authentication tags

AEAD constructions encrypt messages and append an authentication tag. That
authentication tag is computed using the following data:

* The secret key
* The nonce
* The message, before or after encryption
* Optionally, some additional data

During the decryption process, the authentication tag is computed using the same
data, and compared with the one that was attached to the ciphertext. If the tag
is large enough, a valid authentication tag for a given ciphertext cannot be
computed without knowing the secret key.

If these authentication tags differ, it means that the ciphertext has been
corrupted, tampered with, or created without the correct secret key. In such a
situation, decryption functions return an error code, and applications must
discard the invalid received data.

Note that the nonce is included in the computation of the tag. A valid tag for a
given ciphertext and nonce will not verify with the same ciphertext, but a
different nonce.

## Additional data

As described above, the computation of an authentication tag can include
additional data. This is completely optional, and most applications don't need
to include any.

For a given key, nonce and message, the authentication tag will be different if
the additional data differs. The ciphertext will be the same, though. Additional
data are usually non-secret data.

How additional data are used is specific to every application and protocol, but
here are two sample use cases for them:

* **version identifiers:** using a version identifier as additional data allows
  the recipient of an encrypted message to check that the expected protocol
  version was used. If a valid secret key is used, but the version is not the
  one expected by the recipient, decryption will fail.

* **timestamps:** when using a datagram-based transport protocol such as UDP, a
  timestamp can be included in every datagram, so that the recipient can ignore
  datagrams that are too old or in the future. A timestamp is not secret data
  and doesn't have to be encrypted. Using the timestamp as additional data
  allows the recipient to confirm that a timestamp that appears to be valid
  hasn't been tampered with.

## Ordered and unordered messages

As described above, a simple way to ensure that a sequence of received messages
matches what the originator sent is to set the initial nonce to a given value,
and increment it after every message.

The originator only sends the initialization vector. Individual messages do not
contain a copy of the nonce used to encrypt them. They don't have to, since the
recipient can perform the same operation as the sender, namely increment the
nonce after every received encrypted message, in order to decrypt the stream.

If the stream being decrypted doesn't match the original stream, because
messages have been altered, removed, added, duplicated or reordered, the
authentication tag will not match the one computed by the recipient using the
expected nonce. This issue will be immediately detected by the decryption
function.

When using a transport protocol such as UDP, encrypted messages are not
guaranteed to be received in order. Some datagrams may also be missing or
duplicated. Applications must reorder them and handle retransmission.

In that situation, a copy of the nonce, or value representing the difference
with the initial nonce, can be added to every encrypted message. Since a message
is encrypted and authenticated using a unique nonce in addition to the key, the
decryption process will immediately detect a an encrypted message whose attached
nonce has been tampered with.

## Shared keys and repeated nonces

As previously stated, it is important to avoid using the same nonce to encrypt
different messages.

If two or more parties share the same secret key, increment the nonce after each
message, but use the same initialization vector, different messages may end up
being encrypted with the same nonce.

Each party can start with a different initialization vector and send it to its
peers, but a better approach is to simply use different keys. Even if `kAB` and
`kBA` are known by both parties, messages sent by `A` to `B` are encrypted using
the secret key `kAB`, whereas messages sent by `B` to `A` will be encrypted
using `kBA`.

The key exchange API (`crypto_kx()` functions) creates two different keys for
that purpose.

## Nonce-misuse resistance

Libsodium assumes a platform that can produce strong random numbers. On some
embedded systems, this may not be the case, and in such a scenario, having a
monotically increasing, global counter is rarely a practical solution either.

In that scenario, nonces can be constructed as follows: `Hk(message_counter||message)`,
with `message_counter` having a fixed length.

`Hk` is a keyed hash function safe against length-extension attacks,
such as the one provided by `crypto_generichash()`.

This assumes nonces that are 160-bit long or more, such as XChaCha20 and XSalsa20.

With ciphers featuring a shorter nonce size such as AES, the construction above
must be used to derive a subkey in addition to a nonce.

If a subkey is not computed, it is recommended to use a different key for hashing
and for encryption.

Using a key with the hash function is critical: an unkeyed hash function would
leak the hash of the message.

The security guarantees is weaker than when using a random initialization
vector. Namely, two sequences of messages sharing the same prefix will produce
the same encrypted stream prefix. Therefore, this scheme must only be used on
platforms that cannot produce secure random numbers. A sound alternative is to
use a library specifically designed for these platforms, such as
[libhydrogen](https://libhydrogen.org).

## Short nonces

Ciphers such as `AES` do not feature nonces large enough to be randomly chosen
without taking the risk of repeating a nonce.

More accurately, a single nonce shouldn't be used to encrypt different messages
with the same key. Using the same nonce to encrypt different messages with
different keys is perfectly safe.

Therefore, ciphers with short nonces can be safely used, but require keys to be
frequently rotated, in addition to generating a new key for every stream. This
requires support from application-level protocols, and can be tricky to
implement.

An alternative is to use a nonce extension mechanism. A large (160 bits or more)
nonce `N` is used by the protocol. Its initial value can be randomly chosen.

The actual encryption is done as follows:

* Using a pseudorandom function, a subkey and a shorter nonce are derived from
  the key and the large nonce
* The cipher is used with this subkey and short nonce to encrypt or decrypt a
  message

The following code snippet derives a 256-bit subkey and a 96-bit subnonce (these
parameters can be used with AES-256) from a 256-bit key and an arbitrary long
nonce:

```c
unsigned char  out[32 + 12];
unsigned char *subkey   = out;
unsigned char *subnonce = out + 32;
crypto_generichash(out, sizeof out, nonce, sizeof nonce, key, sizeof key);
```

Note that the security of the cipher is reduced to the one of the hash function.
This operation also implies a small performance hit, that becomes negligible as
the message size increases.

Unless a cipher such as `AES` is a requirement, using a cipher with a longer
nonce is easier and safer.

## Note

Please refer to the [main page on AEAD constructions](aead.md) for detailed
information about the limitations of each construction.
