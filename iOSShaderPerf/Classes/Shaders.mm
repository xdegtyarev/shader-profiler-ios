#import "Shaders.h"
#include <string>

const char* kShaderAttribNames[kAttrCount] = {
	"a_position",
	"a_normal",
	"a_tangent",
	"a_uv",
};


/* Create and compile a shader from the provided source(s) */
GLint compileShader (GLint *shader, GLenum type, const char* defines, const GLchar* sources)
{
	GLint status;
	
	std::string src;
	src += defines;
	src += sources;
	const char* srcPtr = src.c_str();
	
    *shader = glCreateShader(type);				// create shader
    glShaderSource(*shader, 1, &srcPtr, NULL);	// set source code in the shader
    glCompileShader(*shader);					// compile shader
	
#if defined(DEBUG)
	GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == GL_FALSE)
	{
		NSLog(@"Failed to compile shader:\n");
		NSLog(@"%s", srcPtr);
	}
	
	return status;
}


bool LoadShader (NSString* file, Shader* oshader)
{
	oshader->prog = oshader->vertShader = oshader->fragShader = 0;
	
	const GLchar *source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
	if (!source)
	{
		NSLog(@"Failed to load shader");
		return false;
	}
	
	
	oshader->prog = glCreateProgram();

	if (!compileShader(&oshader->vertShader, GL_VERTEX_SHADER, "#define VERTEX\n", source)) {
		DestroyShader (oshader);
		return false;
	}
	
	if (!compileShader(&oshader->fragShader, GL_FRAGMENT_SHADER, "#define FRAGMENT\n", source)) {
		DestroyShader (oshader);
		return false;
	}
	
	// attach vertex shader to program
	glAttachShader(oshader->prog, oshader->vertShader);
	
	// attach fragment shader to program
	glAttachShader(oshader->prog, oshader->fragShader);
	
	for (int i = 0; i < kAttrCount; ++i)
		glBindAttribLocation (oshader->prog, i, kShaderAttribNames[i]);
	
	glLinkProgram(oshader->prog);
	
#if defined(DEBUG)
	GLint logLength;
    glGetProgramiv(oshader->prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(oshader->prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
	GLint status;
    glGetProgramiv(oshader->prog, GL_LINK_STATUS, &status);
    if (status == GL_FALSE)
		NSLog(@"Failed to link program %d", oshader->prog);
	
	return true;
}

void DestroyShader (Shader* shader)
{
	if (shader->vertShader) {
		glDeleteShader(shader->vertShader);
		shader->vertShader = 0;
	}
	if (shader->fragShader) {
		glDeleteShader(shader->fragShader);
		shader->fragShader = 0;
	}
	if (shader->prog) {
		glDeleteProgram(shader->prog);
		shader->prog = 0;
	}
}

/* Validate a program (for i.e. inconsistent samplers) */
GLint validateProgram(GLuint prog)
{
	GLint logLength, status;
	
	glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == GL_FALSE)
		NSLog(@"Failed to validate program %d", prog);
	
	return status;
}
