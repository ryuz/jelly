#include <stdio.h>
#include <stdlib.h>




int main(int argc, char *argv[])
{
	if ( argc < 3 ) { return 1; }
	
	FILE* fpIn  = fopen(argv[1], "r");
	FILE* fpOut = fopen(argv[2], "w");
	if ( fpIn == NULL || fpOut == NULL ) { return 1; }
	
	
	static unsigned char	mem[0x100000];
	char					buf[64];
	long long				d;
	for ( int i = 0; i < 0x100000/8; i++ ) {
		fgets(buf, sizeof(buf), fpIn);
		d = 0;
		sscanf(buf, "%llx", &d);
		for ( int j = 0; j < 8; j++ ) {
			mem[i*8+j] = (d & 0xff);
			d >>= 8;
		}
	}
	
	FILE *fp = fopen("mem.bin", "wb");
	fwrite(mem, sizeof(mem), 1, fp);
	fclose(fp);
	
	fprintf(fpOut, "P3\n640 480\n255\n");
	for ( int y = 0; y < 480; y++ ) {
		for ( int x = 0; x < 640; x++ ) {
			int x0 = (x & 0x07);
			int x1 = (x >> 3);
			int y0 = (y & 0x07);
			int y1 = (y >> 3);
			int idx = (80*y1+x1)*64 + (y0 * 8 + x0);
			
			fprintf(fpOut, "%d %d %d\n", mem[idx], mem[0x50000 + idx], mem[0xa0000 + idx]);
		}
	}
	
	fclose(fpIn);
	fclose(fpOut);
	
	return 0;
}

