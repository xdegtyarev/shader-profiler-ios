#import "ES2Renderer.h"
#import "Shaders.h"
#include "matrix.h"
#include <mach/mach_time.h>

typedef   signed long long Prof_Int64;
mach_timebase_info_data_t s_TimeInfo;
static float MachToMillisecondsDelta (Prof_Int64 delta)
{
	delta *= s_TimeInfo.numer;
	delta /= s_TimeInfo.denom;
	float result = (float)delta / 1000000.0F;
	return result;
}
static Prof_Int64 s_TimeAcc;

// ---- rendering
enum {
	kUniformMatrixMVP,
	kUniformMatrixObject2World,
	kUniformVecWorldLightDir,
	kUniformVecWorldCamPos,
	kUniformFloatReflStrength,
	kUniformFloatEmission,
	kUniformTexColor,
	kUniformTexRamp,
	kUniformTexRefl,
	kUniformCount
};

typedef enum {
    RGB565,
    RGB888,
    RGBA4444,
    RGBA8888
} eTextureFormat;

static eTextureFormat format = RGBA8888;

static const char* kUniformNames[kUniformCount] = {
	"u_mvp",
	"u_object2world",
	"u_worldlightdir",
	"u_worldcampos",
	"u_reflStrength",
	"u_emission",
	"u_texColor",
	"u_texRamp",
	"u_texRefl",
};
static GLint g_Uniforms[kUniformCount];

const int kGrid = 2;
const int kVertices = kGrid * kGrid;
const int kIndices = (kGrid-1)*(kGrid-1)*6 * 2;

static float kVBPosition[kVertices*3];
static float kVBNormal[kVertices*3];
static float kVBUV[kVertices*2];
static unsigned short kIB[kIndices];
static GLuint vbo,ibo;
static GLuint tex1,tex2,tex3;
static void InitializeMesh ()
{
	int idx = 0;
	for (int y = 0; y < kGrid; ++y)
	{
		for (int x = 0; x < kGrid; ++x, ++idx)
		{
			float u = float(x)/(kGrid-1);
			float v = float(y)/(kGrid-1);
			kVBPosition[idx*3+0] = (u*2.0f-1.0f);
			kVBPosition[idx*3+1] = (v*2.0f-1.0f);
			kVBPosition[idx*3+2] = 0.0f;
			kVBNormal[idx*3+0] = 0.0f;
			kVBNormal[idx*3+1] = 0.0f;
			kVBNormal[idx*3+2] = 1.0f;
			kVBUV[idx*2+0] = u*3.0f;
			kVBUV[idx*2+1] = v*3.0f;
		}
	}
	idx = 0;
    for (int z = 0; z < 2; ++z){
	for (int y = 0; y < kGrid-1; ++y)
	{
		for (int x = 0; x < kGrid-1; ++x, idx+=6)
		{
			int base = 0;
			kIB[idx+0] = base;
			kIB[idx+1] = base+kGrid;
			kIB[idx+2] = base+1;
			kIB[idx+3] = base+kGrid;
			kIB[idx+4] = base+1;
			kIB[idx+5] = base+kGrid+1;
		}
	}
    }
    
    glGenBuffers(1, &vbo);
    glGenBuffers(1, &ibo);
    
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(kVBPosition) + sizeof(kVBNormal) + sizeof(kVBUV), NULL, GL_STATIC_DRAW);
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(kVBPosition), kVBPosition);
    glBufferSubData(GL_ARRAY_BUFFER, sizeof(kVBPosition), sizeof(kVBNormal), kVBNormal);
    glBufferSubData(GL_ARRAY_BUFFER, sizeof(kVBPosition)+sizeof(kVBNormal), sizeof(kVBUV), kVBUV);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(kIB), kIB, GL_STATIC_DRAW);
}


static void SetupMatrices (const float model[16], const float cam[16], const float proj[16])
{
	float view[16], modelview[16], mvp[16];
	mat4f_Invert3D (cam, view);
	mat4f_MultiplyMat4f (view, model, modelview);
	mat4f_MultiplyMat4f (proj, modelview, mvp);
	glUniformMatrix4fv (g_Uniforms[kUniformMatrixMVP], 1, GL_FALSE, mvp);
	glUniformMatrix4fv (g_Uniforms[kUniformMatrixObject2World], 1, GL_FALSE, model);
}




@interface ES2Renderer (PrivateMethods)
- (BOOL) loadShaders;
@end

@implementation ES2Renderer

// Create an ES 2.0 context
- (id <ESRenderer>) init
{
	if (self = [super init])
	{
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        if (!context || ![EAGLContext setCurrentContext:context] || ![self loadShaders])
		{
            [self release];
            return nil;
        }
		
		// Create default framebuffer object. The backing will be allocated for the current layer in -resizeFromLayer
		glGenFramebuffers(1, &defaultFramebuffer);
		glGenRenderbuffers(1, &colorRenderbuffer);
		glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
		glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
		InitializeMesh ();
	}
	
	return self;
}

