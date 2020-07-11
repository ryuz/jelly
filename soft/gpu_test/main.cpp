

#include <stdio.h>
#include "opencv2/opencv.hpp"
#include "jelly/JellyGL.h"


typedef	JellyGL<1>	JGL;


#if 1

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


// 描画
cv::Mat img;
cv::Mat imgTex[2];


// 描画プロシージャ
void RenderProc(int x, int y, bool polygon, JGL::PixelParam pp, void* user)
{
	cv::Mat& tex = imgTex[pp.matrial];

	if ( polygon ) {
	//	printf("raw:%08x %08x %08x\n", pp.raw_value[0], pp.raw_value[1], pp.raw_value[2]);
		float u = MAX(0.0f, MIN(1.0f, pp.tex_cord[0]));
		float v = MAX(0.0f, MIN(1.0f, pp.tex_cord[1]));

		u = (float)pp.raw_value[1] / pp.raw_value[0];
		v = (float)pp.raw_value[2] / pp.raw_value[0];
		u = MAX(0.0f, MIN(1.0f,u));
		v = MAX(0.0f, MIN(1.0f,v));

		u *= (tex.cols-1);
		v *= (tex.rows-1);
		img.at<cv::Vec3b>(y, x) = tex.at<cv::Vec3b>((int)round(v), (int)round(u));

		float r = MAX(0.0f, MIN(1.0f, pp.color[2])) * 255.0f;
		float g = MAX(0.0f, MIN(1.0f, pp.color[1])) * 255.0f;
		float b = MAX(0.0f, MIN(1.0f, pp.color[0])) * 255.0f;
		img.at<cv::Vec3b>(y, x) = cv::Vec3b((uchar)round(b), (uchar)round(g), (uchar)round(r));
	}
}


unsigned int	bank_addr = 0x00;

void PrintSimWbWrite(unsigned int addr, unsigned int data)
{
	printf("wb_write(32'h%08x, 32'h%08x, 4'b1111);\n", bank_addr + addr, data);
}

void PrintSimRasterizerParameter(unsigned int addr, JGL::RasterizerParameter rp)
{
	for ( auto v : rp ) {
		PrintSimWbWrite(addr, v);
		addr += 4;
	}
}


// パラメータ出力
void SimEdgeParamProc(size_t index, JGL::RasterizerParameter rp, void* user)
{
	unsigned int	addr = 0x1000 + ((unsigned int)index * 3*4);
	PrintSimRasterizerParameter(addr, rp);
}

void SimShadereParamProc(size_t index, const std::vector<JGL::RasterizerParameter>& rps, void* user)
{
	unsigned int	addr = 0x2000 + ((unsigned int)index * 3*4*4);
	PrintSimRasterizerParameter(addr, rps[0]);	addr += 3*4;
	PrintSimRasterizerParameter(addr, rps[3]);	addr += 3*4;
	PrintSimRasterizerParameter(addr, rps[4]);	addr += 3*4;
	PrintSimRasterizerParameter(addr, rps[5]);	addr += 3*4;
}

void SimRegionParamProc(size_t index, const std::vector<JGL::PolygonRegion>& regions, void* user)
{
	// bitマスク生成
	unsigned long edge_flag = 0;
	unsigned long pol_flag  = 0;
	for ( auto& r : regions ) {
		edge_flag |= (1 << r.edge);
		if ( r.inverse ) {
			pol_flag |= (1 << r.edge);
		}
	}

	// 出力
	unsigned int	addr = 0x3000 + ((unsigned int)index * 2*4);
	PrintSimWbWrite(addr, edge_flag);	addr += 4;
	PrintSimWbWrite(addr, pol_flag);	addr += 4;
}



