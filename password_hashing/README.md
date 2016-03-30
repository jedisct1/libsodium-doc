# Password hashing

Secret keys used to encrypt or sign confidential data have to be chosen from a very large keyspace.

However, passwords are usually short, human-generated strings, making dictionary attacks practical.

Password hashing functions derive a secret key of any size from a password and a salt.

- The generated key has the size defined by the application, no matter what the password length is.
- The same password hashed with same parameters will always produce the same key.
- The same password hashed with different salts will produce different keys.
- The function deriving a key from a password and a salt is CPU intensive and intentionally requires a fair amount of memory. Therefore, it mitigates brute-force attacks by requiring a significant effort to verify each password.

Common use cases:
- Protecting an on-disk secret key with a password,
- Password storage, or rather: storing what it takes to verify a password without having to store the actual password.
- Deriving a secret key from a password, for example for disk encryption.

Sodium's high-level `crypto_pwhash_*` API leverage the Argon2 function.

The more specific `crypto_pwhash_scryptsalsa208sha256_*` API uses the more conservative and widely deployed Scrypt function.

## Argon2

Argon2 is optimized for the x86 architecture and exploits the cache and memory organization of the recent Intel and AMD processors. Its implementation remains portable and fast on other architectures.

Argon2 has two variants: Argon2d and Argon2i. Argon2i uses data-independent memory access, which is preferred for password hashing and password-based key derivation. Argon2i also makes multiple passes over the memory to protect from tradeoff attacks.

This is the variant implemented in Sodium since version 1.0.9.

Argon2 is recommended over Scrypt if requiring libsodium >= 1.0.9 is not a concern.

## Scrypt

Scrypt was also designed to make it costly to perform large-scale custom hardware attacks by requiring large amounts of memory.

Even though its memory hardness can be significantly reduced at the cost of extra computations, this function remains an excellent choice today, provided that its parameters are properly chosen.

Scrypt is available in libsodium since version 0.5.0, which makes it a better choice than Argon2 if compatibility with older libsodium versions is a concern.
