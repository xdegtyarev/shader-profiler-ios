#include <math.h>
#include "matrix.h"

void mat4f_LoadIdentity(float* m)
{
	m[0] = 1.0f;
	m[1] = 0.0f;
	m[2] = 0.0f;
	m[3] = 0.0f;
	
	m[4] = 0.0f;
	m[5] = 1.0f;
	m[6] = 0.0f;
	m[7] = 0.0f;
	
	m[8] = 0.0f;
	m[9] = 0.0f;
	m[10] = 1.0f;
	m[11] = 0.0f;	

	m[12] = 0.0f;
	m[13] = 0.0f;
	m[14] = 0.0f;
	m[15] = 1.0f;
}

void mat4f_LoadTranslation(float x, float y, float z, float* mout)
{
    mout[0] = 1.0f;
    mout[1] = 0.0f;
    mout[2] = 0.0f;
    mout[3] = 0.0f;
    
    mout[4] = 0.0f;
    mout[5] = 1.0f;
    mout[6] = 0.0f;
    mout[7] = 0.0f;
    
    mout[8] = 0.0f;
    mout[9] = 0.0f;
    mout[10] = 1.0f;
    mout[11] = 0.0f;    
    
    mout[12] = x;
    mout[13] = y;
    mout[14] = z;
    mout[15] = 1.0f;
}

void mat4f_LoadXRotation(float radians, float* mout)
{
	float cosrad = cosf(radians);
	float sinrad = sinf(radians);
	
	mout[0] = 1.0f;
	mout[1] = 0.0f;
	mout[2] = 0.0f;
	mout[3] = 0.0f;
	
	mout[4] = 0.0f;
	mout[5] = cosrad;
	mout[6] = sinrad;
	mout[7] = 0.0f;
	
	mout[8] = 0.0f;
	mout[9] = -sinrad;
	mout[10] = cosrad;
	mout[11] = 0.0f;	
	
	mout[12] = 0.0f;
	mout[13] = 0.0f;
	mout[14] = 0.0f;
	mout[15] = 1.0f;
}

void mat4f_LoadZRotation(float radians, float* mout)
{
	float cosrad = cosf(radians);
	float sinrad = sinf(radians);
	
	mout[0] = cosrad;
	mout[1] = sinrad;
	mout[2] = 0.0f;
	mout[3] = 0.0f;
	
	mout[4] = -sinrad;
	mout[5] = cosrad;
	mout[6] = 0.0f;
	mout[7] = 0.0f;
	
	mout[8] = 0.0f;
	mout[9] = 0.0f;
	mout[10] = 1.0f;
	mout[11] = 0.0f;	
	
	mout[12] = 0.0f;
	mout[13] = 0.0f;
	mout[14] = 0.0f;
	mout[15] = 1.0f;
}

void mat4f_LoadPerspective(float fov_radians, float aspect, float zNear, float zFar, float* mout)
{
    float f = 1.0f / tanf(fov_radians/2.0f);
    
    mout[0] = f / aspect;
    mout[1] = 0.0f;
    mout[2] = 0.0f;
    mout[3] = 0.0f;
    
    mout[4] = 0.0f;
    mout[5] = f;
    mout[6] = 0.0f;
    mout[7] = 0.0f;
    
    mout[8] = 0.0f;
    mout[9] = 0.0f;
    mout[10] = (zFar+zNear) / (zNear-zFar);
    mout[11] = -1.0f;
    
    mout[12] = 0.0f;
    mout[13] = 0.0f;
    mout[14] = 2 * zFar * zNear /  (zNear-zFar);
    mout[15] = 0.0f;
}

void mat4f_LoadOrtho(float left, float right, float bottom, float top, float near, float far, float* mout)
{
	float r_l = right - left;
	float t_b = top - bottom;
	float f_n = far - near;
	float tx = - (right + left) / (right - left);
	float ty = - (top + bottom) / (top - bottom);
	float tz = - (far + near) / (far - near);

	mout[0] = 2.0f / r_l;
	mout[1] = 0.0f;
	mout[2] = 0.0f;
	mout[3] = 0.0f;
	
	mout[4] = 0.0f;
	mout[5] = 2.0f / t_b;
	mout[6] = 0.0f;
	mout[7] = 0.0f;
	
	mout[8] = 0.0f;
	mout[9] = 0.0f;
	mout[10] = -2.0f / f_n;
	mout[11] = 0.0f;
	
	mout[12] = tx;
	mout[13] = ty;
	mout[14] = tz;
	mout[15] = 1.0f;
}

