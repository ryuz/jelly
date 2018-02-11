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


template <int SIMULATION=0, class T=float, class TI=int32_t>
class JellyGL
{
	// -----------------------------------------
	//   型定義
	// -----------------------------------------
public:
	typedef	std::array< std::array<T, 4>, 4>	Mat4;					// 行列4x4
	typedef	std::array<T, 4>					Vec4;					// ベクタx4
	typedef	std::array<T, 3>					Vec3;					// ベクタx3
	typedef	std::array<T, 2>					Vec2;					// ベクタx2
	typedef	std::array<TI, 3>					RasterizerParameter;	// ラスタライザパラメータ

	// 面定義字の頂点情報
	struct FacePoint {
		size_t	vertex;			// 頂点インデックス
		size_t	tex_cord;		// テクスチャ座標インデックス
		Vec3	color;			// 色
		FacePoint() {}
		FacePoint(size_t v, size_t t)         { vertex = v; tex_cord = t; }
		FacePoint(size_t v, size_t t, Vec3 c) { vertex = v; tex_cord = t; color = c; }
		FacePoint(size_t v, Vec3 c)           { vertex = v; color = c; }
	};

	// 面情報
	struct Face {
		int						matrial;
		std::vector<FacePoint>	points;
	};

	// ポリゴン領域
	struct PolygonRegion {
		size_t	edge;
		bool	inverse;
	};

	// ピクセル情報
	struct PixelParam {
		int		matrial;
		Vec3	tex_cord;
		Vec3	color;
	};

protected:
	typedef	std::array<size_t, 2>	Edge;			// エッジ情報

	// ポリゴン情報
	struct Polygon {
		int							matrial;
		std::vector<PolygonRegion>	region;			// 描画範囲
		size_t						vertex[3];		// 頂点インデックス
		size_t						tex_cord[3];	// テクスチャ座標インデックス
		Vec3						color[3];		// 色
	};

	// ラスタライズ係数
	struct RasterizeCoeff {
		TI		dx;
		TI		dy;
		TI		c;

		// ラスタライザパラメータに変換
		RasterizerParameter	GetRasterizerParameter(int width)
		{
			return {dx, dy - (dx * (TI)(width - 1)), c};
		}
	};

	// 計算ユニット(エッジ判定とパラメータ補完で共通化)
	class RasterizerUnit
	{
	public:
		RasterizerUnit(RasterizerParameter rp)
		{
			m_dx       = rp[0];
			m_y_stride = rp[1];
			m_value    = rp[2];
		}

		bool GetEdgeDiscriminantValue(void)
		{
			return (m_value >= 0);
		}

