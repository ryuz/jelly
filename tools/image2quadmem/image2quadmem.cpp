#include <stdio.h>
#include <string>
#include <opencv2/opencv.hpp>


int main(int argc, char *argv[])
{
	unsigned long	ulImageWidth   = 256;
	unsigned long	ulImageHeight  = 256;
	std::string		strImageFile;
	std::string		strHexFile;

	for ( int i = 1; i < argc; i++ ) {
		if ( strcmp(argv[i], "-w") == 0 && i+1 < argc ) {
			i++;	ulImageWidth  = strtoul(argv[i], NULL, 0);
		}
		else if ( strcmp(argv[i], "-h") == 0 && i+1 < argc ) {
			i++;	ulImageHeight = strtoul(argv[i], NULL, 0);
		}
		else if (strcmp(argv[i], "-img") == 0 && i + 1 < argc) {
			i++;	strImageFile = argv[i];
		}
		else {
			strHexFile = argv[i];
		}
	}
	
	printf("ImageWidt       : %lu\n", ulImageWidth);
	printf("ImageHeig       : %lu\n", ulImageHeight);
	printf("ImageFile       : %s\n", strImageFile.c_str());
	printf("OutputFile      : %s\n", strHexFile.c_str());

	// “Ç‚Ýž‚Ý
	cv::Mat img = cv::imread(strImageFile);
	cv::cvtColor(img, img, CV_BGR2RGB);
	if (img.empty()) {
		printf("file read error\n");
		return 1;
	}

	if ( img.size() != cv::Size(ulImageWidth, ulImageHeight) ) {
		printf("resize imege\n");
		cv::resize(img, img, cv::Size(ulImageWidth, ulImageHeight));
	}
	

	FILE*	fp[4];
	char	filename[256];
	for ( int i = 0; i < 4; i++ ) {
		sprintf_s<256>(filename, "%s%d.hex", strHexFile.c_str(), i);
		fopen_s(&fp[i], filename, "w");
	}

	for ( int y = 0; y < img.rows; y++ ) {
		for ( int x = 0; x < img.cols; x++ ) {
			auto col = img.at<cv::Vec3b>(y, x);
			int i = y%2*2 + x%2;
			fprintf_s(fp[i], "%02x%02x%02x\n", col[2], col[1], col[0]);
		}
	}

	for ( int i = 0; i < 4; i++ ) {
		fclose(fp[i]);
	}
	
	return 0;
}


