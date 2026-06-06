# ENABLE_I2C.md

# Enabling I²C1 on Orange Pi Zero 2W (Arch Linux + Armbian Kernel)

This guide explains how to enable the **I²C1** bus on the **Orange Pi Zero 2W** using Arch Linux with the Armbian kernel.

The I²C1 bus is exposed on the 40-pin header:

| Signal | Physical Pin |
|----------|--------------|
| SDA.1 | Pin 3 |
| SCL.1 | Pin 5 |

---

## Verify the Board

Check that the system is running on an Orange Pi Zero 2W:

```bash
cat /proc/device-tree/model
```

Expected output:

```text
OrangePi Zero 2W
```

---

## Edit the Boot Configuration

Open the boot configuration file:

```bash
sudo nano /boot/bootEnv.txt
```

Locate the `overlays=` line.

If you currently have:

```ini
overlays=spi-spidev i2c2-pi
```

Replace it with:

```ini
overlays=spi-spidev i2c1-pi
```

If you have other overlays enabled, simply add `i2c1-pi` to the list:

```ini
overlays=spi-spidev i2c1-pi
```

Save the file and exit.

---

## Reboot

Apply the changes by rebooting:

```bash
sudo reboot
```

---

## Verify that I²C is Available

After rebooting, check for I²C devices:

```bash
ls /dev/i2c-*
```

Example output:

```text
/dev/i2c-0
/dev/i2c-1
/dev/i2c-2
```

List all detected I²C adapters:

```bash
i2cdetect -l
```

---

## Install I²C Utilities

If the tools are not installed:

```bash
sudo pacman -S i2c-tools
```

---

## Scan for Connected Devices

Scan the available buses:

```bash
sudo i2cdetect -y 0
sudo i2cdetect -y 1
sudo i2cdetect -y 2
```

A typical OLED display (SSD1306 or CH1116) usually appears at:

```text
0x3C
```

or

```text
0x3D
```

Example:

```text
30: -- -- -- -- -- -- 3c -- -- -- -- -- -- -- -- --
```

---

## Determine Which Linux Bus Corresponds to I²C1

To see how Linux mapped the hardware controllers:

```bash
for i in /sys/class/i2c-dev/i2c-*; do
    echo "$i"
    readlink -f "$i/device"
done
```

This helps identify which `/dev/i2c-X` device corresponds to the physical I²C1 bus.

---

## I²C1 Header Pinout

| Signal | GPIO | Physical Pin |
|----------|----------|--------------|
| SDA.1 | GPIO264 | 3 |
| SCL.1 | GPIO263 | 5 |
| 3.3V | - | 1 |
| GND | - | 6 |

---

## Typical OLED Wiring

| OLED Module | Orange Pi Zero 2W |
|------------|-------------------|
| VCC | Pin 1 (3.3V) |
| GND | Pin 6 (GND) |
| SDA | Pin 3 (SDA.1) |
| SCL | Pin 5 (SCL.1) |

---

## Simple C Test Program

```c
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>

int main(void)
{
    int fd = open("/dev/i2c-1", O_RDWR);

    if (fd < 0)
    {
        perror("open");
        return 1;
    }

    printf("I2C opened successfully!\n");

    close(fd);
    return 0;
}
```

Compile and run:

```bash
gcc test.c -o test
./test
```

---

## Troubleshooting

Check kernel messages related to I²C:

```bash
dmesg | grep -i i2c
```

Verify that the overlay was loaded:

```bash
strings /sys/firmware/fdt | grep i2c
```

Check available overlays:

```bash
ls /boot/dtb/allwinner/overlay/ | grep i2c
```

---

## Summary

- I²C1 uses **Pin 3 (SDA)** and **Pin 5 (SCL)**.
- Enable it by adding:

```ini
overlays=i2c1-pi
```

to `/boot/bootEnv.txt`.
- Reboot the system.
- Use `i2cdetect` to verify communication with connected devices.
- Common OLED addresses are **0x3C** and **0x3D**.
