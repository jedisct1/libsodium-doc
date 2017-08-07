# Usage

```c
#include <sodium.h>

int main(void)
{
    if (sodium_init() == -1) {
        return 1;
    }
    ...
}
```

`sodium.h` is the only header that has to be included.

The library is called `sodium` \(use `-lsodium` to link it\), and proper compilation/linker flags can be obtained using `pkg-config` on systems where it is available:

```bash
CFLAGS=$(pkg-config --cflags libsodium)
LDFLAGS=$(pkg-config --libs libsodium)
```

For static linking, Visual Studio users should define `SODIUM_STATIC=1` and `SODIUM_EXPORT=`. This is not required on other platforms.

Projects using CMake can include the [Findsodium.cmake](https://github.com/jedisct1/libsodium/blob/master/contrib/Findsodium.cmake) file in order to detect and link the library.

`sodium_init()` initializes the library and should be called before any other function provided by Sodium.  
The function can be called more than once, and can be called simultaneously from multiple threads since version 1.0.11.

After this function returns, all of the other functions provided by Sodium will be thread-safe.

`sodium_init()` doesn't perform any memory allocations. However, on Unix systems, it may open `/dev/urandom` and keep the descriptor open, so that the device remains accessible after a `chroot()` call.

Multiple calls to `sodium_init()` do not cause additional descriptors to be opened.

`sodium_init()` returns `0` on success, `-1` on failure, and `1` if the library had already been initialized.

Before returning, the function ensures that the system's random number generator has been properly seeded.

On some Linux systems, this may take some time, especially when called right after a reboot of the system. That issue has been reported on Digital Ocean virtual machines as well as on Scaleway ARM instances.

This can be confirmed with the following command:

```sh
cat /proc/sys/kernel/random/entropy_avail
```

If the command returns `0` or a very low number \(&lt; `160`\), and you are not running an obsolete kernel, this is very likely to be the case.

In a virtualized environment, make sure that the `virtio-rng` interface is available. If this is a cloud service and the hypervisor settings are out of your reach, consider switching to a difference service.

On a bare-metal host such as Scaleway instances, a possible workaround is to install the `rng-tools` package:

```sh
apt-get install rng-tools
```

And check the value of `/proc/sys/kernel/random/entropy_avail` again. If the value didn't go any higher, install `haveged`:

```sh
apt-get install haveged
```

Haveged should only be used as a very last resort. It hasn't received any updates for 10+ years, and shouldn't be trusted as a single entropy source, especially on virtualized environments.

[Jitterentropy](https://github.com/smuellerDD/jitterentropy-rngd) is a better alternative, but most Linux distributions don't offer it as an installable package yet.

Applications can warn users about the Linux RNG not being seeded before calling `sodium_init()` using code similar to the following:

```c
#if defined(__linux__)
# include <fcntl.h>
# include <unistd.h>
# include <sys/ioctl.h>
# include <linux/random.h>
#endif
// ...
#if defined(__linux__) && defined(RNDGETENTCNT)
int fd;
int c;

if ((fd = open("/dev/random", O_RDONLY)) != -1) {
    if (ioctl(fd, RNDGETENTCNT, &c) == 0 && c < 160) {
        fputs("This system doesn't provide enough entropy to quickly generate high-quality random numbers.\n"
              "Installing the rng-utils/rng-tools, jitterentropy or haveged packages may help.\n"
              "On virtualized Linux environments, also consider using virtio-rng.\n"
              "The service will not start until enough entropy has been collected.\n", stderr);
    }
    (void) close(fd);
}
#endif
```



