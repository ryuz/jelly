// --------------------------------------------------------------------------
//  Jelly の GPU描画用のライブラリ
//
//                                     Copyright (C) 2017 by Ryuji Fuchikami
// --------------------------------------------------------------------------



#ifndef __RYUZ__JELLY_GL__H__
#define __RYUZ__JELLY_GL__H__


#include <stdint.h>
#include <array>
#include <vector>
#include <map>


template <class T=float, class TI=int32_t, int QE=4, int QP=20, bool perspective_correction=true>
class JellyGL
{
	// -----------------------------------------
	//   型定義
	// -----------------------------------------
public:
	typedef	std::array< std::array<T, 4>, 4>	Mat4;
	typedef	std::array<T, 4>					Vec4;
	typedef	std::array<T, 3>					Vec3;
	typedef	std::array<T, 2>					Vec2;

	struct FacePoint {
		size_t	vertex;			// 頂点インデックス
		size_t	tex_cord;		// テクスチャ座標インデックス
		Vec3	color;			// 色
		FacePoint() {}
		FacePoint(size_t v, size_t t)         { vertex = v; tex_cord = t; }
		FacePoint(size_t v, size_t t, Vec3 c) { vertex = v; tex_cord = t; color = c; }
		FacePoint(size_t v, Vec3 c)           { vertex = v; color = c; }
	};

	struct Face {
		int						matrial;
		std::vector<FacePoint>	points;
	};


	struct PixelParam {
		int		matrial;
		Vec3	tex_cord;
		Vec3	color;
	};

protected:
	typedef	std::array<size_t, 2>				Edge;
	struct PolygonRegion {
		size_t	edge;
		bool	inverse;
	};

	struct Polygon {
		int							matrial;
		std::vector<PolygonRegion>	region;			// 描画範囲
		size_t						vertex[3];		// 頂点インデックス
		size_t						tex_cord[3];	// テクスチャ座標インデックス
		Vec3						color[3];		// 色
	};

	struct RasterizeParam {
		TI		dx;
		TI		dy;
		TI		c;

		void PrintHwParam(int width) {
			printf("%08x\n%08x\n%08x\n",
						(int)dx,
						(int)(dy - (dx * (TI)(width - 1))),
						(int)c);
		}
	};

	// 計算ユニット(エッジ判定とパラメータ補完で共通化)
	class RasterizeUnit
	{
	public:
		RasterizeUnit(RasterizeParam rp, int width)
		{
			m_value    = rp.c;
			m_dx       = rp.dx;
			m_y_stride = rp.dy - (rp.dx * (TI)(width - 1));
		}

		bool GetEdgeValue(void)
		{
			return (m_value >= 0);
		}

		T GetParamValue(void)
		{
			return (T)m_value / (T)(1 << QP);
		}

		// ステップ計算(ハードウェア化想定箇所)
		void CalcNext(bool line_end)
		{
			m_value += line_end ? m_y_stride : m_dx;
		}
	protected:
		TI		m_value;
		TI		m_dx;
		TI		m_y_stride;
	};


	// -----------------------------------------
	//  メンバ変数
	// -----------------------------------------
protected:
	std::vector<Vec3>			m_vertex;			// 頂点リスト
	std::vector<int>			m_vertex_model;		// 頂点の属するモデル番号
	std::vector<Vec2>			m_tex_cord;			// テクスチャ座標リスト
	std::vector<Face>			m_face;				// 描画面
	std::vector<Polygon>		m_polygon;			// ポリゴンデータ

	std::vector <Vec4>			m_draw_vertex;		// 描画用頂点リスト

	std::vector <Mat4>			m_model_matrix;
	Mat4						m_view_matrix;
	Mat4						m_viewport_matrix;

	std::vector<Edge>			m_edge;				// 辺
	std::map< Edge, size_t>		m_edge_index;		// 辺のインデックス探索用

	bool						m_culling_cw  = true;
	bool						m_culling_ccw = false;

	std::vector<RasterizeParam>					m_rasterizeEdge;	// 辺
	std::vector< std::vector<RasterizeParam> >	m_rasterizeParam;	// パラメータ



