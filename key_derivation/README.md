# Key derivation

## Deriving a key from a password

Secret keys used to encrypt or sign confidential data have to be chosen from a very large keyspace. However, passwords are usually short, human-generated strings, making dictionary attacks practical.

The `pwhash` operation derives a secret key of any size from a password and a salt.

See the __Password hashing__ section for more information and code examples.

## Deriving keys from a single high-entropy key

Multiple secret subkeys can be derived from a single master key.

Given the master key and a key identifier, a subkey can be deterministically computed. However, given a subkey, an attacker cannot compute the master key nor any other subkeys.

In order to do so, the Blake2 hash function is an efficient alternative to the HKDF contruction:

```c
const unsigned char appid[crypto_generichash_blake2b_PERSONALBYTES] = {
    'A', ' ', 'S', 'i', 'm', 'p', 'l', 'e', ' ', 'E', 'x', 'a', 'm', 'p', 'l', 'e'
};
unsigned char keyid[crypto_generichash_blake2b_SALTBYTES] = {0};
unsigned char masterkey[64];
unsigned char subkey1[16];
unsigned char subkey2[32];

/* Generate a master key */
randombytes_buf(masterkey, sizeof masterkey);

/* Derive a first subkey (id=0) */
crypto_generichash_blake2b_salt_personal(subkey1, sizeof subkey1,
                                         NULL, 0,
                                         masterkey, sizeof masterkey,
                                         keyid, appid);

/* Derive a second subkey (id=1) */
sodium_increment(keyid, sizeof keyid);
crypto_generichash_blake2b_salt_personal(subkey2, sizeof subkey2,
                                         NULL, 0,
                                         masterkey, sizeof masterkey,
                                         keyid, appid);
```

The `crypto_generichash_blake2b_salt_personal()` function can be used to derive a subkey of any size from a key of any size, as long as these key sizes are in the 128 to 512 bits interval.

In this example, two subkeys are derived from a single key. These subkeys have different sizes (128 and 256 bits), and are derived from a master key of yet another size (512 bits).

The personalization parameter (`appid`) is a 16-bytes value that doesn't have to be secret. It can be used so that the same `(masterkey, keyid)` tuple will produce different output in different applications. It is not required, however: a `NULL` pointer can be passed instead in order to use the default constant.

The salt (`keyid`) doesn't have to be secret either. This is a 16-bytes identifier, that can be a simple counter, and is used to derive more than one key out of a single master key.

## Nonce extension

Unlike XSalsa20 (used by `crypto_box_*` and `crypto_secretbox_*`), ciphers such as AES-GCM and ChaCha20 require a nonce too short to be chosen randomly. With 96 bits random nonces, 2^32 encryptions is the limit before the probability of duplicate nonces becomes too high.

Using a counter instead of random nonces prevents this. However, keeping a state is not always an option, especially with offline protocols.

As an alternative, the nonce can be extended: a key and a part of a long nonce are used as inputs to a pseudorandom function to compute a new key. This subkey and the remaining bits of the long nonce can then be used as parameters for the cipher.

For example, this allows using a 192-bits nonce with a cipher requiring a 64-bits nonce:
```
k = <key>
n = <192-bit nonce>
k' = PRF(k, n[0..127])
c = E(k', n[128..191], m)
```

Since version 1.0.9, Sodium provides the `crypto_core_hchacha20()` function, which can be used as a PRF for that purpose:

```c
int crypto_core_hchacha20(unsigned char *out, const unsigned char *in,
                          const unsigned char *k, const unsigned char *c);
```

This function accepts a 32 bytes (`crypto_core_hchacha20_KEYBYTES`) secret key `k` as well as a 16 bytes (`crypto_core_hchacha20_INPUTBYTES`) input `in`, and outputs a 32 bytes (`crypto_core_hchacha20_OUTPUTBYTES`) value indistinguishable from random data without knowing `k`.

Optionally, a 16-bytes (`crypto_core_hchacha20_CONSTBYTES`) constant `c` can be specified to personalize the function to an application. `c` can be left to `NULL` in order to use the default constant.

The following code snippet case thus be used to construct a ChaCha20-Poly1305 variant with a 192-bits nonce:

```c
#define MESSAGE (const unsigned char *) "message"
#define MESSAGE_LEN 7

unsigned char c[crypto_aead_chacha20poly1305_ABYTES + MESSAGE_LEN];
unsigned char k[crypto_core_hchacha20_KEYBYTES];
unsigned char k2[crypto_core_hchacha20_OUTPUTBYTES];
unsigned char n[crypto_core_hchacha20_INPUTBYTES +
                crypto_aead_chacha20poly1305_NPUBBYTES];

randombytes_buf(k, sizeof k);
randombytes_buf(n, sizeof n); /* 192-bits nonce */

crypto_core_hchacha20(k2, n, k, NULL);

assert(crypto_aead_chacha20poly1305_KEYBYTES <= sizeof k2);
assert(crypto_aead_chacha20poly1305_NPUBBYTES ==
       (sizeof n) - crypto_core_hchacha20_INPUTBYTES);

crypto_aead_chacha20poly1305_encrypt(c, NULL, MESSAGE, MESSAGE_LEN,
                                     NULL, 0, NULL,
                                     n + crypto_core_hchacha20_INPUTBYTES,
                                     k2);
```

A higher-level API will be provided in a future revision of the library in order to abstract this.
