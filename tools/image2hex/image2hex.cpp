#include <stdio.h>
#include <string>
#include <opencv2/opencv.hpp>


int main(int argc, char *argv[])
{
	unsigned long	ulImageWidth   = 640;
	unsigned long	ulImageHeight  = 480;
	unsigned long	ulBlockWidth   = 8;
	unsigned long	ulBlockHeight  = 8;
	unsigned long	ulComponentNum = 3;
	unsigned long	ulStrideC      = 0;
	unsigned long	ulStrideX      = 0;
	unsigned long	ulStrideY      = 0;
	unsigned long	ulMemSize      = 0;
	unsigned long	ulBusSize      = 8;
	std::string		strImageFile;
	std::string		strHexFile;
	std::string		strFlatHexFile;

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
		else if ( strcmp(argv[i], "-c") == 0 && i+1 < argc ) {
			i++;	ulComponentNum = strtoul(argv[i], NULL, 0);
		}
		else if ( strcmp(argv[i], "-sc") == 0 && i+1 < argc ) {
			i++;	ulStrideC = strtoul(argv[i], NULL, 0);
		}
		else if (strcmp(argv[i], "-sx") == 0 && i + 1 < argc) {
			i++;	ulStrideX = strtoul(argv[i], NULL, 0);
		}
		else if (strcmp(argv[i], "-sy") == 0 && i + 1 < argc) {
			i++;	ulStrideY = strtoul(argv[i], NULL, 0);
		}
		else if (strcmp(argv[i], "-mem") == 0 && i + 1 < argc) {
			i++;	ulMemSize = strtoul(argv[i], NULL, 0);
		}
		else if ( strcmp(argv[i], "-bus") == 0 && i+1 < argc ) {
			i++;	ulBusSize = strtoul(argv[i], NULL, 0);
		}
		else if (strcmp(argv[i], "-img") == 0 && i + 1 < argc) {
			i++;	strImageFile = argv[i];
		}
		else if (strcmp(argv[i], "-flat") == 0 && i + 1 < argc) {
			i++;	strFlatHexFile = argv[i];
		}
		else {
			strHexFile = argv[i];
		}
	}

	if ( ulStrideC == 0 ) { ulStrideC = ulBlockWidth*ulBlockHeight; }
	if ( ulStrideX == 0 ) { ulStrideX = ulBlockWidth*ulBlockHeight*ulComponentNum; }
	if ( ulStrideY == 0 ) { ulStrideY = ulImageWidth*ulComponentNum*ulBlockHeight; }
	if ( ulMemSize == 0)  { ulMemSize = ulImageWidth*ulImageHeight*ulComponentNum; }
	
	printf("ImageWidt       : %lu\n", ulImageWidth);
	printf("ImageHeig       : %lu\n", ulImageHeight);
	printf("BlockWidt       : %lu\n", ulBlockWidth);
	printf("BlockHeight     : %lu\n", ulBlockHeight);
	printf("ComponentNum    : %lu\n", ulComponentNum);
	printf("ComponentStride : 0x%08lx\n", ulStrideC);
	printf("XStride         : 0x%08lx\n", ulStrideX);
	printf("YStride         : 0x%08lx\n", ulStrideY);
	printf("MemSize         : 0x%08lx\n", ulMemSize);
	printf("BusSize         : %lu\n", ulBusSize);
	printf("ImageFile       : %s\n", strImageFile.c_str());
	printf("OutputFile      : %s\n", strHexFile.c_str());

	cv::Mat img;
	if ( ulComponentNum == 1 ) {
		img = cv::imread(strImageFile, 0);	// モノクロ
	}
	else {
		img = cv::imread(strImageFile);		// カラー
		cv::cvtColor(img, img, CV_BGR2RGB);
	}
	if (img.empty()) {
		printf("file read error\n");
		return 1;
	}

	if ( img.size() != cv::Size(ulImageWidth, ulImageHeight) ) {
		printf("resize imege\n");
		cv::resize(img, img, cv::Size(ulImageWidth, ulImageHeight));
	}
	
	// フラットイメージ
	if (!strFlatHexFile.empty()) {
		FILE* fp;
		fopen_s(&fp, strFlatHexFile.c_str(), "w");
		for (int i = 0; i < (int)(img.cols*img.rows*ulComponentNum); i += ulBusSize){
			for (int j = ulBusSize - 1; j >= 0; j--){
				fprintf(fp, "%02x", img.data[i + j]);
			}
			fprintf(fp, "\n");
		}
	}

	// テクスチャキャッシュ用ブロックイメージ
	auto	ubBuf = new unsigned char[ulMemSize];
	memset(ubBuf, 0, ulMemSize);
	for (unsigned long y = 0; y < ulImageHeight; y += ulBlockHeight) {
		for (unsigned long x = 0; x < ulImageWidth; x += ulBlockWidth) {
			for (unsigned long c = 0; c < ulComponentNum; c++) {
				int pix = 0;
				for (unsigned long yy = 0; yy < ulBlockHeight; yy++) {
					for (unsigned long xx = 0; xx < ulBlockWidth; xx++) {
						unsigned long xxx = x + xx;
						unsigned long yyy = y + yy;
						uchar v;
						if (xxx < (unsigned long)img.cols && yyy < (unsigned long)img.rows) {
							if ( ulComponentNum == 1 ) {
								v = img.at<uchar>(yyy, xxx);
							}
							else {
								v = img.at<cv::Vec3b>(yyy, xxx)[c];
							}

							ubBuf[(y/ulBlockHeight)*ulStrideY + (x/ulBlockWidth)*ulStrideX + c*ulStrideC + pix] = v;
							pix++;
						}
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