	// -----------------------------------------
	//  メソッド
	// -----------------------------------------
public:
	// コンストラクタ
	JellyGL()
	{
		m_view_matrix     = IdentityMat4();
		m_viewport_matrix = IdentityMat4();
	}

	// デストラクタ
	~JellyGL()
	{
	}

	// 頂点バッファ設定
	void SetVertexBuffer(const std::vector<Vec3>& vertex)
	{
		m_vertex = vertex;
		m_vertex_model.resize(m_vertex.size(), 0);
		m_model_matrix.clear();
		m_model_matrix.push_back(IdentityMat4());
	}

	// モデル設定
	void SetModel(int model, int begin, int end)
	{
		while ( model >= (int)m_model_matrix.size() ) {
			m_model_matrix.push_back(IdentityMat4());
		}
		for ( int i = begin; i < end; i++ ) {
			m_vertex_model[i] = model;
		}
	}

	// テクスチャ座標バッファ設定
	void SetTexCordBuffer(const std::vector<Vec2>& tex_cord)
	{
		m_tex_cord = tex_cord;
	}

	// 面バッファ設定
	void SetFaceBuffer(const std::vector<Face>& face)
	{
		m_face = face;
	}

	// Viewport設定
	void SetViewport(int x, int y, int width, int height)
	{
		m_viewport_matrix = ViewportMat4(x,y ,width, height);
	}

	// Viewマトリックス設定
	void SetViewMatrix(Mat4 mat)
	{
		m_view_matrix = mat;
	}

	// Modelマトリックス設定
	void SetModelMatrix(int model, Mat4 mat)
	{
		while ( model >= (int)m_model_matrix.size() ) {
			m_model_matrix.push_back(IdentityMat4());
		}
		m_model_matrix[model] = mat;
	}

	// 描画リスト生成
	void MakeDrawList(void)
	{
		for ( auto f : m_face ) {
			Polygon	polygon;

			// 描画範囲設定
			for ( size_t i = 0; i < f.points.size(); ++i ) {
				size_t j = (i + 1) % f.points.size();

				PolygonRegion	region;
				Edge			edge;
				if (  f.points[i].vertex < f.points[j].vertex ) {
					edge[0] = f.points[i].vertex;
					edge[1] = f.points[j].vertex;
					region.inverse = false;
				}
				else {
					edge[0] = f.points[j].vertex;
					edge[1] = f.points[i].vertex;
					region.inverse = true;
				}

				// エッジの登録
				if ( m_edge_index.find(edge) == m_edge_index.end() ) {
					// 新規登録
					region.edge = m_edge.size();
					m_edge.push_back(edge);
					m_edge_index[edge] = region.edge;
				}
				else {
					// 既に登録あり
					region.edge = m_edge_index[edge];
				}

				// 登録
				polygon.region.push_back(region);
			}

			FacePoint	fp[3] = {f.points[0], f.points[1], f.points[2]};
			for ( int i = 0; i < 3; ++i ) {
				polygon.vertex[i]   = fp[i].vertex;
				polygon.tex_cord[i] = fp[i].tex_cord;
				polygon.color[i]    = fp[i].color;
			}
			polygon.matrial = f.matrial;

			m_polygon.push_back(polygon);
		}
	}


