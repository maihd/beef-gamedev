/*
Beef GameFX LDtk parser - v0.1 - https://github.com/maihd/beef-gamedev

NOTES

    This library use global allocations.

LICENSE

    See end of file for license information.

RECENT REVISION HISTORY:

    0.1 (2024-06-28) designing the API

============================    Contributors    =========================
Basic functional
    MaiHD

-- Contributing are welcome --
*/


using System;
using System.Diagnostics;

enum LDtkDirection
{
    North,
    East,
    South,
    West
}

enum LDtkWorldLayout
{
    Free,
    GridVania,
    LinearHorizontal,
    LinearVertical
}

[Packed]
struct LDtkColor
{
    public uint8 r;
    public uint8 g;
    public uint8 b;
    public uint8 a;

	[Inline]
	public this(uint8 r, uint8 g, uint8 b, uint8 a)
	{
		this.r = r;
		this.g = g;
		this.b = b;
		this.a = a;
	}

	[Inline]
	static uint8 HexFromChar(char8 x)
	{
		mixin X(bool b)
		{
			(b ? 1 : 0)
		}

	    return (.)(X!(x >= 'a' && x <= 'f') * (x - 'a') + X!(x >= 'A' && x <= 'F') * (x - 'A') + X!(x >= '0' && x <= '9') * (x - '0'));
	}

	[Inline]
	public this(uint32 value)
	{
		this.r = .((value >> 16));
		this.g = .((value >> 8) & 0xff);
		this.b = .(value & 0xff);
		this.a = 0xff;
	}

	[Inline]
	public this(StringView value)
	{
		var value;

	    if (value.IsEmpty)
	    {
	        this = default;
	        return;
	    }

	    if (value[0] == '#')
	    {
	        value.Ptr++;
			value.Length--;
	    }

	    let length = value.Length;
	    if (length != 6 && length != 8)
	    {
			this = default;
	        return;
	    }

	    this.r = .(HexFromChar(value[0]) << 4) | HexFromChar(value[1]);
	    this.g = .(HexFromChar(value[2]) << 4) | HexFromChar(value[3]);
	    this.b = .(HexFromChar(value[4]) << 4) | HexFromChar(value[5]);

	    if (length == 8)
	    {
	        this.a = .((uint16)HexFromChar(value[6]) << 4) | HexFromChar(value[7]);
	    }
	    else
	    {
	        this.a = 0xff;
	    }
	}
}

struct LDtkEnumValue
{
    public StringView    name;
    public LDtkColor     color;
    public int32         tileId;
}

struct LDtkEnum
{
    public int32        		id;
    public StringView   		name;
    public int32        		tilesetId;

    public StringView     		externalPath;
    public StringView     		externalChecksum;

    public Span<LDtkEnumValue> 	values;
}

struct LDtkEntity
{
    public StringView		name;
	public int32			defId;

	public int32			x;
	public int32			y;
	public int32			width;
	public int32			height;

	public int32			gridX;
	public int32			gridY;

	public int32			pivotX;
	public int32			pivotY;

	public int32			worldX;
	public int32			worldY;
}

struct LDtkTile
{
    public int32     	id;
    public int32     	coordId;

    public int32     	x;
    public int32     	y;

    public int32     	worldX;
    public int32     	worldY;
    
    public int32     	textureX;
    public int32     	textureY;
    
    public bool         flipX;
    public bool         flipY;
}

struct LDtkIntGridValue
{
    public StringView 	name;
    public int32     	value;
    public LDtkColor   	color;
}

struct LDtkTileset
{
    public int32     	id;		// Id define by LDtk
	public int32		index;	// Index in world

	public StringView   name;   // Name of tileset
    public StringView 	path;   // Relative path to image file

    public int32     	width;
    public int32     	height;

    public int32     	tileSize;
    public int32     	spacing;
    public int32     	padding;

    public int32     	tagsEnumId;
}

enum LDtkLayerType
{
	Tiles,
	IntGrid,
	Entities,
	AutoLayer,
}

struct LDtkLayer
{
    public StringView				name;
	public LDtkLayerType			type;

	public int32					levelId;
	public int32					layerDefId;