void mat4f_MultiplyMat4f(const float* a, const float* b, float* mout)
{
	mout[0]  = a[0] * b[0]  + a[4] * b[1]  + a[8] * b[2]   + a[12] * b[3];
	mout[1]  = a[1] * b[0]  + a[5] * b[1]  + a[9] * b[2]   + a[13] * b[3];
	mout[2]  = a[2] * b[0]  + a[6] * b[1]  + a[10] * b[2]  + a[14] * b[3];
	mout[3]  = a[3] * b[0]  + a[7] * b[1]  + a[11] * b[2]  + a[15] * b[3];

	mout[4]  = a[0] * b[4]  + a[4] * b[5]  + a[8] * b[6]   + a[12] * b[7];
	mout[5]  = a[1] * b[4]  + a[5] * b[5]  + a[9] * b[6]   + a[13] * b[7];
	mout[6]  = a[2] * b[4]  + a[6] * b[5]  + a[10] * b[6]  + a[14] * b[7];
	mout[7]  = a[3] * b[4]  + a[7] * b[5]  + a[11] * b[6]  + a[15] * b[7];

	mout[8]  = a[0] * b[8]  + a[4] * b[9]  + a[8] * b[10]  + a[12] * b[11];
	mout[9]  = a[1] * b[8]  + a[5] * b[9]  + a[9] * b[10]  + a[13] * b[11];
	mout[10] = a[2] * b[8]  + a[6] * b[9]  + a[10] * b[10] + a[14] * b[11];
	mout[11] = a[3] * b[8]  + a[7] * b[9]  + a[11] * b[10] + a[15] * b[11];

	mout[12] = a[0] * b[12] + a[4] * b[13] + a[8] * b[14]  + a[12] * b[15];
	mout[13] = a[1] * b[12] + a[5] * b[13] + a[9] * b[14]  + a[13] * b[15];
	mout[14] = a[2] * b[12] + a[6] * b[13] + a[10] * b[14] + a[14] * b[15];
	mout[15] = a[3] * b[12] + a[7] * b[13] + a[11] * b[14] + a[15] * b[15];
}



#define MAT(m,r,c) (m)[(c)*4+(r)]

#define RETURN_ZERO \
{ \
for (int i=0;i<16;i++) \
out[i] = 0.0F; \
return false; \
}

// Invert 3D transformation matrix (not perspective). Adapted from graphics gems 2.
// Inverts upper left by calculating its determinant and multiplying it to the symmetric
// adjust matrix of each element. Finally deals with the translation by transforming the
// original translation using by the calculated inverse.
bool mat4f_Invert3D (const float* in, float* out)
{
	float pos, neg, t;
	float det;
	
	// Calculate the determinant of upper left 3x3 sub-matrix and
	// determine if the matrix is singular.
	pos = neg = 0.0;
	t =  MAT(in,0,0) * MAT(in,1,1) * MAT(in,2,2);
	if (t >= 0.0) pos += t; else neg += t;
	
	t =  MAT(in,1,0) * MAT(in,2,1) * MAT(in,0,2);
	if (t >= 0.0) pos += t; else neg += t;
	
	t =  MAT(in,2,0) * MAT(in,0,1) * MAT(in,1,2);
	if (t >= 0.0) pos += t; else neg += t;
	
	t = -MAT(in,2,0) * MAT(in,1,1) * MAT(in,0,2);
	if (t >= 0.0) pos += t; else neg += t;
	
	t = -MAT(in,1,0) * MAT(in,0,1) * MAT(in,2,2);
	if (t >= 0.0) pos += t; else neg += t;
	
	t = -MAT(in,0,0) * MAT(in,2,1) * MAT(in,1,2);
	if (t >= 0.0) pos += t; else neg += t;
	
	det = pos + neg;
	
	if (det*det < 1e-25)
		RETURN_ZERO;
	
	det = 1.0F / det;
	MAT(out,0,0) = (  (MAT(in,1,1)*MAT(in,2,2) - MAT(in,2,1)*MAT(in,1,2) )*det);
	MAT(out,0,1) = (- (MAT(in,0,1)*MAT(in,2,2) - MAT(in,2,1)*MAT(in,0,2) )*det);
	MAT(out,0,2) = (  (MAT(in,0,1)*MAT(in,1,2) - MAT(in,1,1)*MAT(in,0,2) )*det);
	MAT(out,1,0) = (- (MAT(in,1,0)*MAT(in,2,2) - MAT(in,2,0)*MAT(in,1,2) )*det);
	MAT(out,1,1) = (  (MAT(in,0,0)*MAT(in,2,2) - MAT(in,2,0)*MAT(in,0,2) )*det);
	MAT(out,1,2) = (- (MAT(in,0,0)*MAT(in,1,2) - MAT(in,1,0)*MAT(in,0,2) )*det);
	MAT(out,2,0) = (  (MAT(in,1,0)*MAT(in,2,1) - MAT(in,2,0)*MAT(in,1,1) )*det);
	MAT(out,2,1) = (- (MAT(in,0,0)*MAT(in,2,1) - MAT(in,2,0)*MAT(in,0,1) )*det);
	MAT(out,2,2) = (  (MAT(in,0,0)*MAT(in,1,1) - MAT(in,1,0)*MAT(in,0,1) )*det);
	
	// Do the translation part
	MAT(out,0,3) = - (MAT(in,0,3) * MAT(out,0,0) +
					  MAT(in,1,3) * MAT(out,0,1) +
					  MAT(in,2,3) * MAT(out,0,2) );
	MAT(out,1,3) = - (MAT(in,0,3) * MAT(out,1,0) +
					  MAT(in,1,3) * MAT(out,1,1) +
					  MAT(in,2,3) * MAT(out,1,2) );
	MAT(out,2,3) = - (MAT(in,0,3) * MAT(out,2,0) +
					  MAT(in,1,3) * MAT(out,2,1) +
					  MAT(in,2,3) * MAT(out,2,2) );
	
	MAT(out,3,0) = 0.0f;
	MAT(out,3,1) = 0.0f;
	MAT(out,3,2) = 0.0f;
	MAT(out,3,3) = 1.0f;
	
	return true;
}

#undef MAT
#undef RETURN_ZERO
