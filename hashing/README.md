# Hashing

A **cryptographic hash function** is a one-way function that scrambles a message in such a way that
you always get the same output, but you can't recover the original message from that output.

Whether the input to a hash function is a single digit or a huge document, the output has a fixed
length. And regardless of the length of the input the output **varies chaotically**, so that the
hashes of similar inputs are wildly different.

Sodium uses two general-purpose hash algorithms:

- BLAKE2b, appropriate for most use cases (checking file integrity, creating unique identifiers for
  arbitrary payloads)
- SipHash-2-4, for faster hashing of short inputs (useful for hash tables, probabilistic structures
  such as Bloom filters, and integrity checking for short messages)

Neither of these should be used for [password hashing](/password_hashing) or for [key
derivation](/key_derivation); see the corresponding documentation for either of those specific use
cases.
