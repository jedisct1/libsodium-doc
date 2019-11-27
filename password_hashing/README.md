# Password hashing

Secret keys used to encrypt or sign confidential data have to be chosen from a very large keyspace.

However, passwords are usually short, human-generated strings, making dictionary attacks practical.

Password hashing functions derive a secret key of any size from a password and a salt.

* The generated key has the size defined by the application, no matter what the password length is.
* The same password hashed with same parameters will always produce the same output.
* The same password hashed with different salts will produce different outputs.
* The function deriving a key from a password and a salt is CPU intensive and intentionally requires a fair amount of memory. Therefore, it mitigates brute-force attacks by requiring a significant effort to verify each password.

Common use cases:

* Password storage, or rather: storing what it takes to verify a password
without having to store the actual password.
* Deriving a secret key from a password, for example for disk encryption.

Sodium's high-level `crypto_pwhash_*` API currently leverages the Argon2id function on all platforms. This can change at any point in time, but it is guaranteed that a given version of libsodium can verify all hashes produced by all previous versions, from any platform. Applications don't have to worry about backward compatibility.

The more specific `crypto_pwhash_scryptsalsa208sha256_*` API uses the more conservative and widely deployed Scrypt function.

## Argon2

Argon2 is optimized for the x86 architecture and exploits the cache and memory organization of the recent Intel and AMD processors. But its implementation remains portable and fast on other architectures, with the exception of JavaScript.

Argon2 has three variants: Argon2d, Argon2i and Argon2id. Libsodium supports Argon2i and Argon2id.

## Scrypt

Scrypt was also designed to make it costly to perform large-scale custom hardware attacks by requiring large amounts of memory.

Even though its memory hardness can be significantly reduced at the cost of extra computations, this function remains an excellent choice today, provided that its parameters are properly chosen.

## Server relief

If multiple clients can simultaneously log in on a shared server, the memory and computation requirements can exhaust the server's resources.

In order to mitigate this, passwords can be pre-hashed on the client (e.g. using libsodium.js in a web application):

* On user account creation, the server sends a random seed to the client. The client computes `ph = password_hash(password, seed)` and sends `ph` to the server. `password_hash` is a password hashing function tuned for the maximum memory and CPU usage the client can handle. The server stores the seed and `password_hash'(ph, seed)` for this user account. `password_hash'` is a password hashing function, whose parameters can be tuned for low memory and
CPU usage.
* On a login attempt, the server sends the seed, or, for a nonexistent user, a pseudorandom seed that has to always be the same for a given user name (for example using `crypto_generichash()`, with a key, and the user name as the
message). The client computes `ph = password_hash(password, seed)` and sends it to the server. The server computes `password_hash'(ph, seed)` and compares it against what was stored in the database.