	// 描画実施
	void DrawSetup(void)
	{
		// マトリックス作成
		std::vector<Mat4> matrix;
		for ( auto& mat : m_model_matrix ) {
			matrix.push_back(MulMat(m_viewport_matrix, MulMat(m_view_matrix, mat)));
		}

		// 頂点座標計算
		m_draw_vertex.clear();
		for ( size_t i = 0; i < m_vertex.size(); ++i ) {
			m_draw_vertex.push_back(MulPerspectiveVec4(matrix[m_vertex_model[i]] , m_vertex[i]));
		}

		// ラスタライザパラメータ生成
		m_rasterizeEdge.clear();
		for ( auto edge : m_edge ) {
			m_rasterizeEdge.push_back(EdgeToRasterizeParam(m_draw_vertex[edge[0]], m_draw_vertex[edge[1]]));
		}
		m_rasterizeParam.clear();
		for ( auto p : m_polygon ) {
			Vec3 param[3+3];
			for ( int i = 0; i < 3; ++i ) {
				T u = m_tex_cord[p.tex_cord[i]][0];
				T v = m_tex_cord[p.tex_cord[i]][1];
				T w = m_draw_vertex[p.vertex[i]][3];
				if ( perspective_correction ) {
					param[0][i] = 1 / w;
					param[1][i] = u / w;
					param[2][i] = v / w;

					param[3][i] = p.color[i][0];
					param[4][i] = p.color[i][1];
					param[5][i] = p.color[i][2];
				}
				else {
					param[0][i] = w;
					param[1][i] = u;
					param[2][i] = v;

					param[3][i] = p.color[i][0];
					param[4][i] = p.color[i][1];
					param[5][i] = p.color[i][2];
				}
			}

			std::vector<RasterizeParam>	rp;
			for ( int i = 0; i < 3+3; ++i ) {
				Vec3 vertex[3];
				for ( int j = 0; j < 3; ++j ) {
					vertex[j][0] =  m_draw_vertex[p.vertex[j]][0];	// x
					vertex[j][1] =  m_draw_vertex[p.vertex[j]][1];	// y
					vertex[j][2] =  param[i][j];					// param
				}
				rp.push_back(ParamToRasterizeParam(vertex));
			}
			m_rasterizeParam.push_back(rp);
		}
	}

	void SetRegs(unsigned long base, int width)
	{
		volatile unsigned long *addr;
		addr = (volatile unsigned long *)(base + 0x1000);
		for ( auto& rp : m_rasterizeEdge ) {
			*addr++ = (int)rp.dx;
			*addr++ = (int)(rp.dy - (rp.dx * (TI)(width - 1)));
			*addr++ = (int)rp.c;
		}

		addr = (volatile unsigned long *)(base + 0x2000);
		for ( auto& rps : m_rasterizeParam ) {
			for ( int i = 3; i < 6; i++ ) {
				*addr++ = (int)rps[i].dx;
				*addr++ = (int)(rps[i].dy - (rps[i].dx * (TI)(width - 1)));
				*addr++ = (int)rps[i].c;
			}
		}

		addr = (volatile unsigned long *)(base + 0x3000);
		for ( auto& pol : m_polygon ) {
			unsigned long edge_flag = 0;
			unsigned long inv_flag  = 0;
			for ( auto& reg : pol.region ) {
				edge_flag |= (1 << reg.edge);
				if ( reg.inverse ) {
					inv_flag |= (1 << reg.edge);
				}
			}
			*addr++ = edge_flag;
			*addr++ = inv_flag;
		}
	}

	void PrintHwParam(int width)
	{
		printf("<edge>\n");
		for ( auto& rp : m_rasterizeEdge ) {
			rp.PrintHwParam(width);
		}
		printf("\n");

		printf("<polygon uvt>\n");
		for ( auto& rps : m_rasterizeParam ) {
	//		for ( auto& rp : rps ) {
	//			rp.PrintHwParam(width);
	//		}
			rps[0].PrintHwParam(width);
			rps[1].PrintHwParam(width);
			rps[2].PrintHwParam(width);
			printf("\n");
		}

		printf("<polygon rgb>\n");
		for ( auto& rps : m_rasterizeParam ) {
			rps[3].PrintHwParam(width);
			rps[4].PrintHwParam(width);
			rps[5].PrintHwParam(width);
			printf("\n");
		}

		printf("<region>\n");
		for ( auto& pol : m_polygon ) {
			unsigned long edge_flag = 0;
			unsigned long inv_flag  = 0;
			for ( auto& reg : pol.region ) {
				edge_flag |= (1 << reg.edge);
				if ( reg.inverse ) {
					inv_flag |= (1 << reg.edge);
				}
			}
			printf("%08lx\n", edge_flag);
			printf("%08lx\n", inv_flag);
		}
	}

	void Draw(int width, int height, void (*proc)(int x, int y, bool polygon, PixelParam pp, void* user), void* user=0)
	{
		// 計算用ユニット設定
		std::vector<RasterizeUnit> rasterizerEdge;
		for ( auto& rp : m_rasterizeEdge ) {
			rasterizerEdge.push_back(RasterizeUnit(rp, width));
		}
		std::vector< std::vector<RasterizeUnit> > rasterizerParam;
		for ( auto& rps : m_rasterizeParam ) {
			std::vector<RasterizeUnit>	vec;
			for ( auto& rp : rps ) {
				vec.push_back(RasterizeUnit(rp, width));
			}
			rasterizerParam.push_back(vec);
		}

		// 描画
		std::vector<bool>	edge_flags(m_rasterizeEdge.size());
		for ( int y = 0; y < height; ++y ) {
			for ( int x = 0; x < width; ++x ) {
				// エッジ判定
				for ( size_t i = 0; i < rasterizerEdge.size(); ++i ) {
					edge_flags[i] = rasterizerEdge[i].GetEdgeValue();
				}

				// Z判定
				PixelParam	pp = {};
				bool		valid = false;
				for ( size_t i = 0; i < m_polygon.size(); ++i ) {
					if ( CheckRegion(m_polygon[i].region, edge_flags) ) {
						T w, u, v;
						if ( perspective_correction ) {
							w = 1 / (T)rasterizerParam[i][0].GetParamValue();
							u = rasterizerParam[i][1].GetParamValue() * w;
							v = rasterizerParam[i][2].GetParamValue() * w;
						}
						else {
							w = rasterizerParam[i][0].GetParamValue();
							u = rasterizerParam[i][1].GetParamValue();
							v = rasterizerParam[i][2].GetParamValue();
						}
						T	r = rasterizerParam[i][3].GetParamValue();
						T	g = rasterizerParam[i][4].GetParamValue();
						T	b = rasterizerParam[i][5].GetParamValue();

						if ( !valid || pp.tex_cord[0] > w ) {
							valid = true;
							pp.matrial = m_polygon[i].matrial;
							pp.tex_cord[0] = u;
							pp.tex_cord[1] = v;
							pp.tex_cord[2] = w;
							pp.color[0] = r;
							pp.color[1] = g;
							pp.color[2] = b;
						}
					}
				}

				// 描画処理
				proc(x, y, valid, pp, user);

				// パラメータインクリメント
				for ( auto& ras : rasterizerEdge ) {
					ras.CalcNext(x == (width-1));
				}
				for ( auto& vec : rasterizerParam ) {
					for ( auto& ras : vec ) {
						ras.CalcNext(x == (width-1));
					}
				}
			}
		}
	}


protected:
	// 領域判定
	bool CheckRegion(const std::vector<PolygonRegion>& region, const std::vector<bool>& edge_flags) {
		bool	and_flag = true;
		bool	or_flag  = false;
		for ( auto r : region ) {
			bool v = edge_flags[r.edge] ^ r.inverse;
			and_flag &= v;
			or_flag  |= v;
		}
		return (m_culling_cw && and_flag) || (m_culling_ccw && !or_flag);
	}

	// エッジ判定パラメータ算出
	RasterizeParam	EdgeToRasterizeParam(Vec4 v0, Vec4 v1)
	{
		TI ix0 = (TI)round(v0[0]);
		TI iy0 = (TI)round(v0[1]);
		TI x0 = (TI)round(v0[0] * (1 << QE));
		TI y0 = (TI)round(v0[1] * (1 << QE));
		TI x1 = (TI)round(v1[0] * (1 << QE));
		TI y1 = (TI)round(v1[1] * (1 << QE));

		RasterizeParam	rp;
		rp.dx = y0 - y1;
		rp.dy = x1 - x0;
		rp.c  = -((iy0 * rp.dy) + (ix0 * rp.dx));

		if ( (rp.dy < 0 || (rp.dy == 0 && rp.dx < 0)) ) {
			rp.c--;
		}

		return rp;
	}

	// パラメータ計算
	RasterizeParam	ParamToRasterizeParam(Vec3 vertex[3])
	{
		Vec3	vector0 = SubVec3(vertex[1], vertex[0]);
		Vec3	vector1 = SubVec3(vertex[2], vertex[0]);
		Vec3	cross   = CrossVec3(vector0, vector1);

		T		dx = -cross[0] / cross[2];
		T		dy = -cross[1] / cross[2];
		T		c  = (cross[0]*vertex[0][0] + cross[1]*vertex[0][1] + cross[2]*vertex[0][2]) / cross[2];

		RasterizeParam	rp;
		rp.dx = (TI)(dx * (1 << QP));
		rp.dy = (TI)(dy * (1 << QP));
		rp.c  = (TI)(c  * (1 << QP));

		return rp;
	}



	// -----------------------------------------
	//  CG用行列計算補助関数
	// -----------------------------------------
public:
	// ビューポート設定
	static	Mat4 ViewportMat4(int x, int y, int width, int height)
	{
		Mat4 mat = IdentityMat4();
		mat[0][0] = (T)width / (T)2;
		mat[0][3] = (T)x + (width / (T)2);
		mat[1][1] = (T)height / (T)2;
		mat[1][3] = (T)y + (height / (T)2);
		return mat;
	}

	// 視点設定
	static	Mat4 LookAtMat4(Vec3 eye, Vec3 center, Vec3 up)
	{
		up = NormalizeVec3(up);
		Vec3 f = NormalizeVec3(SubVec3(center, eye));
		Vec3 s = CrossVec3(f, up);
		Vec3 u = CrossVec3(NormalizeVec3(s), f);
		Mat4 mat = { s[0],  s[1],  s[2],  0,
				     u[0],  u[1],  u[2],  0,
				    -f[0], -f[1], -f[2],  0,
			            0,     0,     0,  1};
		return MulMat(mat, TranslatedMat4(NegVec3(eye)));
	}

	// 平行移動
	static	Mat4 TranslatedMat4(Vec3 translated)
	{
		Mat4 mat = IdentityMat4();
		mat[0][3] = translated[0];
		mat[1][3] = translated[1];
		mat[2][3] = translated[2];
		return mat;
	}

	// 回転
	static	Mat4 RotateMat4(T angle,  Vec3 up)
	{
		angle *= (T)(3.14159265358979 / 180.0);
		up = NormalizeVec3(up);

		T s = sin(angle);
		T c = cos(angle);
		Mat4 mat = IdentityMat4();
		mat[0][0] = up[0]*up[0]*(1-c)+c;
		mat[0][1] = up[0]*up[1]*(1-c)-up[2]*s;
		mat[0][2] = up[0]*up[2]*(1-c)+up[1]*s;
		mat[1][0] = up[1]*up[0]*(1-c)+up[2]*s;
		mat[1][1] = up[1]*up[1]*(1-c)+c;
		mat[1][2] = up[1]*up[2]*(1-c)-up[0]*s;
		mat[2][0] = up[2]*up[0]*(1-c)-up[1]*s;
		mat[2][1] = up[2]*up[1]*(1-c)+up[0]*s;
		mat[2][2] = up[2]*up[2]*(1-c)+c;
		return mat;
	}

	// 視点設定
	static	Mat4 PerspectiveMat4(T fovy, T aspect, T zNear, T zFar)
	{
		fovy *= (T)(3.14159265358979 / 180.0);

		T f = (T)(1.0/tan(fovy/2.0));
		Mat4 mat = ZeroMat4();
		mat[0][0] = f / aspect;
		mat[1][1] = f;
		mat[2][2] = (zFar+zNear)/(zNear-zFar);
		mat[2][3] = (2*zFar*zNear)/(zNear-zFar);
		mat[3][2] = -1;
		return mat;
	}


	// -----------------------------------------
	//  行列計算補助関数
	// -----------------------------------------
public:
	// 単位行列生成
	static	Mat4 IdentityMat4(void)
	{
		Mat4	mat;
		for ( size_t i = 0; i < mat.size(); ++i ) {
			for ( size_t j = 0; j < mat[i].size(); ++j ) {
				mat[i][j] = (i == j) ? (T)1 : (T)0;
			}
		}
		return mat;
	}

	// 単位行列生成
	static	Mat4 ZeroMat4(void)
	{
		Mat4	mat;
		for ( size_t i = 0; i < mat.size(); ++i ) {
			for ( size_t j = 0; j < mat[i].size(); ++j ) {
				mat[i][j] = (T)0;
			}
		}
		return mat;
	}


