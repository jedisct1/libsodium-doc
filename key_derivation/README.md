# Key derivation

## Deriving a key from a password

Secret keys used to encrypt or sign confidential data have to be chosen from a very large keyspace. However, passwords are usually short, human-generated strings, making dictionary attacks practical.

The `pwhash` operation derives a secret key of any size from a password and a salt.

See the **Password hashing** section for more information and code examples.

## Deriving keys from a single high-entropy key

Multiple secret subkeys can be derived from a single master key.

Given the master key and a key identifier, a subkey can be deterministically computed. However, given a subkey, an attacker cannot compute the master key nor any other subkeys.

### Key derivation with libsodium &gt;= 1.0.12

Recent versions of the library have a dedicated API for key derivation.

The `crypto_kdf` API can derive up to 2^64 keys from a single master key and context, and individual subkeys can have an arbitrary length between 128 \(16 bytes\) and 512 bits \(64 bytes\).

Example:

```c
#define CONTEXT "Examples"

uint8_t master_key[crypto_kdf_KEYBYTES];
uint8_t subkey1[32];
uint8_t subkey2[32];
uint8_t subkey3[64];

crypto_kdf_keygen(master_key);

crypto_kdf_derive_from_key(subkey1, sizeof subkey1, 1, CONTEXT, master_key);
crypto_kdf_derive_from_key(subkey2, sizeof subkey2, 2, CONTEXT, master_key);
crypto_kdf_derive_from_key(subkey3, sizeof subkey3, 3, CONTEXT, master_key);
```

Usage:

```c
void crypto_kdf_keygen(uint8_t key[crypto_kdf_KEYBYTES]);
```

The `crypto_kdf_keygen()` function creates a master key.

```c
int crypto_kdf_derive_from_key(unsigned char *subkey, size_t subkey_len,
                               uint64_t subkey_id,
                               const char ctx[crypto_kdf_CONTEXTBYTES],
                               const unsigned char key[crypto_kdf_KEYBYTES]);
```

The `crypto_kdf_derive_from_key()` function derives a `subkey_id`-th subkey `subkey` of length `subkey_len` bytes using the master key `key` and the context `ctx`.

`subkey_id` can be any value up to `(2^64)-1`.

`subkey_len` has to be between `crypto_kdf_BYTES_MIN` \(inclusive\) and `crypto_kdf_BYTES_MAX` \(inclusive\).

Similar to a type, the context `ctx` is a 8 characters string describing what the key is going to be used for.

Its purpose is to mitigate accidental bugs by separating domains.  
The same function used with the same key but in two distinct contexts is likely to generate two different outputs.

Contexts don't have to be secret and can have a low entropy.

Examples of contexts include `UserName`, `__auth__`, `pictures` and `userdata`.

If more convenient, it is also fine to use a single global context for a whole application.  
This will still prevent the same keys from being mistakenly used by another application.

Constants:

* `crypto_kdf_PRIMITIVE`
* `crypto_kdf_BYTES_MIN`
* `crypto_kdf_BYTES_MAX`
* `crypto_kdf_CONTEXTBYTES`
* `crypto_kdf_KEYBYTES`

Algorithm details:

`BLAKE2B-subkeylen(key=key, message={}, salt=subkey_id || {0}, personal=ctx || {0})`

### Key derivation with libsodium &lt; 1.0.12

On older versions of the library, the BLAKE2 function can be used directly:

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

In this example, two subkeys are derived from a single key. These subkeys have different sizes \(128 and 256 bits\), and are derived from a master key of yet another size \(512 bits\).

The personalization parameter \(`appid`\) is a 16-bytes value that doesn't have to be secret. It can be used so that the same `(masterkey, keyid)` tuple will produce different output in different applications. It is not required, however: a `NULL` pointer can be passed instead in order to use the default constant.

The salt \(`keyid`\) doesn't have to be secret either. This is a 16-bytes identifier, that can be a simple counter, and is used to derive more than one key out of a single master key.

## Nonce extension

Unlike XSalsa20 \(used by `crypto_box_*` and `crypto_secretbox_*`\) and XChaCha20, ciphers such as AES-GCM and ChaCha20 require a nonce too short to be chosen randomly \(64 or 96 bits\). With 96 bits random nonces, 2^32 encryptions is the limit before the probability of duplicate nonces becomes too high.

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

This function accepts a 32 bytes \(`crypto_core_hchacha20_KEYBYTES`\) secret key `k` as well as a 16 bytes \(`crypto_core_hchacha20_INPUTBYTES`\) input `in`, and outputs a 32 bytes \(`crypto_core_hchacha20_OUTPUTBYTES`\) value indistinguishable from random data without knowing `k`.

Optionally, a 16-bytes \(`crypto_core_hchacha20_CONSTBYTES`\) constant `c` can be specified to personalize the function to an application. `c` can be left to `NULL` in order to use the default constant.

The following code snippet case thus be used to construct a ChaCha20-Poly1305 variant with a 192-bits nonce \(XChaCha20\) on libsodium &lt; 1.0.12 \(versions &gt;= 1.0.12 already include this construction\).

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



