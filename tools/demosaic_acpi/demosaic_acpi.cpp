#include <stdio.h>
#include <string>
#include <algorithm>
#include <opencv2/opencv.hpp>




inline int GetPixel(const cv::Mat& img, int x, int y)
{
	if (x < 0) { x = -x; }
	if (y < 0) { y = -y; }
	if (x >= img.cols) { x = (img.cols - 1) - (x - (img.cols - 1)); }
	if (y >= img.rows) { y = (img.rows - 1) - (y - (img.rows - 1)); }
	
	return img.at<short>(y, x);
}



int main(int argc, char *argv[])
{
	cv::Mat imgSrc = cv::imread("caputure_img.pgm", 0);
	cv::imshow("imgSrc", imgSrc);
	
	cv::Mat imgRaw;
	imgSrc.convertTo(imgRaw, CV_16S);
	imgRaw *= 4;

	cv::Mat imgTmpG(imgSrc.size(), CV_16S);
	cv::Mat imgTmpX(imgSrc.size(), CV_16S);
	cv::Mat imgTmpV(imgSrc.size(), CV_16S);
	cv::Mat imgTmpH(imgSrc.size(), CV_16S);

	cv::Mat imgR(imgSrc.size(), CV_16S);
	cv::Mat imgG(imgSrc.size(), CV_16S);
	cv::Mat imgB(imgSrc.size(), CV_16S);
	cv::Mat imgRgb(imgSrc.size(), CV_8UC3);

	int pix = 0;
	for (int y = 0; y < imgRaw.rows; y++) {
		for (int x = 0; x < imgRaw.cols; x++) {
			int raw11 = GetPixel(imgRaw, x - 2, y - 2);
			int raw12 = GetPixel(imgRaw, x - 1, y - 2);
			int raw13 = GetPixel(imgRaw, x + 0, y - 2);
			int raw14 = GetPixel(imgRaw, x + 1, y - 2);
			int raw15 = GetPixel(imgRaw, x + 2, y - 2);
			int raw21 = GetPixel(imgRaw, x - 2, y - 1);
			int raw22 = GetPixel(imgRaw, x - 1, y - 1);
			int raw23 = GetPixel(imgRaw, x + 0, y - 1);
			int raw24 = GetPixel(imgRaw, x + 1, y - 1);
			int raw25 = GetPixel(imgRaw, x + 2, y - 1);
			int raw31 = GetPixel(imgRaw, x - 2, y + 0);
			int raw32 = GetPixel(imgRaw, x - 1, y + 0);
			int raw33 = GetPixel(imgRaw, x + 0, y + 0);
			int raw34 = GetPixel(imgRaw, x + 1, y + 0);
			int raw35 = GetPixel(imgRaw, x + 2, y + 0);
			int raw41 = GetPixel(imgRaw, x - 2, y + 1);
			int raw42 = GetPixel(imgRaw, x - 1, y + 1);
			int raw43 = GetPixel(imgRaw, x + 0, y + 1);
			int raw44 = GetPixel(imgRaw, x + 1, y + 1);
			int raw45 = GetPixel(imgRaw, x + 2, y + 1);
			int raw51 = GetPixel(imgRaw, x - 2, y + 2);
			int raw52 = GetPixel(imgRaw, x - 1, y + 2);
			int raw53 = GetPixel(imgRaw, x + 0, y + 2);
			int raw54 = GetPixel(imgRaw, x + 1, y + 2);
			int raw55 = GetPixel(imgRaw, x + 2, y + 2);

			int alpha = abs(-raw13 + 2 * raw33 - raw53) + abs(raw23 - raw43);
			int beta = abs(-raw31 + 2 * raw33 - raw35) + abs(raw32 - raw34);

			int v = (raw23 + raw43) * 2 + (-raw13 + 2 * raw33 - raw53);
			int h = (raw32 + raw34) * 2 + (-raw31 + 2 * raw33 - raw35);

			int tmp_g = 0;
			if (alpha < beta) {
				tmp_g = ((raw23 + raw43) * 2 + (-raw13 + 2 * raw33 - raw53)) / 4;
			}
			else if (alpha > beta) {
				tmp_g = ((raw32 + raw34) * 2 + (-raw31 + 2 * raw33 - raw35)) / 4;
			}
			else {
				tmp_g = ((raw23 + raw43 + raw32 + raw34) * 2 + (-raw13 - raw31 + 4 * raw33 - raw53 - raw35)) / 8;
			}

			imgTmpG.at<short>(y, x) = std::min(std::max(tmp_g, 0), 1023);

			// debug
			if (pix == 326) {
				printf("%d\n", tmp_g);
			}
			pix++;
		}
	}

	pix = 0;
	for (int y = 0; y < imgRaw.rows; y++) {
		for (int x = 0; x < imgRaw.cols; x++) {
			int raw11 = GetPixel(imgRaw, x - 1, y - 1);
			int raw12 = GetPixel(imgRaw, x + 0, y - 1);
			int raw13 = GetPixel(imgRaw, x + 1, y - 1);
			int raw21 = GetPixel(imgRaw, x - 1, y + 0);
			int raw22 = GetPixel(imgRaw, x + 0, y + 0);
			int raw23 = GetPixel(imgRaw, x + 1, y + 0);
			int raw31 = GetPixel(imgRaw, x - 1, y + 1);
			int raw32 = GetPixel(imgRaw, x + 0, y + 1);
			int raw33 = GetPixel(imgRaw, x + 1, y + 1);

			int tg11 = GetPixel(imgTmpG, x - 1, y - 1);
			int tg12 = GetPixel(imgTmpG, x + 0, y - 1);
			int tg13 = GetPixel(imgTmpG, x + 1, y - 1);
			int tg21 = GetPixel(imgTmpG, x - 1, y + 0);
			int tg22 = GetPixel(imgTmpG, x + 0, y + 0);
			int tg23 = GetPixel(imgTmpG, x + 1, y + 0);
			int tg31 = GetPixel(imgTmpG, x - 1, y + 1);
			int tg32 = GetPixel(imgTmpG, x + 0, y + 1);
			int tg33 = GetPixel(imgTmpG, x + 1, y + 1);

			int alpha = abs(-tg13 + 2 * tg22 - tg31) + abs(raw13 - raw31);
			int beta = abs(-tg11 + 2 * tg22 - tg33) + abs(raw11 - raw33);

			int tmpX;
			int tmpH;
			int tmpV;

			int tmpL = ((raw11 + raw33) * 2 + (-tg11 + 2 * tg22 - tg33));
			int tmpR = ((raw13 + raw31) * 2 + (-tg13 + 2 * tg22 - tg31));

			if (alpha < beta) {
				tmpX = ((raw13 + raw31) * 2 + (-tg13 + 2 * tg22 - tg31)) * 2;
			}
			else if (alpha > beta) {
				tmpX = ((raw11 + raw33) * 2 + (-tg11 + 2 * tg22 - tg33)) * 2;
			}
			else {
				tmpX = ((raw13 + raw31 + raw11 + raw33) * 2 + (-tg13 - tg11 + 4 * tg22 - tg31 - tg33));
			}

			tmpH = ((raw21 + raw23) * 2 + (-tg21 + 2 * tg22 - tg23));
			tmpV = ((raw12 + raw32) * 2 + (-tg12 + 2 * tg22 - tg32));

			int X = tmpX / 8;
			int H = tmpH / 4;
			int V = tmpV / 4;

			imgTmpX.at<short>(y, x) = tmpX / 8;
			imgTmpH.at<short>(y, x) = tmpH / 4;
			imgTmpV.at<short>(y, x) = tmpV / 4;

			int R, G, B;
			int phase = ((y % 2) << 1) + (x % 2);
			switch (phase ^ 3) {
			case 0:
				R = imgRaw.at<short>(y, x);
				G = imgTmpG.at<short>(y, x);
				B = imgTmpX.at<short>(y, x);
				break;

			case 1:
				R = imgTmpH.at<short>(y, x);
				G = imgRaw.at<short>(y, x);
				B = imgTmpV.at<short>(y, x);
				break;

			case 2:
				R = imgTmpV.at<short>(y, x);
				G = imgRaw.at<short>(y, x);
				B = imgTmpH.at<short>(y, x);
				break;

			case 3:
				R = imgTmpX.at<short>(y, x);
				G = imgTmpG.at<short>(y, x);
				B = imgRaw.at<short>(y, x);
				break;
			}

			imgR.at<short>(y, x) = R;
			imgG.at<short>(y, x) = G;
			imgB.at<short>(y, x) = B;

			// debug
			if (pix == 1641) {
				printf("%d\n", X);
			}
			pix++;
		}
	}

	for (int y = 0; y < imgRaw.rows; y++) {
		for (int x = 0; x < imgRaw.cols; x++) {
			imgTmpG.at<short>(y, x) = std::min(std::max(imgTmpG.at<short>(y, x), (short)0), (short)1023);
			imgR.at<short>(y, x) = std::min(std::max(imgR.at<short>(y, x), (short)0), (short)1023);
			imgG.at<short>(y, x) = std::min(std::max(imgG.at<short>(y, x), (short)0), (short)1023);
			imgB.at<short>(y, x) = std::min(std::max(imgB.at<short>(y, x), (short)0), (short)1023);

			imgRgb.at<cv::Vec3b>(y, x)[0] = imgB.at<short>(y, x) / 4;
			imgRgb.at<cv::Vec3b>(y, x)[1] = imgG.at<short>(y, x) / 4;
			imgRgb.at<cv::Vec3b>(y, x)[2] = imgR.at<short>(y, x) / 4;
		}
	}


	{
		FILE *fp;
		fopen_s(&fp, "tmp_g.pgm", "w");
		fprintf(fp, "P2\n");
		fprintf(fp, "%d %d\n", imgTmpG.cols, imgTmpG.rows);
		fprintf(fp, "%d\n", 1023);
		for (int y = 0; y < imgTmpG.rows; y++) {
			for (int x = 0; x < imgTmpG.cols; x++) {
				fprintf(fp, "%d\n", (int)imgTmpG.at<short>(y, x));
			}
		}
		fclose(fp);
	}

	{
		FILE *fp;
		fopen_s(&fp, "rgb.ppm", "w");
		fprintf(fp, "P3\n");
		fprintf(fp, "%d %d\n", imgR.cols, imgR.rows);
		fprintf(fp, "%d\n", 1023);
		for (int y = 0; y < imgR.rows; y++) {
			for (int x = 0; x < imgR.cols; x++) {
				fprintf(fp, "%d %d %d\n", (int)imgR.at<short>(y, x), (int)imgG.at<short>(y, x), (int)imgB.at<short>(y, x));
			}
		}
		fclose(fp);
	}

	cv::imshow("imgRgb", imgRgb);
	cv::waitKey();

	return 0;
}


