# Key derivation

## Deriving a key from a password

Secret keys used to encrypt or sign confidential data have to be chosen from a very large keyspace. However, passwords are usually short, human-generated strings, making dictionary attacks practical.

The `pwhash` operation derives a secret key of any size from a password and a salt.

See the __Password hashing__ section for more information and code examples.

## Deriving keys from a single high-entropy key

Multiple secret subkeys can be derived from a single master key.

Given the master key and a key identifier, a subkey can be deterministically computed. However, given a subkey, an attacker cannot compute the master key nor any other subkeys.

In order to do so, the Blake2 hash function is an efficient alternative to the HKDF contruction:

