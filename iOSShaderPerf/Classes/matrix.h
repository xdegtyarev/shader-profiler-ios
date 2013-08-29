#ifndef MATRIX_H
#define MATRIX_H

void mat4f_LoadIdentity(float* m);
void mat4f_LoadTranslation(float x, float y, float z, float* mout);
void mat4f_LoadXRotation(float radians, float* mout);
void mat4f_LoadZRotation(float radians, float* mout);
void mat4f_LoadPerspective(float fov_radians, float aspect, float zNear, float zFar, float* mout);
void mat4f_LoadOrtho(float left, float right, float bottom, float top, float near, float far, float* mout);
void mat4f_MultiplyMat4f(const float* a, const float* b, float* mout);
bool mat4f_Invert3D (const float* a, float* mout);

#endif
