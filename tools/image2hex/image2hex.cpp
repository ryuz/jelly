#include <stdio.h>
#include <string>
#include <opencv2/opencv.hpp>


int main(int argc, char *argv[])
{
	unsigned long	ulImageWidth  = 640;
	unsigned long	ulImageHeight = 480;
	unsigned long	ulBlockWidth  = 8;
	unsigned long	ulBlockHeight = 8;
	unsigned long	ulPlaneSize   = 0x050000;
	unsigned long	ulMemSize     = 0x100000;
	unsigned long	ulBusSize     = 8;
	std::string		strImageFile;
	std::string		strHexFile;

	for ( int i = 1; i < argc; i++ ) {
		if ( strcmp(argv[i], "-w") == 0 && i+1 < argc ) {
			i++;	ulImageWidth  = strtoul(argv[i], NULL, 0);
		}
		else if ( strcmp(argv[i], "-h") == 0 && i+1 < argc ) {
			i++;	ulImageHeight = strtoul(argv[i], NULL, 0);
		}
		else if ( strcmp(argv[i], "-bw") == 0 && i+1 < argc ) {
			i++;	ulBlockWidth = strtoul(argv[i], NULL, 0);
		}
		else if ( strcmp(argv[i], "-bh") == 0 && i+1 < argc ) {
			i++;	ulBlockHeight = strtoul(argv[i], NULL, 0);
		}
		else if ( strcmp(argv[i], "-plane") == 0 && i+1 < argc ) {
			i++;	ulPlaneSize = strtoul(argv[i], NULL, 0);
		}
		else if ( strcmp(argv[i], "-mem") == 0 && i+1 < argc ) {
			i++;	ulMemSize = strtoul(argv[i], NULL, 0);
		}
		else if ( strcmp(argv[i], "-bus") == 0 && i+1 < argc ) {
			i++;	ulBusSize = strtoul(argv[i], NULL, 0);
		}
		else if (strcmp(argv[i], "-img") == 0 && i + 1 < argc) {
			i++;	strImageFile = argv[i];
		}
		else {
			strHexFile = argv[i];
		}
	}
	
	printf("ImageWidt   : %d\n", ulImageWidth);
	printf("ImageHeig   : %d\n", ulImageHeight);
	printf("BlockWidt   : %d\n", ulBlockWidth);
	printf("BlockHeight : %d\n", ulBlockHeight);
	printf("PlaneSize   : 0x%x\n", ulPlaneSize);
	printf("MemSize     : 0x%x\n", ulMemSize);
	printf("BusSize     : %d\n", ulBusSize);
	printf("ImageFile   : %s\n", strImageFile.c_str());
	printf("OutputFile  : %s\n", strHexFile.c_str());

	cv::Mat img = cv::imread(strImageFile);
	if (img.empty()) {
		printf("file read error\n");
		return 1;
	}

	cv::resize(img, img, cv::Size(ulImageWidth, ulImageHeight));
	

	auto	ubBuf = new unsigned char[ulMemSize];
	for (int i = 0; i < 3; i++) {
		auto p = &ubBuf[i*ulPlaneSize];
		for (unsigned long y = 0; y < ulImageHeight; y += ulBlockHeight) {
			for (unsigned long x = 0; x < ulImageWidth; x += ulBlockWidth) {

				for (unsigned long yy = 0; yy < ulBlockHeight; yy++) {
					for (unsigned long xx = 0; xx < ulBlockWidth; xx++) {
						unsigned long xxx = x + xx;
						unsigned long yyy = y + yy;
						cv::Vec3b v;
						if (xxx < (unsigned long)img.cols && yyy < (unsigned long)img.rows) {
							v = img.at<cv::Vec3b>(yyy, xxx);
						}
						*p++ = v[i];
					}
				}
			}
		}
	}

	FILE* fp;
	fopen_s(&fp, strHexFile.c_str(), "w");

	for (int i = 0; i < (int)ulMemSize; i += ulBusSize){
		for ( int j = ulBusSize - 1; j >= 0; j--){
			fprintf(fp, "%02x", ubBuf[i + j]);
		}
		fprintf(fp, "\n");
	}

	fclose(fp);
	
	delete[] ubBuf;

	return 0;
}


