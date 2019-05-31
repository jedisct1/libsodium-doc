# The Sodium crypto library \(libsodium\)

Sodium is a modern, easy-to-use software library for encryption, decryption,
signatures, password hashing and more.

It is a portable, cross-compilable, installable, packageable fork of
[NaCl](http://nacl.cr.yp.to/), with a compatible API, and an extended API to
improve usability even further.

Its goal is to provide all of the core operations needed to build higher-level
cryptographic tools.

Sodium is cross-platforms and cross-languages. It runs on a variety of compilers
and operating systems, including Windows \(with MinGW or Visual Studio, x86 and
x86_64\), iOS and Android. Javascript and WebAssembly versions are also
available and are fully supported. Bindings for all common programming languages
are available and well-supported.

The design choices emphasize security and ease of use. But despite the emphasis
on high security, primitives are faster across-the-board than most
implementations.

[Version 1.0.18](https://github.com/jedisct1/libsodium/releases) was released on
May 31, 2019.

## Downloading libsodium

* [Github repository](https://github.com/jedisct1/libsodium)
* [Tarballs and pre-compiled binaries](https://download.libsodium.org/libsodium/releases/)
* [Documentation](https://doc.libsodium.org)

## Mailing list

A mailing-list is available to discuss libsodium.

In order to join, just send a random mail to `sodium-subscribe` {at}
`pureftpd`{dot}`org`.

## Offline documentation

This documentation can be downloaded as a PDF file here:
[https://www.gitbook.com/book/jedisct1/libsodium/details](https://www.gitbook.com/book/jedisct1/libsodium/details)

## License

[ISC license](https://en.wikipedia.org/wiki/ISC_license).

See the `LICENSE` file for details.

## Thanks!

The development of libsodium is entirely made by volunteers. We would like to
specially thank the following companies and organizations for their
contribution:

* [Paragonie Initiative Enterprise](https://paragonie.com/), who donated a Raspberry Pi to ensure that the library works perfectly on this hardware.
  Thanks!
* [Private Internet Access](https://www.privateinternetaccess.com), who sponsored a [complete security audit](https://www.privateinternetaccess.com/blog/2017/08/libsodium-audit-results).
  This is amazing, thanks!
* [Maximilian Blochberger](https://github.com/blochberger) and Joshua Small, who both generously donated $100. This will help a lot to cover the infrastructure costs. Thanks again, Max and Joshua!

People who designed the primitives and wrote implementations the library is
based on can be found in the
[AUTHORS](https://raw.githubusercontent.com/jedisct1/libsodium/master/AUTHORS)
file. This project wouldn't exist without them.

Also a huge "thank you" to people and companies who contributed bindings for
their favorite programming languages. A list can be found in the
[THANKS](https://raw.githubusercontent.com/jedisct1/libsodium/master/THANKS)
file.

Another huge "thank you" to package maintainers who have been doing an amazing
job at building packages for many distributions and operating systems.

Finally, thanks to **you** for reading this documentation and for the awesome
projects you are going to build with this library!
