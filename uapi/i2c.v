module uapi

#include "linux/i2c-dev.h"
#include "linux/i2c.h"
#include <fcntl.h>

fn C.open(&char, u32) int
fn C.close(int)
fn C.ioctl(int, u32, int) int

pub struct I2c {
	fd      i32
	address u8
}

struct I2cMsg {
	addr  u16
	flags u16
	len   u16
	buf   &u8
}

struct I2cRdwrIoctlData {
	msgs  &I2cMsg
	nmsgs u32
}

pub fn I2c.new(path string, address u8) !I2c {
	fd := C.open(path.str, 2)
	if fd < 0 {
		return error('Failed to open I2C device')
	}

	if C.ioctl(fd, C.I2C_SLAVE, int(address)) < 0 {
		C.close(fd)
		return error('Failed to set I2C slave address')
	}

	return I2c{
		fd:      fd
		address: address
	}
}

pub fn (device I2c) write(data []u8) ! {
	msg := I2cMsg{
		addr:  device.address
		flags: 0
		len:   u16(data.len)
		buf:   data.data
	}

	ioctl_data := I2cRdwrIoctlData{
		msgs:  &msg
		nmsgs: 1
	}

	if C.ioctl(device.fd, C.I2C_RDWR, voidptr(&ioctl_data)) < 0 {
		return error('Erro na transação I2C via ioctl')
	}
}

pub fn (device I2c) read(buffer []u8) ![]u8 {
	msg := I2cMsg{
		addr:  device.address
		flags: u16(C.I2C_M_RD)
		len:   u16(buffer.len)
		buf:   buffer.data
	}

	ioctl_data := I2cRdwrIoctlData{
		msgs:  &msg
		nmsgs: 1
	}

	if C.ioctl(device.fd, C.I2C_RDWR, voidptr(&ioctl_data)) < 0 {
		return error('Erro na transação I2C via ioctl')
	}

	return buffer
}

pub fn (device I2c) close() {
	C.close(device.fd)
}