	// 行列乗算
	static	Mat4 MulMat(const Mat4 matSrc0, const Mat4 matSrc1)
	{
		Mat4	matDst;
		for ( size_t i = 0; i < matDst.size(); i++ ) {
			for ( size_t j = 0; j < matDst[0].size(); j++ ) {
				matDst[i][j] = 0;
				for ( size_t k = 0; k < matDst[0].size(); k++ ) {
					matDst[i][j] += matSrc0[i][k] * matSrc1[k][j];
				}
			}
		}
		return matDst;
	}

	// 行列のベクタへの適用
	static	Vec4 MulMat(const Mat4 matSrc, const Vec4 vecSrc)
	{
		Vec4 vecDst;
		for ( size_t i = 0; i < vecDst.size(); i++ ) {
			vecDst[i] = 0;
			for ( size_t j = 0; j < matSrc[i].size(); j++ ) {
				vecDst[i] += matSrc[i][j] * vecSrc[j];
			}
		}
		return vecDst;
	}

	// 行列のベクタへの適用(射影)
	static	Vec3 MulPerspectiveVec3(const Mat4 matSrc, const Vec3 vecSrc)
	{
		Vec4	vecIn;
		Vec4	vecOut;
		Vec3	vecDst;

		vecIn[0] = vecSrc[0];
		vecIn[1] = vecSrc[1];
		vecIn[2] = vecSrc[2];
		vecIn[3] = 1.0f;
		vecOut = MulMat(matSrc, vecIn);
		vecDst[0] = vecOut[0] / vecOut[3];
		vecDst[1] = vecOut[1] / vecOut[3];
		vecDst[2] = vecOut[2] / vecOut[3];

		return vecDst;
	}


	// 行列のベクタへの適用(射影)
	static	Vec4 MulPerspectiveVec4(const Mat4 matSrc, const Vec3 vecSrc)
	{
		Vec4	vecIn;
		Vec4	vecDst;

		vecIn[0] = vecSrc[0];
		vecIn[1] = vecSrc[1];
		vecIn[2] = vecSrc[2];
		vecIn[3] = 1.0f;
		vecDst = MulMat(matSrc, vecIn);
		vecDst[0] = vecDst[0] / vecDst[3];
		vecDst[1] = vecDst[1] / vecDst[3];
		vecDst[2] = vecDst[2] / vecDst[3];

		return vecDst;
	}

	// ベクトルの符号反転
	static	Vec3 NegVec3(const Vec3 vecSrc) {
		Vec3 vecDst;
		for ( size_t i = 0; i < vecDst.size(); i++ ) {
			vecDst[i] = -vecSrc[i];
		}
		return vecDst;
	}

	// ベクトルの減算
	static	Vec3 SubVec3(const Vec3 vec0, const Vec3 vec1) {
		Vec3 vecDst;
		for ( size_t i = 0; i < vecDst.size(); i++ ) {
			vecDst[i] = vec0[i] - vec1[i];
		}
		return vecDst;
	}

	// ベクトルの外積
	static	Vec3 CrossVec3(const Vec3 vec0, const Vec3 vec1)
	{
		Vec3	vecCross;
		vecCross[0] = vec0[1]*vec1[2] - vec0[2]*vec1[1];
		vecCross[1] = vec0[2]*vec1[0] - vec0[0]*vec1[2];
		vecCross[2] = vec0[0]*vec1[1] - vec0[1]*vec1[0];
		return vecCross;
	}

	// ノルム計算
	static	T NormVec3(const Vec3 vec)
	{
		T norm = 0;
		for ( size_t i = 0; i < vec.size(); i++ ) {
			norm += vec[i] * vec[i];
		}
		return sqrt(norm);
	}

	// 単位ベクトル化
	static	Vec3 NormalizeVec3(const Vec3 vec)
	{
		T norm = NormVec3(vec);
		Vec3	vecDst;
		for ( size_t i = 0; i < vecDst.size(); i++ ) {
			vecDst[i] = vec[i] / norm;
		}
		return vecDst;
	}
};



#endif	// __RYUZ__JELLY_GL__H__


// end of file