- (void)render
{
    [EAGLContext setCurrentContext:context];
    
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
    glViewport(0, 0, backingWidth, backingHeight);
    
    glClearColor(0.5f, 0.4f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
	
	// use shader program
	glUseProgram(program.prog);
    
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
	
	// update attribute values
	glVertexAttribPointer (kAttrPosition, 3, GL_FLOAT, false, 0, 0);
	glEnableVertexAttribArray(kAttrPosition);
	glVertexAttribPointer (kAttrNormal, 3, GL_FLOAT, false, 0, (void*)sizeof(kVBPosition));
	glEnableVertexAttribArray(kAttrNormal);
	glVertexAttribPointer (kAttrUV, 2, GL_FLOAT, false, 0, (void*)(sizeof(kVBPosition)+sizeof(kVBNormal)));
	glEnableVertexAttribArray(kAttrUV);
	
    glActiveTexture (GL_TEXTURE0);

	glBindTexture (GL_TEXTURE_2D, tex1);
    glUniform1i (g_Uniforms[kUniformTexColor], 0);
    glActiveTexture (GL_TEXTURE1);
	glBindTexture (GL_TEXTURE_2D, tex2);
    glUniform1i (g_Uniforms[kUniformTexRamp], 1);
    glActiveTexture (GL_TEXTURE2);
	glBindTexture (GL_TEXTURE_2D, tex3);
    glUniform1i (g_Uniforms[kUniformTexRefl], 2);
	
	// setup matrices
	float rot1[16], rot2[16], model[16], proj[16], cam[16];
	mat4f_LoadPerspective (0.45f, 2.0f/3.0f, 0.01f, 100.0f, proj);
	mat4f_LoadZRotation (rotz, rot1);
	mat4f_LoadXRotation (-M_PI*0.25f, rot2);
	mat4f_MultiplyMat4f (rot2, rot1, model);
	mat4f_LoadXRotation (-M_PI*0.25f, cam);

	cam[13] = 1.6f;
	cam[14] = 2.0f;
	SetupMatrices (model, cam, proj);
	
	float lx = 0.3f, ly=-1.0f, lz=1.0f;
	float invlen = 1.0f / sqrt(lx*lx+ly*ly+lz*lz);
	lx *= invlen; ly *= invlen; lz *= invlen;
	
	glUniform4f (g_Uniforms[kUniformVecWorldLightDir], -lx, -ly, -lz, 0.0f);
	glUniform4f (g_Uniforms[kUniformVecWorldCamPos], cam[12], cam[13], cam[14], 1.0f);
	glUniform1f (g_Uniforms[kUniformFloatEmission], 0.75f);
    glUniform1f (g_Uniforms[kUniformFloatReflStrength], 0.75f);
	
    static bool s_ProfilerInitialized = false;
	if (!s_ProfilerInitialized)
	{
		mach_timebase_info(&s_TimeInfo);
		s_ProfilerInitialized = true;
	}
	static int s_FrameCount = 0;
	Prof_Int64 time0 = 0, time1 = 0;
	time0 = mach_absolute_time();

	
	// draw
	glDrawElements(GL_TRIANGLES, kIndices, GL_UNSIGNED_SHORT, 0);
	
	rotz += 0.3f * M_PI / 180.0f;
//	rotz = 0;

	glFinish ();
        
    
    
	time1 = mach_absolute_time();
	Prof_Int64 deltaTime = time1-time0;
	
    [context presentRenderbuffer:GL_RENDERBUFFER];
	
	if (s_FrameCount == 100)
	{
		printf("frametime avg: %4.2fms\n", MachToMillisecondsDelta(s_TimeAcc/100));
		s_TimeAcc = 0;
		s_FrameCount = 0;
	}
	s_TimeAcc += deltaTime;
	++s_FrameCount;
}

static GLuint LoadTexture (NSString* path)
{
    GLuint texId;
    glGenTextures(1, &texId);
    NSData *texData = [[NSData alloc] initWithContentsOfFile:path];
    UIImage *image = [[UIImage alloc] initWithData:texData];
    if (image == nil)
		return 0;
    GLuint width = CGImageGetWidth(image.CGImage);
    GLuint height = CGImageGetHeight(image.CGImage);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *imageData = malloc( height * width * 4 );
    CGContextRef context = CGBitmapContextCreate( imageData, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big );
    CGColorSpaceRelease( colorSpace );
    CGContextClearRect( context, CGRectMake( 0, 0, width, height ) );
    CGContextTranslateCTM( context, 0, height - height );
    CGContextDrawImage( context, CGRectMake( 0, 0, width, height ), image.CGImage );
    CGContextRelease(context);
    void *tempData = NULL;
    uint32_t *inPixel32;
    uint16_t *outPixel16;
    GLenum glTexFormat =  GL_RGBA;
    GLenum glInternalTexFormat =  GL_RGBA;
    GLenum glDataFormat = GL_UNSIGNED_BYTE;

    format = RGBA8888;
    switch (format)
    {
        case RGB565:
            tempData = malloc(height * width * 2);
            inPixel32 = (unsigned int*)imageData;
            outPixel16 = (unsigned short*)tempData;
            for(unsigned int i = 0; i < width * height; ++i, ++inPixel32)
                *outPixel16++ = ((((*inPixel32 >> 0) & 0xFF) >> 3) << 11) | ((((*inPixel32 >> 8) & 0xFF) >> 2) << 5) | ((((*inPixel32 >> 16) & 0xFF) >> 3) << 0);
            glTexFormat =  GL_RGB;
            glInternalTexFormat = GL_RGB;
            glDataFormat = GL_UNSIGNED_SHORT_5_6_5;
            break;

        case RGB888:{
            tempData = malloc(height * width * 3);
            char *inData = (char*)imageData;
            char *outData = (char*)tempData;
            int j=0;
            for(unsigned int i = 0; i < width * height *4; i++) {
                outData[j++] = inData[i++];
                outData[j++] = inData[i++];
                outData[j++] = inData[i++];
            }
            glTexFormat =  GL_RGB;
            glInternalTexFormat = GL_RGB;
            glDataFormat = GL_UNSIGNED_BYTE;
            }
            break;
            
        case RGBA4444:
        {
            tempData = malloc(height * width * 2);
            inPixel32 = (unsigned int*)imageData;
            outPixel16 = (unsigned short*)tempData;
            for(unsigned int i = 0; i < width * height; ++i, ++inPixel32){
                *outPixel16++ = ((((*inPixel32 >> 0) & 0xFF) >> 4) << 12) | ((((*inPixel32 >> 8) & 0xFF) >> 4) << 8) |((((*inPixel32 >> 16) & 0xFF) >> 4) << 4) |((((*inPixel32 >> 24) & 0xFF) >> 4) << 0);
            }
            glTexFormat = GL_RGBA;
            glInternalTexFormat = GL_RGBA;
            glDataFormat = GL_UNSIGNED_SHORT_4_4_4_4;
        }
            break;
        case  RGBA8888:{
            tempData = imageData;
        }
    }
    

    
	glBindTexture (GL_TEXTURE_2D, texId);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexImage2D(GL_TEXTURE_2D, 0, glInternalTexFormat, width, height, 0, glTexFormat, glDataFormat, tempData);

    free(imageData);
    [image release];
    [texData release];
    return texId;
}

- (BOOL)loadShaders {
	
	// create shader program
	if (!LoadShader ([[NSBundle mainBundle] pathForResource:@"shader" ofType:@"txt"], &program))
	{
		return NO;
	}
	
	// get uniform locations
	for (int i = 0; i < kUniformCount; ++i)
		g_Uniforms[i] = glGetUniformLocation(program.prog, kUniformNames[i]);
	
	// create textures

	tex1 = LoadTexture ([[NSBundle mainBundle] pathForResource:@"TNT_DIFFUSE_0" ofType:@"png"]);
	tex2 = LoadTexture ([[NSBundle mainBundle] pathForResource:@"SHADOW_ramp_0" ofType:@"png"]);
	tex3 = LoadTexture ([[NSBundle mainBundle] pathForResource:@"SPECULAR_0b" ofType:@"png"]);
//    PVRTexture *pvrTexture = [[PVRTexture pvrTextureWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DIFFUSE" ofType:@"pvr"]]retain];
//    tex1 = pvrTexture.name;
//    pvrTexture = [[PVRTexture pvrTextureWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"SHADOW" ofType:@"pvr"]] retain];
//	tex2 = pvrTexture.name;
//    pvrTexture = [[PVRTexture pvrTextureWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"SPECULAR" ofType:@"pvr"]]retain];
//	tex3 = pvrTexture.name;
    NSLog(@"%x", glGetError());
	return YES;
}

- (BOOL) resizeFromLayer:(CAEAGLLayer *)layer
{
	// Allocate color buffer backing based on the current layer size
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
	
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
	{
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return NO;
    }
	
    return YES;
}

- (void) dealloc
{
	// tear down GL
	if (defaultFramebuffer)
	{
		glDeleteFramebuffers(1, &defaultFramebuffer);
		defaultFramebuffer = 0;
	}
	
	if (colorRenderbuffer)
	{
		glDeleteRenderbuffers(1, &colorRenderbuffer);
		colorRenderbuffer = 0;
	}
	
	// realease the shader program object
	DestroyShader (&program);
	
	// tear down context
	if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
	
	[context release];
	context = nil;
	
	[super dealloc];
}

@end
