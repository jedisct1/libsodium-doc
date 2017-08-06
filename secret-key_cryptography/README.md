# Secret-key cryptography

*Secret-key cryptography* refers to cryptographic system that uses the **same key** to encrypt and decrypt data.

This means that all parties involved have to know the key to be able to communicate securely – that is, decrypt encrypted messages to read them and encrypt messages they want to send.

Therefore the key, being *shared* among parties, but having to stay *secret* to 3rd parties – in order to keep communications private – is considered a *shared secret*.

Using secret-key cryptography, Alice and Bob would have to devise a **single** cryptographic key that they will **both** know and use each time they send each other a message.

Alice encrypts her message using this shared key, sends the *ciphertext* (the message, once encrypted) to Bob, then Bob uses the same key again to decrypt, ultimately reading the message.

An adversary cannot decrypt the message without knowing the secret key.

Such cryptographic system, requiring the key to be shared by both parties, is also known as *symmetric-key cryptography*.