int main(void)
{
	int		width  = 96;
	int		height = 64;

//	int		width  = 640;
//	int		height = 480;

//	width  = 1920;
//	height = 1080;


//	imgTex = cv::imread("DSC_0030.jpg");
	imgTex[0] = cv::imread("Penguins.jpg");
	imgTex[1] = cv::imread("Chrysanthemum.jpg");
	img = cv::Mat::zeros(height, width, CV_8UC3);
	if ( imgTex[0].empty() ) { return 1; }
	if ( imgTex[1].empty() ) { return 1; }

	JGL	jgl;
	jgl.SetEdgeParamFracWidth(4);
	jgl.SetShaderParamFracWidth(24);

	jgl.SetSize(width, height);
	jgl.SetCulling(true, false);

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

#if 0
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

//	cv::VideoWriter writer("output.avi", CV_FOURCC_DEFAULT, 30, cv::Size(width, height), true);

	float angle0 = 40;
	float angle1 = -80;
	do {
		// clear
		img = cv::Mat::zeros(height, width, CV_8UC3);

		// viewport
		jgl.SetViewport(0, 0, width, height);

		// model0
		JGL::Mat4	matRotate0 = JGL::RotateMat4(angle0, {0, 1, 0});	angle0 += 1;
		JGL::Mat4	matTranslate0 = JGL::TranslatedMat4({0, 0, 0});
		jgl.SetModelMatrix(0, JGL::MulMat(matTranslate0, matRotate0));
		
		// model1
		JGL::Mat4	matRotate1	 = JGL::RotateMat4(angle1, {0, 1, 0});	angle1 -= 2;
		JGL::Mat4	matTranslate1 = JGL::TranslatedMat4({0, 0, 2});
		jgl.SetModelMatrix(1, JGL::MulMat(matTranslate1, matRotate1));
		
		// view
		JGL::Mat4	matLookAt       = JGL::LookAtMat4({5, -8, 20}, {0, 0, 0}, {0, 1, 0});
		JGL::Mat4	matPerspectivet = JGL::PerspectiveMat4(13.0f, (float)width/(float)height, 0.1f, 1000.0f);
		jgl.SetViewMatrix(JGL::MulMat(matPerspectivet, matLookAt));
		
		//draw
		jgl.DrawSetup();
	//	jgl.PrintHwParam(width);
		
		// シミュレーション用出力
	//	printf("\n$display(\"[edge]\");\n");	jgl.CalcEdgeRasterizerParameter(SimEdgeParamProc);
	//	printf("\n$display(\"[shader]\");\n");	jgl.CalcShaderRasterizerParameter(SimShadereParamProc);
	//	printf("\n$display(\"[region]\");\n");	jgl.CalcRegionRasterizerParameter(SimRegionParamProc);
	//	printf("\n");	
		
		printf("------------\n");	
		jgl.DrawHw(0);

		// 描画
		jgl.Draw(RenderProc);

		// show
		cv::imshow("img", img);
//		writer << img;
	} while ( cv::waitKey(0) != 0x1b );

	return 0;
}


#else



std::array<float, 3> table_vertex[4] = {
	{1,     1, 0},
	{639,   1, 0},
	{639, 479, 0},
	{  1, 479, 0},
};

std::array<float, 2> table_tex_cord[4] = {
	{0, 0},
	{1, 0},
	{1, 1},
	{0, 1},
};


cv::Mat img;
cv::Mat imgTex;

void RenderProc(int x, int y, bool polygon, JGL::PixelParam pp, void* user)
{
	if ( polygon ) {
		float u = MAX(0.0f, MIN(1.0f, pp.u));
		float v = MAX(0.0f, MIN(1.0f, pp.v));
		u *= (imgTex.cols-1);
		v *= (imgTex.rows-1);
		
		img.at<cv::Vec3b>(y, x) = imgTex.at<cv::Vec3b>(v, u);
	}
}


void rasterizer_test(void)
{
	imgTex = cv::imread("Penguins.jpg");
	img = cv::Mat::zeros(480, 640, CV_8UC3);

	JGL	jgl;
	jgl.SetVertexBuffer(std::vector<JGL::Vec3>(table_vertex, std::end(table_vertex)));
	jgl.SetTexCordBuffer(std::vector<JGL::Vec2>(table_tex_cord, std::end(table_tex_cord)));

	std::vector<JGL::Face>	face_table;
	JGL::Face				f;
	
	// １面を設定
	f.clear();
	f.push_back(JGL::FacePoint(0, 0));
	f.push_back(JGL::FacePoint(1, 1));
	f.push_back(JGL::FacePoint(2, 2));
	f.push_back(JGL::FacePoint(3, 3));
	face_table.push_back(f);

	jgl.SetFaceBuffer(face_table);
	jgl.MakeDrawList();

//	JGL::Mat4	matRotate		= JGL::RotateMat4(angle, {0, 1, 0});
//	JGL::Mat4	matLookAt       = JGL::LookAtMat4({2, 2, +5}, {0, 0, 0}, {0, 1, 0});
//	JGL::Mat4	matPerspectivet = JGL::PerspectiveMat4(20.0, 1.0, 0.1, 1000);

	JGL::Mat4	mat = JGL::IdentityMat4();
	jgl.SetMatrix(mat);

	img = cv::Mat::zeros(480, 640, CV_8UC3);
	jgl.Draw(640, 480, RenderProc);

	cv::imshow("img", img);
	cv::waitKey();
}




#endif