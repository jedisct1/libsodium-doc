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

The library is called `sodium` (use `-lsodium` to link it), and proper compilation/linker flags can be obtained using `pkg-config` on systems where it is available:

```sh
CFLAGS += $(pkg-config --cflags libsodium)
LDFLAGS += $$(pkg-config --libs-only-L libsodium)
LDLIBS += $$(pkg-config --libs-only-l libsodium)
```

For static linking, Visual Studio users should define `SODIUM_STATIC=1` and `SODIUM_EXPORT=`. This is not required on other platforms.

Projects using CMake can include the [Findsodium.cmake](https://github.com/facebookincubator/fizz/blob/master/build/fbcode_builder/CMake/FindSodium.cmake) file from the Facebook Fizz project to detect and link the library.

`sodium_init()` initializes the library and should be called before any other function provided by Sodium. It is safe to call this function more than once and from different threads – subsequent calls won't have any effects.

After this function returns, all of the other functions provided by Sodium will be thread-safe.

`sodium_init()` doesn't perform any memory allocations. However, on Unix systems, it may open `/dev/urandom` and keep the descriptor open so that the device remains accessible after a `chroot()` call.

Multiple calls to `sodium_init()` do not cause additional descriptors to be opened.

`sodium_init()` returns `0` on success, `-1` on failure, and `1` if the library had already been initialized.

Before returning, the function ensures that the system's random number generator has been properly seeded.

## sodium_init() stalling on Linux

On some Linux systems, this may take some time, especially when called right after a reboot of the system. This issue has been reported on Digital Ocean virtual machines, Scaleway ARM instances, and AWS Nitro Enclaves.

This can be confirmed with the following command:

```sh
cat /proc/sys/kernel/random/entropy_avail
```

If the command returns `0` or a very low number (\< `160`), and you are not running an obsolete kernel, this is very likely to be the case.

In a virtualized environment, make sure that the `virtio-rng` interface is available. If this is a cloud service and the hypervisor settings are out of your reach, consider switching to a different service.

Current Linux kernels (\>= 5.4) include the `haveged` algorithm in order to mitigate that problem. So, before trying the last-resort solutions below, try using a recent kernel.

If you have to use a kernel before version 5.4, a possible workaround is to install `haveged`:

```sh
apt-get install haveged
```

An alternative is `rng-tools`:

```sh
apt-get install rng-tools
```

In some environments, setting the `-O jitter:timeout` option to `20` [might be necessary](https://github.com/nhorman/rng-tools/issues/195#issuecomment-1519222464).

[Jitterentropy](https://github.com/smuellerDD/jitterentropy-rngd) is a better alternative, but most Linux distributions don't offer it as an installable package yet.

After installing these tools, check the value of `/proc/sys/kernel/random/entropy_avail` again.

On AWS Nitro Enclaves, workarounds include:

- Calling the `aws_nitro_enclaves_library_seed_entropy()` function before `sodium_init()`, and occasionally afterwards.
- Using the `RDSEED` CPU instruction to seed the kernel RNG (not recommended as a unique entropy source).
- Setting `random.trust_cpu=on` in the kernel command line (requires Linux kernel \> 4.19).

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
              "Upgrading the kernel, installing the rng-utils/rng-tools, jitterentropy-rngd or haveged packages may help.\n"
              "On virtualized Linux environments, also consider using virtio-rng.\n"
              "The service will not start until enough entropy has been collected.\n", stderr);
    }
    (void) close(fd);
}
#endif
```

Congrats, you're all set up!

A good documentation page to read next might be [Quickstart and FAQ](../quickstart/README.md).
