#ifndef SHADERS_H
#define SHADERS_H

#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

enum ShaderAttrib {
	kAttrPosition = 0,
	kAttrNormal,
	kAttrTangent,
	kAttrUV,
	kAttrCount
};

struct Shader {
	GLint vertShader;
	GLint fragShader;
	GLint prog;
};

bool LoadShader (NSString* file, Shader* oshader);
void DestroyShader (Shader* shader);

GLint validateProgram(GLuint prog);

#endif