    public int32					cols;
    public int32					rows;
    public int32					tileSize;

    public int32					offsetX;
    public int32					offsetY;

    public float					tilePivotX;
    public float					tilePivotY;

    public int32					visible;
    public float					opacity;

    public LDtkTileset				tileset;
    
    public Span<LDtkTile>			tiles;

	public Span<LDtkIntGridValue>   values;

	public Span<LDtkEntity>			entities;
}

struct LDtkLevel
{
    public int32             	id;
    public StringView        	name;

    public int32             	width;
    public int32             	height;

    public int32             	worldX;
    public int32             	worldY;

    public LDtkColor           bgColor;
    public StringView         		bgPath;
    public int32             	bgPosX;
    public int32             	bgPosY;
    public float               bgCropX;
    public float               bgCropY;
    public float               bgCropWidth;
    public float               bgCropHeight;
    public float               bgScaleX;
    public float               bgScaleY;
    public float               bgPivotX;
    public float               bgPivotY;

    public Span<LDtkLayer>		layers;

    public int32[4]            neigbourCount;
    public int32[4][16]        neigbourIds;
}

struct LDtkLayerDef
{
    public int32             id;
    public StringView         name;

    public LDtkLayerType       type;

    public int32             gridSize;
    public float               opacity;

    public int32             offsetX;
    public int32             offsetY;

    public float               tilePivotX;
    public float               tilePivotY;
    public int32             tilesetDefId;

    public Span<LDtkIntGridValue>   intGridValues;
}

struct LDtkEntityDef
{
    public int32         	id;
    public StringView     	name;
    
    public int32         	width;
    public int32         	height;

    public LDtkColor       	color;
    
    public float           	pivotX;
    public float           	pivotY;
    
    public int32         	tileId;
    public int32         	tilesetId;

    public Span<StringView> tags;
}

struct LDtkWorld
{
    public LDtkWorldLayout layout;
    public LDtkColor       backgroundColor;

    public float           defaultPivotX;
    public float           defaultPivotY;
    public int32           defaultGridSize;

    public Span<LDtkTileset>    tilesets;

    public Span<LDtkEnum>       enums;

    public Span<LDtkLayerDef>   layerDefs;

    public Span<LDtkEntityDef>  entityDefs;

    public Span<LDtkLevel>      levels;
}

enum LDtkErrorCode
{
    None,
	FileNotFound,
    ParseJsonFailed,
    MissingLevels,

    MissingWorldProperties,
    InvalidWorldProperties,

    MissingLayerDefProperties,
    InvalidLayerDefProperties,

	MissingLevelExternalFile,
	InvalidLevelExternalFile,

	UnknownLayerType,

	UnnameError,
    OutOfMemory,
	InternalError,
}

struct LDtkError
{
    public LDtkErrorCode	code;
    public StringView		message;

	public this(LDtkErrorCode code, StringView message)
	{
		this.code = code;
		this.message = message;
	}
}

function LDtkError LDtkReadFileFn(StringView fileName, void* buffer, int32* bufferSize);

struct LDtkContext
{
	public void*			buffer;
	public int32			bufferSize;

	public LDtkReadFileFn	readFileFn;

	
	public static Self UseStd(void* buffer, int32 bufferSize)
	{
		return .();
	}

	public static Self GetDefault(void* buffer, int32 bufferSize)
	{
		return .();
	}

#if BF_PLATFORM_WINDOWS
	public static Self UseWindows(void* buffer, int32 bufferSize)
	{
		LDtkContext result = .{
			buffer = buffer,
			bufferSize = bufferSize,
			readFileFn = => ReadFileWindows
		};

		return result;
	}

