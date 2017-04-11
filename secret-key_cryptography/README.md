# Secret-key cryptography

*Secret-key cryptography* refers to cryptographic system that use the **same key** to encrypt and decrypt data. 

This means that all parties involved have to know the key to be able to communicate securely – that is, decrypt encrypted messages to read them and encrypt messages they want to send. Therefore the key, being *shared* among parties, but having to stay *secret* to 3rd parties – in order to keep communications private – is considered a *shared secret*. 

Here’s a example, using the common "Alice" & "Bob" characters : Alice & Bob, lovers, want to communicate securely and privately. Using secret-key cryptography, they first have to devise a **single** cryptographic key, that they will **both** know and use each time they send each other a message. Alice encrypts her message using this shared key, sends the the *ciphertext* (the message, once encrypted) to Bob, then Bob uses the same key again to decrypt, ultimately reading the message. But there is also a 3rd party, known as Eve – let's say she's Bob's jealous wife. She has noticed encrypted messages in her husband Bob's inbox, and she'd like to decrypt and read them. Except she can't without knowing the secret key, which is held only by Alice & Bob – so the lover's correspondence remains private. Thus, Alice and Bob can securely communicate using secret-key cryptography, without Eve being able to spy on them (as long as the secret key remains secret, obviously).

Such cryptographic systems, requiring the key to be shared by both parties, is also known as *symmetric-key cryptography*.
