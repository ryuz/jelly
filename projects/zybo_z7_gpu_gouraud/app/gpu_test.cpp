
#include <stdio.h>
#include <math.h>
#include <algorithm>
#include "JellyGL.h"

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


void gpu_test(void *gpu_addr)
{
	int		width  = 1280;
	int		height = 720;
	
	volatile uint32_t* base_addr = (volatile uint32_t *)gpu_addr;
	
	JGL	jgl;
	jgl.SetEdgeParamFracWidth(4);
	jgl.SetShaderParamFracWidth(24);
	
	jgl.SetSize(width, height);
	jgl.SetCulling(true, false);
	
	jgl.SetupHwCore((uint32_t)gpu_addr, true);
	
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
	
	
	float angle00 = 0;
	float angle01 = 0;
	float angle02 = 0;
	float angle1  = 0;
	
	float angle_view[3] = {0, 0, 0};
	do {
		// viewport
		jgl.SetViewport(0, 0, width, height);
		
		// model0
		JGL::Mat4	matRotate00 = JGL::RotateMat4(angle00, {0, 1, 0});	//angle00 -= (float)mpu.gyro[0] / 10000.0f;
		JGL::Mat4	matRotate01 = JGL::RotateMat4(angle01, {0, 0, 1});	//angle01 -= (float)mpu.gyro[1] / 10000.0f;
		JGL::Mat4	matRotate02 = JGL::RotateMat4(angle02, {1, 0, 0});	//angle02 -= (float)mpu.gyro[2] / 10000.0f;
		jgl.SetModelMatrix(0, JGL::MulMat(matRotate00, JGL::MulMat(matRotate01, matRotate02)));
		angle00 += 0.1;
//		angle00 *= 0.98f;
//		angle01 *= 0.98f;
//		angle02 *= 0.98f;

		// model1
		JGL::Mat4	matRotate1	 = JGL::RotateMat4(angle1, {0, 1, 0});//	angle1 -= (float)mpu.gyro[1] / 5000.0f;
		JGL::Mat4	matTranslate1 = JGL::TranslatedMat4({0, 0, 2});
		jgl.SetModelMatrix(1, JGL::MulMat(matTranslate1, matRotate1));
//		angle1 *= 0.98f;

		// view
//		angle_view[0] += (float)mpu.gyro[2] / 20000.0f;
//		angle_view[0] *= 0.98;

		JGL::Vec3 look_at_vec = {-5, 8, -20};
		look_at_vec = JGL::MulPerspectiveVec3(JGL::RotateMat4(angle_view[0], {0, 1, 0}), look_at_vec);
		look_at_vec[0] += 5;
		look_at_vec[1] += -8;
		look_at_vec[2] += 20;
		
		JGL::Mat4	matLookAt       = JGL::LookAtMat4({5, -8, 20}, look_at_vec, {0, 1, 0});
		JGL::Mat4	matPerspectivet = JGL::PerspectiveMat4(30.0f, (float)width/(float)height, 0.1f, 1000.0f);
		jgl.SetViewMatrix(JGL::MulMat(matPerspectivet, matLookAt));
		
		//draw
		jgl.DrawSetup();
		
		jgl.DrawHw(0);
		while ( base_addr[0x21] != 0 )
			;
		base_addr[0x21] = 1;
		base_addr[0x20] = 1;
	} while ( 1 );
}


