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
In this example, two subkeys are derived from a single key. These subkeys have different sizes (128 and 256 bits), and are derived from a master key of yet another size (512 bits).

The `crypto_generichash_blake2b_salt_personal()` function can be used to derive a subkey of any size from a key of any size, as long as these key sizes are in the 128 to 512 bits interval.

The personalization parameter (`appid`) is a 16-bytes value that doesn't have to be secret. It can be used so that the same `(masterkey, keyid)` tuple will produce different output in different applications. It is not required, however: a `NULL` pointer can be passed instead in order to use the default constant.

The salt (`keyid`) doesn't have to be secret either. This is a 16-bytes identifier, that can be a simple counter, and is used to derive more than one key out of a single master key.



