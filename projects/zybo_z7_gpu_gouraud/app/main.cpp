#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <errno.h>


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
	map_addr = (volatile uint32_t *)mmap((void*)0x00100000, 0x1000, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
	if ( map_addr == MAP_FAILED ) {
		printf("mmap error\n");
		return 1;
	}
	
	for ( int i = 0; i < 16; i++ ) {
		printf("%08x\n", map_addr[0x20+i]);
	}
	
	munmap((void*)map_addr, 0x1000);
	close(fd);
	
	return 0;
}