	static LDtkError ReadFileWindows(StringView fileName, void* buffer, int32* bufferSize)
	{
		//TCHAR tFileName[MAX_PATH];
		//WideCharToMultiByte(CP_UTF8, 0, tFileName, sizeof(tFileName), fileName, 0, NULL, NULL);

		let file = System.Windows.CreateFileA(fileName.Ptr, System.Windows.GENERIC_READ, .Read, null, .Open, System.Windows.FILE_ATTRIBUTE_READONLY, 0);
		if (file == .InvalidHandle)
		{
			return .(.FileNotFound, "");
		}

		let fileSize = System.Windows.GetFileSize(file, null);
		if (buffer != null)
		{
			if (*bufferSize < fileSize)
			{
				System.Windows.CloseHandle(file);
				return .(.OutOfMemory, "");
			}

			System.Windows.ReadFile(file, (.)buffer, fileSize, var numReadBytes, null);
			if (numReadBytes == 0)
			{
				return .(.OutOfMemory, "");
			}
		}

		*bufferSize = (.)fileSize;

		System.Windows.CloseHandle(file);
		return .(.None, "");
	}
#endif

#if RAYLIB
	public static Self UseRaylib(void* buffer, int32 bufferSize)
	{
		return .();
	}
#endif
}

enum LDtkParseFlags
{
    None,
    LayerReverseOrder,
}

public static class LDtk
{
	struct Allocator
	{
		uint8*        buffer;
		int32         bufferSize;

		uint8*        lowerMarker;
		uint8*        upperMarker;

		public int remainSize => (.)(upperMarker - lowerMarker);
		public bool CanAlloc(int size) => remainSize >= size;

		public this(void* buffer, int32 bufferSize)
		{
			const int32 alignment = 16;
			const int32 mask = alignment - 1;

			Debug.Assert(buffer != null && bufferSize > 0);

			let address = (uint)buffer;
			let	misalign = address & mask;
			let	adjustment = (int32)(alignment - misalign);

			var buffer;
			var bufferSize;

			buffer = (void*)(address + (.)adjustment);
			bufferSize = bufferSize - adjustment;
			bufferSize = bufferSize - (alignment - (bufferSize & mask));

			this.buffer       = (uint8*)buffer;
			this.bufferSize   = bufferSize;
			this.lowerMarker  = (uint8*)buffer;
			this.upperMarker  = (uint8*)buffer + bufferSize;
		}

		public void DeallocLower(void* buffer, int32 size) mut
		{
			void* lastBuffer = lowerMarker - size;
			if (lastBuffer == buffer)
			{
				lowerMarker -= size;
			}
		}

		public void* AllocLower(void* oldBuffer, int32 oldSize, int32 newSize) mut
		{
			DeallocLower(oldBuffer, oldSize);

			if (newSize <= 0)
			{
				return null;
			}

			if (CanAlloc(newSize))
			{
				void* result = lowerMarker;
				lowerMarker += newSize;
				return result;
			}

			return null;
		}

		public void DeallocUpper(void* buffer, int32 size) mut
		{
			void* lastBuffer = upperMarker - size;
			if (lastBuffer == buffer)
			{
				upperMarker -= size;
			}
		}

		public void* AllocUpper(void* oldBuffer, int32 oldSize, int32 newSize) mut
		{
			DeallocLower(oldBuffer, oldSize);

			if (newSize <= 0)
			{
				return null;
			}

			if (CanAlloc(newSize))
			{
				void* result = upperMarker;
				upperMarker += newSize;
				return result;
			}

			return null;
		}

		public void* Alloc(int size, int align) mut
		{
			return AllocLower(null, 0, (.)size);
		}
	}

	public static Result<LDtkWorld, LDtkError> Parse(StringView ldtkPath, LDtkContext context, LDtkParseFlags flags)
	{
		var allocator = Allocator(context.buffer, context.bufferSize);

		char8* content = (char8*)context.buffer;
		int32 contentLength = context.bufferSize;
		let readResult = context.readFileFn(ldtkPath, content, &contentLength);
		if (readResult.code != .None)
		{
			return .Err(readResult);
		}
		content[contentLength] = 0;
		let jsonContent = StringView(content, contentLength);

		let json = scope JsonTree();
		if (Json.ReadJson(jsonContent, json) case .Err(let error))
		{
			return .Err(LDtkError(.ParseJsonFailed, error.ToString(..new:allocator String())));
		}

		LDtkWorld world = default;
		return .Ok(world);
	}
}

/*
------------------------------------------------------------------------------
MIT License

Copyright (c) 2024 MaiHD

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
------------------------------------------------------------------------------
*/