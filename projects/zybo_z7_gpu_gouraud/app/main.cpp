#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <linux/i2c-dev.h>
#include "UioMmap.h"



void gpu_test(void *gpu_addr);


int SearchUioId(const char *name, int max_id=256)
{
	char	dev_fname[32];
	char	uio_name[64];
	FILE	*fp;
	
	for ( int i = 0; i < max_id; i++ ) {
		// read name
		sprintf(dev_fname, "/sys/class/uio/uio%d/name", i);
		if ( (fp = fopen(dev_fname, "r")) == NULL ) {
			return -1;
		}
		fgets(uio_name, 64, fp);
		fclose(fp);
		
		// chomp
		int len = strlen(uio_name);
		if ( len > 0 && uio_name[len-1] == '\n' ) {
			uio_name[len-1] = '\0';
		}
		
		// compare
		if ( strcmp(uio_name, name) == 0 ) {
			return i;
		}
	}
	
	return -1;
}


int main()
{
#if 0
	int i2c = open("/dev/i2c-0",O_RDWR);
	if ( i2c < 0 ) {
		printf("I2C open error\n");
		return 1;
	}
	printf("I2C:%d\n", i2c);
	
	ioctl(i2c, I2C_SLAVE, 0x68);
	
	uint8_t	buf[16];
	int ret = 0;
	buf[0] = 0x75;
    ret = write(i2c, buf, 1);
    printf("write:%d\n\r", ret);
	
	buf[0] = 0xff;
    ret = read(i2c, buf, 1);
    printf("read:%d\n\r", ret);
    
    printf("WHO_AM_I:0x%02x\n\r", buf[0]);
	close(i2c);
	return 0;
#endif	
	
#if 0
	int uio_id = SearchUioId("my_pl_peri");
	if ( uio_id < 0 ) {
		printf("UIO not found\n");
		return 1;
	}
	
	char	uio_dev_fname[32];
	sprintf(uio_dev_fname, "/dev/uio%d", uio_id);
	int fd;
	if ( (fd = open(uio_dev_fname, O_RDWR | O_SYNC)) < 0 ) {
		printf("UIO open error:%s\n", uio_dev_fname);
		return 1;
    }
	
	volatile uint32_t *map_addr;
	map_addr = (volatile uint32_t *)mmap(NULL, 0x00200000, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
	if ( map_addr == MAP_FAILED ) {
		printf("mmap error\n");
		return 1;
	}
	
//	for ( int i = 0; i < 16; i++ ) {
//		printf("%08x\n", map_addr[0x00100000/4 + i]);
//	}
#else
	UioMmap um_pl_peri("my_pl_peri", 0x00200000);
	volatile uint32_t *map_addr = (volatile uint32_t *)um_pl_peri.GetAddress();
#endif
	
	gpu_test((void*)&map_addr[0x00100000/4]);
	
	
	munmap((uint32_t*)map_addr, 0x0010000);
	close(fd);
	
	
	
	return 0;
}



