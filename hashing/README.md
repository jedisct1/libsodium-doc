# Hashing

*Hashing* refers to using a function that takes an input of any size and produces a fixed size output. Hashing the same input with the same function and parameters (e.g. output length) always produces the same output. This output is commonly known as a hash or digest.

Hashes are often used to check the integrity of data. For example, to detect whether a file has been modified or corrupted.

Not all hash functions are suitable for cryptography. Cryptographic hash functions have specific properties that make them secure. For instance, the output cannot be reversed to recover the input. Given an input, no one should be able to find a different input that hashes to the same output. Furthermore, no one should be able to produce two different inputs that hash to the same output.

Some cryptographic hash functions can also be used as Message Authentication Codes (MACs). These functions can take a message and secret key as input to produce a unique authentication tag that cannot be reproduced without the key. This operation is often called keyed hashing and is important for ensuring that data has not been tampered with.