		T GetShaderParamValue(int param_q)
		{
			return (T)m_value / (T)(1 << param_q);
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
	int							m_width          = 640;
	int							m_height         = 480;
	bool						m_culling_cw     = true;
	bool						m_culling_ccw    = true;
	int							m_edge_param_q   = 4;
	int							m_shader_param_q = 24;
	bool						m_perspective_correction = true;

	std::vector<Vec3>			m_vertex;			// 頂点リスト
	std::vector<int>			m_vertex_model;		// 頂点の属するモデル番号
	std::vector<Vec2>			m_tex_cord;			// テクスチャ座標リスト
	std::vector<Face>			m_face;				// 描画面
	std::vector<Polygon>		m_polygon;			// ポリゴンデータ

	std::vector <Vec4>			m_draw_vertex;		// 描画用頂点リスト

	std::vector <Mat4>			m_model_matrix;		// モデル行列
	Mat4						m_view_matrix;		// ビュー行列
	Mat4						m_viewport_matrix;	// viewport

	std::vector<Edge>			m_edge;				// 辺
	std::map< Edge, size_t>		m_edge_index;		// 辺のインデックス探索用


	std::vector<RasterizeCoeff>					m_coeffsEdge;	// エッジ判定パラメータ係数
	std::vector< std::vector<RasterizeCoeff> >	m_coeffsShader;	//  シェーダーパラメータ係数


	// H/Wエンジン設定
	uint32_t		m_hw_base_addr        = 0x40100000;
	uint32_t		m_hw_shader_type      = 0;
	uint32_t		m_hw_version          = 0;
	uint32_t		m_hw_bank_step        = 0x00001000;
	uint32_t		m_hw_params_step      = 0x00004000;
	uint32_t		m_hw_bank_num         = 2;
	uint32_t		m_hw_edge_num         = 12*2;
	uint32_t		m_hw_polygon_num      = 6*2;
	uint32_t		m_hw_shader_param_num = 4;
	uint32_t		m_hw_shader_param_q   = 24;

	bool			m_hw_shader_param_has_z        = true;
	bool			m_hw_shader_param_has_tex_cord = false;
	bool			m_hw_shader_param_has_color    = true;

	const unsigned long	REG_ADDR_CTL_ENABLE             = 0x00*4;
	const unsigned long	REG_ADDR_CTL_UPDATE             = 0x01*4;
	const unsigned long	REG_ADDR_PARAM_WIDTH            = 0x02*4;
	const unsigned long	REG_ADDR_PARAM_HEIGHT           = 0x03*4;
	const unsigned long	REG_ADDR_PARAM_CULLING          = 0x04*4;
	const unsigned long	REG_ADDR_PARAM_BANK             = 0x10*4;

	const unsigned long	REG_ADDR_CFG_SHDER_TYPE         = 0x20*4;
	const unsigned long	REG_ADDR_CFG_VERSION            = 0x21*4;
	const unsigned long	REG_ADDR_CFG_BANK_ADDR_WIDTH    = 0x22*4;
	const unsigned long	REG_ADDR_CFG_PARAMS_ADDR_WIDTH  = 0x23*4;
	const unsigned long	REG_ADDR_CFG_BANK_NUM           = 0x24*4;
	const unsigned long	REG_ADDR_CFG_EDGE_NUM           = 0x25*4;
	const unsigned long	REG_ADDR_CFG_POLYGON_NUM        = 0x26*4;
	const unsigned long	REG_ADDR_CFG_SHADER_PARAM_NUM   = 0x27*4;
	const unsigned long	REG_ADDR_CFG_EDGE_PARAM_WIDTH   = 0x28*4;
	const unsigned long	REG_ADDR_CFG_SHADER_PARAM_WIDTH = 0x29*4;
	const unsigned long	REG_ADDR_CFG_REGION_PARAM_WIDTH = 0x2a*4;
//	const unsigned long	REG_ADDR_CFG_SHADER_PARAM_Q     = 0x2b*4;



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

	// 精度設定
	void SetEdgeParamFracWidth(int q)	{ m_edge_param_q   = q;	}
	void SetShaderParamFracWidth(int q)	{ m_shader_param_q = q;	}

	// サイズ設定
	void SetSize(int width, int height)
	{
		m_width  = width;
		m_height = height;
	}

	// カリング設定
	void SetCulling(bool cw, bool ccw)
	{
		m_culling_cw  = cw;
		m_culling_ccw = ccw;
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
		m_coeffsEdge.clear();
		for ( auto edge : m_edge ) {
			m_coeffsEdge.push_back(EdgeToRasterizeCoeff(m_draw_vertex[edge[0]], m_draw_vertex[edge[1]], m_edge_param_q));
		}
		m_coeffsShader.clear();
		for ( auto p : m_polygon ) {
			Vec3 param[3+3];
			for ( int i = 0; i < 3; ++i ) {
				T u = m_tex_cord[p.tex_cord[i]][0];
				T v = m_tex_cord[p.tex_cord[i]][1];
				T w = m_draw_vertex[p.vertex[i]][3];
				if ( m_perspective_correction ) {
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

			std::vector<RasterizeCoeff>	rcs;
			for ( int i = 0; i < 3+3; ++i ) {
				Vec3 vertex[3];
				for ( int j = 0; j < 3; ++j ) {
					vertex[j][0] =  m_draw_vertex[p.vertex[j]][0];	// x
					vertex[j][1] =  m_draw_vertex[p.vertex[j]][1];	// y
					vertex[j][2] =  param[i][j];					// param
				}
				rcs.push_back(ShaderParamToRasterizeCoeff(vertex, m_shader_param_q));
			}
			m_coeffsShader.push_back(rcs);
		}
	}


	// ラスタライザ設定用パラメータ算出(edge)
	void CalcEdgeRasterizerParameter(void (*procEdge)(size_t index, RasterizerParameter rp, void* user), void* user=0)
	{
		// edge
		for ( size_t index = 0; index < m_coeffsEdge.size(); ++index ) {
			procEdge(index, m_coeffsEdge[index].GetRasterizerParameter(m_width), user);
		}
	}

	// ラスタライザ設定用パラメータ算出(shader)
	void CalcShaderRasterizerParameter(void (*procShader)(size_t index, const std::vector<RasterizerParameter>& rps, void* user), void* user=0)
	{
		// shader param
		for ( size_t index = 0; index < m_coeffsShader.size(); ++index ) {
			std::vector<RasterizerParameter>	rps;
			for ( auto& rc : m_coeffsShader[index] ) {
				rps.push_back(rc.GetRasterizerParameter(m_width));
			}
			procShader(index, rps, user);
		}
	}

	// ラスタライザ設定用パラメータ算出(region)
	void CalcRegionRasterizerParameter(void (*procRegion)(size_t index, const std::vector<PolygonRegion>& region, void* user), void* user=0)
	{
		// region
		for ( size_t index = 0; index < m_polygon.size(); ++index ) {
			procRegion(index, m_polygon[index].region, user);
		}
	}

	// 描画シミュレーション
	void Draw(void (*proc)(int x, int y, bool polygon, PixelParam pp, void* user), void* user=0)
	{
		// 計算用ユニット設定
		std::vector<RasterizerUnit> rasterizerEdge;
		for ( auto& rc : m_coeffsEdge ) {
			rasterizerEdge.push_back(RasterizerUnit(rc.GetRasterizerParameter(m_width)));
		}
		std::vector< std::vector<RasterizerUnit> > rasterizerParam;
		for ( auto& rcs : m_coeffsShader ) {
			std::vector<RasterizerUnit>	vec;
			for ( auto& rc : rcs ) {
				vec.push_back(RasterizerUnit(rc.GetRasterizerParameter(m_width)));
			}
			rasterizerParam.push_back(vec);
		}

		// 描画
		std::vector<bool>	edge_flags(m_coeffsEdge.size());
		for ( int y = 0; y < m_height; ++y ) {
			for ( int x = 0; x < m_width; ++x ) {
				// エッジ判定
				for ( size_t i = 0; i < rasterizerEdge.size(); ++i ) {
					edge_flags[i] = rasterizerEdge[i].GetEdgeDiscriminantValue();
				}

				// Z判定
				PixelParam	pp = {};
				bool		valid = false;
				for ( size_t i = 0; i < m_polygon.size(); ++i ) {
					if ( CheckRegion(m_polygon[i].region, edge_flags) ) {
						T w, u, v;
						if ( m_perspective_correction ) {
							w = 1 / (T)rasterizerParam[i][0].GetShaderParamValue(m_shader_param_q);
							u = rasterizerParam[i][1].GetShaderParamValue(m_shader_param_q) * w;
							v = rasterizerParam[i][2].GetShaderParamValue(m_shader_param_q) * w;
						}
						else {
							w = rasterizerParam[i][0].GetShaderParamValue(m_shader_param_q);
							u = rasterizerParam[i][1].GetShaderParamValue(m_shader_param_q);
							v = rasterizerParam[i][2].GetShaderParamValue(m_shader_param_q);
						}
						T	r = rasterizerParam[i][3].GetShaderParamValue(m_shader_param_q);
						T	g = rasterizerParam[i][4].GetShaderParamValue(m_shader_param_q);
						T	b = rasterizerParam[i][5].GetShaderParamValue(m_shader_param_q);

						if ( !valid || pp.tex_cord[2] > w ) {
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
					ras.CalcNext(x == (m_width-1));
				}
				for ( auto& vec : rasterizerParam ) {
					for ( auto& ras : vec ) {
						ras.CalcNext(x == (m_width-1));
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

	// エッジ判定係数算出
	RasterizeCoeff	EdgeToRasterizeCoeff(Vec4 v0, Vec4 v1, int param_q)
	{
		TI ix0 = (TI)round(v0[0]);
		TI iy0 = (TI)round(v0[1]);
		TI x0 = (TI)round(v0[0] * (1 << param_q));
		TI y0 = (TI)round(v0[1] * (1 << param_q));
		TI x1 = (TI)round(v1[0] * (1 << param_q));
		TI y1 = (TI)round(v1[1] * (1 << param_q));

		RasterizeCoeff	rc;
		rc.dx = y0 - y1;
		rc.dy = x1 - x0;
		rc.c  = -((iy0 * rc.dy) + (ix0 * rc.dx));

		if ( (rc.dy < 0 || (rc.dy == 0 && rc.dx < 0)) ) {
			rc.c--;
		}

		return rc;
	}

	// ポリゴンパラメータ係数計算
	RasterizeCoeff	ShaderParamToRasterizeCoeff(Vec3 vertex[3], int param_q)
	{
		Vec3	vector0 = SubVec3(vertex[1], vertex[0]);
		Vec3	vector1 = SubVec3(vertex[2], vertex[0]);
		Vec3	cross   = CrossVec3(vector0, vector1);

		T		dx = -cross[0] / cross[2];
		T		dy = -cross[1] / cross[2];
		T		c  = (cross[0]*vertex[0][0] + cross[1]*vertex[0][1] + cross[2]*vertex[0][2]) / cross[2];

		RasterizeCoeff	rc;
		rc.dx = (TI)(dx * (1 << param_q));
		rc.dy = (TI)(dy * (1 << param_q));
		rc.c  = (TI)(c  * (1 << param_q));

		return rc;
	}


	// -----------------------------------------
	//  H/W制御
	// -----------------------------------------

protected:
	// H/W書き込み
	inline void WriteHwWord(uint32_t addr, uint32_t data)
	{
		if ( SIMULATION == 0 ) {
			// 実機
			*(volatile uint32_t*)addr = data;
		}
		else if ( SIMULATION == 1 ) {
			// verilog testbench用
			printf("wb_write(32'h%08x, 32'h%08x, 4'hf);\n", (int)addr, (int)data);
		}
	}

	// H/W読み出し
	inline uint32_t ReadHwWord(uint32_t addr)
	{
		if ( SIMULATION == 0 ) {
			return *(volatile uint32_t*)addr;
		}

		return 0;
	}

	// アドレス取得
	inline uint32_t GetHwParamAddr(uint32_t bank, uint32_t param)
	{
		return m_hw_base_addr + (bank * m_hw_bank_step) + (param * m_hw_params_step);
	}

	// ラスタライザ設定
	inline void WriteHwRasterizerParameter(uint32_t& addr, const RasterizerParameter& rp)
	{
		WriteHwWord(addr, rp[0]);	addr += 4;
		WriteHwWord(addr, rp[1]);	addr += 4;
		WriteHwWord(addr, rp[2]);	addr += 4;
	}

	// レジスタ書き込み
	void WriteHwRegister(uint32_t addr, uint32_t data)
	{
		WriteHwWord(m_hw_base_addr + addr, data);
	}

	// レジスタ読み込み
	uint32_t ReadHwRegister(uint32_t add)
	{
		return ReadHwWord(m_hw_base_addr + add);
	}

#if 0

	// パラメータレジスタ書き込み
	void WriteHwParamRegister(uint32_t bank, uint32_t param, uint32_t addr, uint32_t data)
	{
		WriteHwRegister((bank * m_hw_bank_step) + (param * m_hw_params_step) + addr, data);
	}

	// エッジパラメータ書き込み
	void WriteHwEdgeParam(uint32_t bank, uint32_t index, RasterizerParameter rp)
	{
		uint32_t addr = index * 3 * 4;
		WriteHwParamRegister(bank, 1, addr, rp[0]);	addr += 4;
		WriteHwParamRegister(bank, 1, addr, rp[1]);	addr += 4;
		WriteHwParamRegister(bank, 1, addr, rp[2]);
	}

	// シェーダーパラメータ書き込み
	void WriteHwEdgeParam(uint32_t bank, uint32_t polygon_index, uint32_t param_index, RasterizerParameter rp)
	{
		uint32_t addr = (polygon_index * m_hw_shader_param_num + param_index) * 3 * 4;
		WriteHwParamRegister(bank, 2, addr, rp[0]);	addr += 4;
		WriteHwParamRegister(bank, 2, addr, rp[1]);	addr += 4;
		WriteHwParamRegister(bank, 2, addr, rp[2]);
	}

	// 領域パラメータ書き込み
	void WriteHwEdgeParam(uint32_t bank, uint32_t index, uint32_t flag, uint32_t polality)
	{
		uint32_t addr = index * 2 * 4;
		WriteHwParamRegister(bank, 3, addr, flag);		addr += 4;
		WriteHwParamRegister(bank, 3, addr, polality);
	}
#endif

public:
	// H/W初期化
	void SetupHwCore(uint32_t base_addr, bool auto_config=true)
	{
		// ベースアドレス設定
		m_hw_base_addr = base_addr;

		// 設定読み出し
		if ( auto_config ) {
			m_hw_shader_type      = ReadHwRegister(REG_ADDR_CFG_SHDER_TYPE);
			m_hw_version          = ReadHwRegister(REG_ADDR_CFG_VERSION);
			m_hw_bank_step        = (4 << ReadHwRegister(REG_ADDR_CFG_BANK_ADDR_WIDTH));
			m_hw_params_step      = (4 << ReadHwRegister(REG_ADDR_CFG_PARAMS_ADDR_WIDTH));
			m_hw_bank_num         = ReadHwRegister(REG_ADDR_CFG_BANK_NUM);
			m_hw_edge_num         = ReadHwRegister(REG_ADDR_CFG_EDGE_NUM);
			m_hw_polygon_num      = ReadHwRegister(REG_ADDR_CFG_POLYGON_NUM);
			m_hw_shader_param_num = ReadHwRegister(REG_ADDR_CFG_SHADER_PARAM_NUM);
	//		m_hw_shader_param_q   = ReadHwRegister(REG_ADDR_CFG_SHADER_PARAM_Q);
			if ( m_hw_shader_param_q > 0 ) {
				m_shader_param_q = m_hw_shader_param_q;
			}

			m_hw_shader_param_has_z        = (m_hw_shader_type & 0x01);
			m_hw_shader_param_has_tex_cord = (m_hw_shader_type & 0x02);
			m_hw_shader_param_has_color    = (m_hw_shader_type & 0x04);
		}
	}

	// 描画実施
	void DrawHw(uint32_t bank)
	{
		uint32_t addr;

		// edge
		addr = GetHwParamAddr(bank, 1);
		for ( auto& rc : m_coeffsEdge ) {
			WriteHwRasterizerParameter(addr, rc.GetRasterizerParameter(m_width));
		}

		// shader param
		addr = GetHwParamAddr(bank, 2);
		for ( auto& rcs : m_coeffsShader ) {
			std::vector<RasterizerParameter>	rps;
			if ( m_hw_shader_param_has_z ) {
				WriteHwRasterizerParameter(addr, rcs[0].GetRasterizerParameter(m_width));
			}
			if ( m_hw_shader_param_has_tex_cord ) {
				WriteHwRasterizerParameter(addr, rcs[1].GetRasterizerParameter(m_width));
				WriteHwRasterizerParameter(addr, rcs[2].GetRasterizerParameter(m_width));
			}
			if ( m_hw_shader_param_has_color ) {
				WriteHwRasterizerParameter(addr, rcs[3].GetRasterizerParameter(m_width));
				WriteHwRasterizerParameter(addr, rcs[4].GetRasterizerParameter(m_width));
				WriteHwRasterizerParameter(addr, rcs[5].GetRasterizerParameter(m_width));
			}
		}

		// region
		addr = GetHwParamAddr(bank, 3);
		for ( uint32_t index = 0; index < m_hw_polygon_num; ++index ) {
			if ( (size_t)index < m_polygon.size() ) {
				// bitマスク生成
				unsigned long edge_flag = 0;
				unsigned long pol_flag  = 0;
				for ( auto& r : m_polygon[index].region ) {
					edge_flag |= (1 << r.edge);
					if ( r.inverse ) {
						pol_flag |= (1 << r.edge);
					}
				}
				WriteHwWord(addr, edge_flag);	addr += 4;
				WriteHwWord(addr, pol_flag);	addr += 4;
			}
			else {
				WriteHwWord(addr, 0);	addr += 4;
				WriteHwWord(addr, 0);	addr += 4;
			}
		}
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


#if 0

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
			*addr++ = (int)rps[0].dx;
			*addr++ = (int)(rps[0].dy - (rps[0].dx * (TI)(width - 1)));
			*addr++ = (int)rps[0].c;

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

#endif
