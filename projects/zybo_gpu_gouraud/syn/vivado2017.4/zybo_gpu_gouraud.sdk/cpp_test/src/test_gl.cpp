
#include <stdio.h>
#include <math.h>
#include <algorithm>
#include "JellyGL.h"
#include "mpu9250.h"

typedef	JellyGL<>	JGL;


// モデルの頂点リスト
std::array<float, 3> table_vertex[8*2] = {
	{-2, -2, -2},
	{+2, -2, -2},
	{-2, +2, -2},
	{+2, +2, -2},
	{-2, -2, +2},
	{+2, -2, +2},
	{-2, +2, +2},
	{+2, +2, +2},
	{-1, -1, -1},
	{+1, -1, -1},
	{-1, +1, -1},
	{+1, +1, -1},
	{-1, -1, +1},
	{+1, -1, +1},
	{-1, +1, +1},
	{+1, +1, +1},
};

// テクスチャ座標リスト
std::array<float, 2> table_tex_cord[4] = {
	{0, 0},
	{1, 0},
	{1, 1},
	{0, 1},
};



void rasterizer_test(void)
{
	Mpu9250_Init();


	int		width  = 640;
	int		height = 480;

	width  = 1920;
	height = 1080;

	JGL	jgl;
	jgl.SetEdgeParamFracWidth(4);
	jgl.SetShaderParamFracWidth(24);

	jgl.SetSize(width, height);
	jgl.SetCulling(true, false);

	jgl.SetupHwCore(0x40000000);

	jgl.SetVertexBuffer(std::vector<JGL::Vec3>(table_vertex, std::end(table_vertex)));
	jgl.SetTexCordBuffer(std::vector<JGL::Vec2>(table_tex_cord, std::end(table_tex_cord)));

	jgl.SetModel(0, 0, 8);
	jgl.SetModel(1, 8, 16);

	std::vector<JGL::Face>	face_table;
	JGL::Face				f;

	// キューブの６面を設定
	f.matrial = 0;
	f.points.clear();
	f.points.push_back(JGL::FacePoint(0, 0, {0.5f, 0.0f, 0.0f}));
	f.points.push_back(JGL::FacePoint(2, 1, {0.5f, 0.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(3, 2, {0.5f, 1.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(1, 3, {0.5f, 1.0f, 0.0f}));
	face_table.push_back(f);

	f.points.clear();
	f.points.push_back(JGL::FacePoint(7, 0, {0.5f, 0.0f, 0.0f}));
	f.points.push_back(JGL::FacePoint(6, 1, {0.5f, 0.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(4, 2, {0.5f, 1.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(5, 3, {0.5f, 1.0f, 0.0f}));
	face_table.push_back(f);

	f.points.clear();
	f.points.push_back(JGL::FacePoint(0, 0, {0.5f, 0.0f, 0.0f}));
	f.points.push_back(JGL::FacePoint(1, 1, {0.5f, 0.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(5, 2, {0.5f, 1.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(4, 3, {0.5f, 1.0f, 0.0f}));
	face_table.push_back(f);

	f.points.clear();
	f.points.push_back(JGL::FacePoint(1, 0, {0.5f, 0.0f, 0.0f}));
	f.points.push_back(JGL::FacePoint(3, 1, {0.5f, 0.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(7, 2, {0.5f, 1.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(5, 3, {0.5f, 1.0f, 0.0f}));
	face_table.push_back(f);

	f.points.clear();
	f.points.push_back(JGL::FacePoint(3, 0, {0.5f, 0.0f, 0.0f}));
	f.points.push_back(JGL::FacePoint(2, 1, {0.5f, 0.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(6, 2, {0.5f, 1.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(7, 3, {0.5f, 1.0f, 0.0f}));
	face_table.push_back(f);

	f.points.clear();
	f.points.push_back(JGL::FacePoint(2, 0, {0.5f, 0.0f, 0.0f}));
	f.points.push_back(JGL::FacePoint(0, 1, {0.5f, 0.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(4, 2, {0.5f, 1.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(6, 3, {0.5f, 1.0f, 0.0f}));
	face_table.push_back(f);

#if 1
	// ２個目のキューブの６面を設定
	f.matrial = 1;
	f.points.clear();
	f.points.push_back(JGL::FacePoint(8+0, 0, {0.5f, 0.0f, 0.0f}));
	f.points.push_back(JGL::FacePoint(8+2, 1, {0.5f, 0.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(8+3, 2, {0.5f, 1.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(8+1, 3, {0.5f, 1.0f, 0.0f}));
	face_table.push_back(f);

	f.points.clear();
	f.points.push_back(JGL::FacePoint(8+7, 0, {0.5f, 0.0f, 0.0f}));
	f.points.push_back(JGL::FacePoint(8+6, 1, {0.5f, 0.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(8+4, 2, {0.5f, 1.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(8+5, 3, {0.5f, 1.0f, 0.0f}));
	face_table.push_back(f);

	f.points.clear();
	f.points.push_back(JGL::FacePoint(8+0, 0, {0.5f, 0.0f, 0.0f}));
	f.points.push_back(JGL::FacePoint(8+1, 1, {0.5f, 0.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(8+5, 2, {0.5f, 1.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(8+4, 3, {0.5f, 1.0f, 0.0f}));
	face_table.push_back(f);

	f.points.clear();
	f.points.push_back(JGL::FacePoint(8+1, 0, {0.5f, 0.0f, 0.0f}));
	f.points.push_back(JGL::FacePoint(8+3, 1, {0.5f, 0.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(8+7, 2, {0.5f, 1.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(8+5, 3, {0.5f, 1.0f, 0.0f}));
	face_table.push_back(f);

	f.points.clear();
	f.points.push_back(JGL::FacePoint(8+3, 0, {0.5f, 0.0f, 0.0f}));
	f.points.push_back(JGL::FacePoint(8+2, 1, {0.5f, 0.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(8+6, 2, {0.5f, 1.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(8+7, 3, {0.5f, 1.0f, 0.0f}));
	face_table.push_back(f);

	f.points.clear();
	f.points.push_back(JGL::FacePoint(8+2, 0, {0.5f, 0.0f, 0.0f}));
	f.points.push_back(JGL::FacePoint(8+0, 1, {0.5f, 0.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(8+4, 2, {0.5f, 1.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(8+6, 3, {0.5f, 1.0f, 0.0f}));
	face_table.push_back(f);
#endif

	jgl.SetFaceBuffer(face_table);
	jgl.MakeDrawList();

	Mpu9250Data	mpu;

	int bank = 0;
	float angle00 = 0;
	float angle01 = 0;
	float angle02 = 0;
	float angle1  = 0;
	do {
		Mpu9250_Read(mpu);

		// viewport
		jgl.SetViewport(0, 0, width, height);

		// model0
		JGL::Mat4	matRotate00 = JGL::RotateMat4(angle00, {0, 1, 0});	angle00 -= (float)mpu.gyro[0] / 10000.0f;
		JGL::Mat4	matRotate01 = JGL::RotateMat4(angle01, {0, 0, 1});	angle01 -= (float)mpu.gyro[1] / 10000.0f;
		JGL::Mat4	matRotate02 = JGL::RotateMat4(angle02, {1, 0, 0});	angle02 -= (float)mpu.gyro[2] / 10000.0f;
		jgl.SetModelMatrix(0, JGL::MulMat(matRotate00, JGL::MulMat(matRotate01, matRotate02)));
		angle00 *= 0.98f;
		angle01 *= 0.98f;
		angle02 *= 0.98f;

		// model1
		JGL::Mat4	matRotate1	 = JGL::RotateMat4(angle1, {0, 1, 0});	angle1 -= (float)mpu.gyro[2] / 5000.0f;
		JGL::Mat4	matTranslate1 = JGL::TranslatedMat4({0, 0, 2});
		jgl.SetModelMatrix(1, JGL::MulMat(matTranslate1, matRotate1));
		angle1 *= 0.98f;

		// view
		JGL::Mat4	matLookAt       = JGL::LookAtMat4({5, -8, 20}, {0, 0, 0}, {0, 1, 0});
		JGL::Mat4	matPerspectivet = JGL::PerspectiveMat4(13.0f, (float)width/(float)height, 0.1f, 1000.0f);
		jgl.SetViewMatrix(JGL::MulMat(matPerspectivet, matLookAt));

		//draw
		jgl.DrawSetup();

		if ( bank == 0 ) {
			jgl.DrawHw(0);
			*(volatile unsigned long *)0x40000004 = 0;
			*(volatile unsigned long *)0x40000000 = 1;
			while ( *(volatile unsigned long *)0x40000044 != 0 )
				;
			bank = 1;
		}
		else {
			jgl.DrawHw(1);
			*(volatile unsigned long *)0x40000004 = 0;
			*(volatile unsigned long *)0x40000000 = 1;
			while ( *(volatile unsigned long *)0x40000044 != 0 )
				;
			bank = 0;
		}
	} while ( 1 );
}




#if 0
typedef	JellyGL<float>	JGL;


// モデルの頂点リスト
std::array<float, 3> table_vertex[8*2] = {
	{-2, -2, -2},
	{+2, -2, -2},
	{-2, +2, -2},
	{+2, +2, -2},
	{-2, -2, +2},
	{+2, -2, +2},
	{-2, +2, +2},
	{+2, +2, +2},
	{-1, -1, -1},
	{+1, -1, -1},
	{-1, +1, -1},
	{+1, +1, -1},
	{-1, -1, +1},
	{+1, -1, +1},
	{-1, +1, +1},
	{+1, +1, +1},
};

// テクスチャ座標リスト
std::array<float, 2> table_tex_cord[4] = {
	{0, 0},
	{1, 0},
	{1, 1},
	{0, 1},
};


// 描画プロシージャ
void RenderProc(int x, int y, bool polygon, JGL::PixelParam pp, void* user)
{
//	cv::Mat& tex = imgTex[pp.matrial];
/*
	if ( polygon ) {
		float u = std::max(0.0f, std::min(1.0f, pp.tex_cord[0]));
		float v = std::max(0.0f, std::min(1.0f, pp.tex_cord[1]));
		u *= (tex.cols-1);
		v *= (tex.rows-1);
	//	img.at<cv::Vec3b>(y, x) = tex.at<cv::Vec3b>((int)round(v), (int)round(u));

		float r = std::max(0.0f, std::min(1.0f, pp.color[0])) * 255.0f;
		float g = std::max(0.0f, std::min(1.0f, pp.color[1])) * 255.0f;
		float b = std::max(0.0f, std::min(1.0f, pp.color[2])) * 255.0f;
	//	img.at<cv::Vec3b>(y, x) = cv::Vec3b((uchar)round(b), (uchar)round(g), (uchar)round(r));
	}
*/
}


void rasterizer_test(void)
{
	Mpu9250_Init();

//	imgTex = cv::imread("DSC_0030.jpg");
//	imgTex[0] = cv::imread("Penguins.jpg");
//	imgTex[1] = cv::imread("Chrysanthemum.jpg");
//	img = cv::Mat::zeros(480, 640, CV_8UC3);

	JGL	jgl;
	jgl.SetVertexBuffer(std::vector<JGL::Vec3>(table_vertex, std::end(table_vertex)));
	jgl.SetTexCordBuffer(std::vector<JGL::Vec2>(table_tex_cord, std::end(table_tex_cord)));

	jgl.SetModel(0, 0, 8);
	jgl.SetModel(1, 8, 16);

	std::vector<JGL::Face>	face_table;
	JGL::Face				f;

	// キューブの６面を設定
	f.matrial = 0;
	f.points.clear();
	f.points.push_back(JGL::FacePoint(0, 0, {0.5f, 0.0f, 0.0f}));
	f.points.push_back(JGL::FacePoint(2, 1, {0.5f, 0.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(3, 2, {0.5f, 1.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(1, 3, {0.5f, 1.0f, 0.0f}));
	face_table.push_back(f);

	f.points.clear();
	f.points.push_back(JGL::FacePoint(7, 0, {0.5f, 0.0f, 0.0f}));
	f.points.push_back(JGL::FacePoint(6, 1, {0.5f, 0.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(4, 2, {0.5f, 1.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(5, 3, {0.5f, 1.0f, 0.0f}));
	face_table.push_back(f);

	f.points.clear();
	f.points.push_back(JGL::FacePoint(0, 0, {0.5f, 0.0f, 0.0f}));
	f.points.push_back(JGL::FacePoint(1, 1, {0.5f, 0.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(5, 2, {0.5f, 1.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(4, 3, {0.5f, 1.0f, 0.0f}));
	face_table.push_back(f);

	f.points.clear();
	f.points.push_back(JGL::FacePoint(1, 0, {0.5f, 0.0f, 0.0f}));
	f.points.push_back(JGL::FacePoint(3, 1, {0.5f, 0.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(7, 2, {0.5f, 1.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(5, 3, {0.5f, 1.0f, 0.0f}));
	face_table.push_back(f);

	f.points.clear();
	f.points.push_back(JGL::FacePoint(3, 0, {0.5f, 0.0f, 0.0f}));
	f.points.push_back(JGL::FacePoint(2, 1, {0.5f, 0.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(6, 2, {0.5f, 1.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(7, 3, {0.5f, 1.0f, 0.0f}));
	face_table.push_back(f);

	f.points.clear();
	f.points.push_back(JGL::FacePoint(2, 0, {0.5f, 0.0f, 0.0f}));
	f.points.push_back(JGL::FacePoint(0, 1, {0.5f, 0.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(4, 2, {0.5f, 1.0f, 1.0f}));
	f.points.push_back(JGL::FacePoint(6, 3, {0.5f, 1.0f, 0.0f}));
	face_table.push_back(f);

#if 1
	// ２個目のキューブの６面を設定
	f.matrial = 1;
	f.points.clear();
	f.points.push_back(JGL::FacePoint(8+0, 0));
	f.points.push_back(JGL::FacePoint(8+2, 1));
	f.points.push_back(JGL::FacePoint(8+3, 2));
	f.points.push_back(JGL::FacePoint(8+1, 3));
	face_table.push_back(f);

	f.points.clear();
	f.points.push_back(JGL::FacePoint(8+7, 0));
	f.points.push_back(JGL::FacePoint(8+6, 1));
	f.points.push_back(JGL::FacePoint(8+4, 2));
	f.points.push_back(JGL::FacePoint(8+5, 3));
	face_table.push_back(f);

	f.points.clear();
	f.points.push_back(JGL::FacePoint(8+0, 0));
	f.points.push_back(JGL::FacePoint(8+1, 1));
	f.points.push_back(JGL::FacePoint(8+5, 2));
	f.points.push_back(JGL::FacePoint(8+4, 3));
	face_table.push_back(f);

	f.points.clear();
	f.points.push_back(JGL::FacePoint(8+1, 0));
	f.points.push_back(JGL::FacePoint(8+3, 1));
	f.points.push_back(JGL::FacePoint(8+7, 2));
	f.points.push_back(JGL::FacePoint(8+5, 3));
	face_table.push_back(f);

	f.points.clear();
	f.points.push_back(JGL::FacePoint(8+3, 0));
	f.points.push_back(JGL::FacePoint(8+2, 1));
	f.points.push_back(JGL::FacePoint(8+6, 2));
	f.points.push_back(JGL::FacePoint(8+7, 3));
	face_table.push_back(f);

	f.points.clear();
	f.points.push_back(JGL::FacePoint(8+2, 0));
	f.points.push_back(JGL::FacePoint(8+0, 1));
	f.points.push_back(JGL::FacePoint(8+4, 2));
	f.points.push_back(JGL::FacePoint(8+6, 3));
	face_table.push_back(f);
#endif

	jgl.SetFaceBuffer(face_table);
	jgl.MakeDrawList();

//	cv::VideoWriter writer("output.avi", CV_FOURCC_DEFAULT, 30, cv::Size(640, 480), true);

	Mpu9250Data	mpu;

	int bank = 0;
	float angle00 = 0;
	float angle01 = 0;
	float angle02 = 0;

	float angle1 = 0;
	do {
		Mpu9250_Read(mpu);
//		printf("(%d, %d, %d) (%d, %d, %d)\r\n", mpu.accel[0], mpu.accel[1], mpu.accel[2], mpu.gyro[0], mpu.gyro[1], mpu.gyro[2]);

		// clear
//		img = cv::Mat::zeros(480, 640, CV_8UC3);

		// viewport
//		jgl.SetViewport(0, 0, 640, 480);
		jgl.SetViewport(0, 0, 1920, 1080);

		// model0
		JGL::Mat4	matRotate00 = JGL::RotateMat4(angle00, {0, 1, 0});	angle00 -= (float)mpu.gyro[0] / 5000.0f;
		JGL::Mat4	matRotate01 = JGL::RotateMat4(angle01, {0, 0, 1});	angle01 -= (float)mpu.gyro[1] / 5000.0f;
		JGL::Mat4	matRotate02 = JGL::RotateMat4(angle02, {1, 0, 0});	angle02 -= (float)mpu.gyro[2] / 5000.0f;
		jgl.SetModelMatrix(0, JGL::MulMat(matRotate00, JGL::MulMat(matRotate01, matRotate02)));
		angle00 *= 0.98f;
		angle01 *= 0.98f;
		angle02 *= 0.98f;

		// model1
		JGL::Mat4	matRotate1	 = JGL::RotateMat4(angle1, {0, 1, 0});	angle1 -= 0.2;
		JGL::Mat4	matTranslate = JGL::TranslatedMat4({0, 0, 2});
		jgl.SetModelMatrix(1, JGL::MulMat(matTranslate, matRotate1));

		// view
		JGL::Mat4	matLookAt       = JGL::LookAtMat4({5, -8, 20}, {0, 0, 0}, {0, 1, 0});
		JGL::Mat4	matPerspectivet = JGL::PerspectiveMat4(30.0f, 640.0f/480.0f, 0.1f, 1000.0f);
		jgl.SetViewMatrix(JGL::MulMat(matPerspectivet, matLookAt));

		//draw
		jgl.DrawSetup();
	//	jgl.PrintHwParam(640);

		*(volatile unsigned long *)0x40000008 = 1920-1;
		*(volatile unsigned long *)0x4000000c = 1080-1;

		if ( bank == 1 ) {
			jgl.SetRegs(0x40000000, 1920);
			*(volatile unsigned long *)0x40000004 = 0;
			*(volatile unsigned long *)0x40000000 = 1;
			bank = 0;
			while ( *(volatile unsigned long *)0x40000044 != 0 )
				;
		}
		else {
			jgl.SetRegs(0x40004000, 1920);
			*(volatile unsigned long *)0x40000004 = 1;
			*(volatile unsigned long *)0x40000000 = 1;
			bank = 1;
			while ( *(volatile unsigned long *)0x40000044 != 1 )
				;
		}

//		jgl.Draw(640, 480, RenderProc);

	} while ( 1 );
}

#endif
