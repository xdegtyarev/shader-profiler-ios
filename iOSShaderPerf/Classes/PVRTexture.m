#import "PVRTexture.h"

#define PVR_TEXTURE_FLAG_TYPE_MASK	0xff

static char gPVRTexIdentifier[4] = "PVR!";

enum
{
	kPVRTextureFlagTypePVRTC_2 = 24,
	kPVRTextureFlagTypePVRTC_4
};

typedef struct _PVRTexHeader
{
	uint32_t headerLength;
	uint32_t height;
	uint32_t width;
	uint32_t numMipmaps;
	uint32_t flags;
	uint32_t dataLength;
	uint32_t bpp;
	uint32_t bitmaskRed;
	uint32_t bitmaskGreen;
	uint32_t bitmaskBlue;
	uint32_t bitmaskAlpha;
	uint32_t pvrTag;
	uint32_t numSurfs;
} PVRTexHeader;


@implementation PVRTexture

@synthesize name = _name;
@synthesize width = _width;
@synthesize height = _height;
@synthesize internalFormat = _internalFormat;
@synthesize hasAlpha = _hasAlpha;


- (BOOL)unpackPVRData:(NSData *)data
{
	BOOL success = FALSE;
	PVRTexHeader *header = NULL;
	uint32_t flags, pvrTag;
	uint32_t dataLength = 0, dataOffset = 0, dataSize = 0;
	uint32_t blockSize = 0, widthBlocks = 0, heightBlocks = 0;
	uint32_t width = 0, height = 0, bpp = 4;
	uint8_t *bytes = NULL;
	uint32_t formatFlags;
	
	header = (PVRTexHeader *)[data bytes];
	
	pvrTag = CFSwapInt32LittleToHost(header->pvrTag);

	if (gPVRTexIdentifier[0] != ((pvrTag >>  0) & 0xff) ||
		gPVRTexIdentifier[1] != ((pvrTag >>  8) & 0xff) ||
		gPVRTexIdentifier[2] != ((pvrTag >> 16) & 0xff) ||
		gPVRTexIdentifier[3] != ((pvrTag >> 24) & 0xff))
	{
		return FALSE;
	}
	
	flags = CFSwapInt32LittleToHost(header->flags);
	formatFlags = flags & PVR_TEXTURE_FLAG_TYPE_MASK;
	formatFlags = kPVRTextureFlagTypePVRTC_4;
	if (formatFlags == kPVRTextureFlagTypePVRTC_4 || formatFlags == kPVRTextureFlagTypePVRTC_2)
	{
		[_imageData removeAllObjects];
		
		if (formatFlags == kPVRTextureFlagTypePVRTC_4)
			_internalFormat = GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG;
		else if (formatFlags == kPVRTextureFlagTypePVRTC_2)
			_internalFormat = GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG;
	
		_width = width = CFSwapInt32LittleToHost(header->width);
		_height = height = CFSwapInt32LittleToHost(header->height);
		
		if (CFSwapInt32LittleToHost(header->bitmaskAlpha))
			_hasAlpha = TRUE;
		else
			_hasAlpha = FALSE;
		
		dataLength = CFSwapInt32LittleToHost(header->dataLength);
		
		bytes = ((uint8_t *)[data bytes]) + sizeof(PVRTexHeader);
		
		// Calculate the data size for each texture level and respect the minimum number of blocks
		while (dataOffset < dataLength)
		{
			if (formatFlags == kPVRTextureFlagTypePVRTC_4)
			{
				blockSize = 4 * 4; // Pixel by pixel block size for 4bpp
				widthBlocks = width / 4;
				heightBlocks = height / 4;
				bpp = 4;
			}
			else
			{
				blockSize = 8 * 4; // Pixel by pixel block size for 2bpp
				widthBlocks = width / 8;
				heightBlocks = height / 4;
				bpp = 2;
			}
			
			// Clamp to minimum number of blocks
			if (widthBlocks < 2)
				widthBlocks = 2;
			if (heightBlocks < 2)
				heightBlocks = 2;

			dataSize = widthBlocks * heightBlocks * ((blockSize  * bpp) / 8);
			
			[_imageData addObject:[NSData dataWithBytes:bytes+dataOffset length:dataSize]];
			
			dataOffset += dataSize;
			
			width = MAX(width >> 1, 1);
			height = MAX(height >> 1, 1);
		}
				  
		success = TRUE;
	}
	
	return success;
}


- (BOOL)createGLTexture
{
	int width = _width;
	int height = _height;
	NSData *data;
	GLenum err;
	
	if ([_imageData count] > 0)
	{
		if (_name != 0)
			glDeleteTextures(1, &_name);
		
		glGenTextures(1, &_name);
		glBindTexture(GL_TEXTURE_2D, _name);
	}
	
	if ([_imageData count] > 1)
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	else
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	
	for (int i=0; i < 8 && i < _imageData.count; i++)
	{
		data = [_imageData objectAtIndex:i];
		glCompressedTexImage2D(GL_TEXTURE_2D, i, _internalFormat, width, height, 0, [data length], [data bytes]);
		
		err = glGetError();
		if (err != GL_NO_ERROR)
		{
			NSLog(@"Error uploading compressed texture level: %d. glError: 0x%04X", i, err);
			return FALSE;
		}
		
		width = MAX(width >> 1, 1);
		height = MAX(height >> 1, 1);
	}
	
	[_imageData removeAllObjects];
	
	return TRUE;
}


- (id)initWithContentsOfFile:(NSString *)path
{
	if (self = [super init])
	{
		NSData *data = [NSData dataWithContentsOfFile:path];
		
		_imageData = [[NSMutableArray alloc] initWithCapacity:10];
		
		_name = 0;
		_width = _height = 0;
		_internalFormat = GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG;
		_hasAlpha = FALSE;
		
		if (!data || ![self unpackPVRData:data] || ![self createGLTexture])
		{
			[self release];
			self = nil;
		}
	}
	
	return self;
}
-(BOOL)loadData:(NSData *)data
{
	glGenTextures(1, &_name);
	glBindTexture(GL_TEXTURE_2D, _name);
	
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glCompressedTexImage2D(GL_TEXTURE_2D, 0, GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG, 256, 256, 0, [data length], [data bytes]);
    NSLog(@"%x", glGetError());
    return YES;
}

- (id)initWithContentsOfURL:(NSURL *)url
{
	if (![url isFileURL])
	{
		[self release];
		return nil;
	}
	
	return [self initWithContentsOfFile:[url path]];
}


+ (id)pvrTextureWithContentsOfFile:(NSString *)path
{
	return [[[self alloc] initWithContentsOfFile:path] autorelease];
}


+ (id)pvrTextureWithContentsOfURL:(NSURL *)url
{
	if (![url isFileURL])
		return nil;
	
	return [PVRTexture pvrTextureWithContentsOfFile:[url path]];
}


- (void)dealloc
{
	[_imageData release];
	
	if (_name != 0)
		glDeleteTextures(1, &_name);
	
	[super dealloc];
}

@end
