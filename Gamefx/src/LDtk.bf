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

    public bool						visible;
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
    public LDtkWorldLayout 		layout;
    public LDtkColor       		backgroundColor;

	public int32 				gridWidth;
	public int32				gridHeight;

    public float           		defaultPivotX;
    public float           		defaultPivotY;
    public int32           		defaultGridSize;

    public Span<LDtkTileset>    tilesets;

    public Span<LDtkEnum>       enums;

    public Span<LDtkLayerDef>   layerDefs;

    public Span<LDtkEntityDef>  entityDefs;

    public Span<LDtkLevel>      levels;

	public int32				width => gridWidth * defaultGridSize;
	public int32				height => gridHeight * defaultGridSize;
}

enum LDtkErrorCode
{
    None,
	FileNotFound,
    ParseJsonFailed,
    MissingLevels,

	MissingLevelProperties,
	InvalidLevelProperties,

    MissingWorldProperties,
    InvalidWorldProperties,

	MissingEnumDefProperties,
	InvalidEnumDefProperties,

	MissingEntityDefProperties,
	InvalidEntityDefProperties,

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

	private struct AllocUpper : this(Allocator* allocator)
	{
		public void* Alloc(int size, int align) mut
		{
			return allocator.AllocUpper(null, 0, (.)size);
		}
	}

	public static Result<LDtkWorld, LDtkError> Parse(StringView ldtkPath, LDtkContext context, LDtkParseFlags flags)
	{
		char8* content = (char8*)context.buffer;
		int32 contentLength = context.bufferSize;
		let readResult = context.readFileFn(ldtkPath, content, &contentLength);
		if (readResult.code != .None)
		{
			return .Err(readResult);
		}
		content[contentLength] = 0;
		let jsonContent = StringView(content, contentLength);
		
		var allocator = Allocator(context.buffer, context.bufferSize);

		let json = new JsonTree(); defer delete json;
		if (Json.ReadJson(jsonContent, json) case .Err(let error))
		{
			return .Err(LDtkError(.ParseJsonFailed, error.ToString(..new:allocator String())));
		}

		if (json.root case .Object(let jsonWorld))
		{
			if (!jsonWorld.TryGetValue("defs", let jsonDefsElement))
			{
			    return .Err(LDtkError(.MissingWorldProperties, "'defs' is not found"));
			}

			if (jsonDefsElement case .Object(let jsonDefs))
			{
				LDtkWorld world = Try!(ReadWorldProperties(jsonWorld));

				LDtkError readDefsError;
				readDefsError = ReadEnums(jsonDefs, ref allocator, ref world);
				if (readDefsError.code != .None)
				{
				    return .Err(readDefsError);
				}

				readDefsError = ReadTilesets(jsonDefs, ref allocator, ref world);
				if (readDefsError.code != .None)
				{
				    return .Err(readDefsError);
				}

				readDefsError = ReadLayerDefs(jsonDefs, ref allocator, ref world);
				if (readDefsError.code != .None)
				{
				    return .Err(readDefsError);
				}

				readDefsError = ReadEntityDefs(jsonDefs, ref allocator, ref world);
				if (readDefsError.code != .None)
				{
				    return .Err(readDefsError);
				}

				let readLevelsError = ReadLevels(jsonWorld, ldtkPath, ref allocator, context.readFileFn, flags, ref world);
				if (readLevelsError.code != .None)
				{
				    return .Err(readDefsError);
				}

				return .Ok(world);
			}
			else
			{
				return .Err(LDtkError(.InvalidWorldProperties, "defs must be an object"));
			}	
		}
		else
		{
			return .Err(LDtkError(.UnnameError, "LDtk json file is not well-form. Root must be an object."));
		}
	}

	private static Result<LDtkWorld, LDtkError> ReadWorldProperties(JsonObjectData json)
	{
		var world = LDtkWorld();

		world.gridWidth = (.)json["worldGridWidth"].AsNumber();
		world.gridHeight = (.)json["worldGridHeight"].AsNumber();

		if (json.TryGetValue("defaultPivotX", let jsonDefaultPivotX))
		{
			world.defaultPivotX = (.)jsonDefaultPivotX.AsNumber();
		}
		else
		{
			return .Err(LDtkError(.MissingWorldProperties, "'defaultPivotX' is not found"));
		}

		if (json.TryGetValue("defaultPivotY", let jsonDefaultPivotY))
		{
			world.defaultPivotY = (.)jsonDefaultPivotY.AsNumber();
		}
		else
		{
			return .Err(LDtkError(.MissingWorldProperties, "'defaultPivotX' is not found"));
		}

		if (json.TryGetValue("defaultGridSize", let jsonDefaultGridSize))
		{
			world.defaultGridSize = (.)jsonDefaultGridSize.AsNumber();
		}
		else
		{
			return .Err(LDtkError(.MissingWorldProperties, "'defaultGridSize' is not found"));
		}

		if (json.TryGetValue("bgColor", let jsonBgColor))
		{
			world.backgroundColor = .(jsonBgColor.AsString());
		}
		else
		{
			return .Err(LDtkError(.MissingWorldProperties, "'bgColor' is not found"));
		}

		if (!json.TryGetValue("worldLayout", let jsonWorldLayoutName))
		{
		    return .Err(LDtkError(.MissingWorldProperties, "'worldLayout' is not found"));
		}

		let worldLayoutName = jsonWorldLayoutName.AsString();
		switch (worldLayoutName)
		{
		case "Free":
			world.layout = .Free;

		case "GridVania":
			world.layout = .GridVania;

		case "LinearHorizontal":
			world.layout = .LinearHorizontal;

		case "LinearVertical":
			world.layout = .LinearVertical;

		default:
			return .Err(LDtkError(.InvalidWorldProperties, "Unknown GridLayout"));
		}

		return .Ok(world);
	}

	private static LDtkError ReadEnums(JsonObjectData jsonDefs, ref Allocator allocator, ref LDtkWorld world)
	{
		if (!jsonDefs.TryGetValue("enums", let jsonEnumsElement))
		{
		    return .(.MissingWorldProperties, "defs.enums is not found");
		}

		if (jsonEnumsElement case .Array(let jsonEnums))
		{
			let enumCount = jsonEnums.Count;
			let enums = new:allocator LDtkEnum[enumCount]*;

			for (let i < enumCount)
			{
				var enumDef = ref enums[i];
				let jsonEnum = jsonEnums[i].AsObject();

				enumDef.id = (.)jsonEnum["uid"].AsNumber();
				enumDef.name = new:allocator String(jsonEnum["identifier"].AsString());

				enumDef.tilesetId = (.)jsonEnum["iconTilesetUid"].AsNumber();

				if (jsonEnum.GetValueOrDefault("externalRelPath") case .String(let jsonExternalRelPath))
				{
					enumDef.externalPath = new:allocator String(jsonExternalRelPath);
				}

				if (jsonEnum.GetValueOrDefault("externalFileChecksum") case .String(let jsonExternalFileChecksum))
				{
					enumDef.externalChecksum = new:allocator String(jsonExternalFileChecksum);
				}
				
				if (!jsonEnum.TryGetValue("values", let jsonValuesElement))
				{
					return .(.MissingEnumDefProperties, "values");
				}

				if (jsonValuesElement case .Array(let jsonValues))
				{
					let valueCount = jsonValues.Count;
					let values = new:allocator LDtkEnumValue[valueCount]*;
					for (let j < valueCount)
					{
						var value = ref values[j];
						let jsonValue = jsonValues[j].AsObject();

						value.name = new:allocator String(jsonValue["id"].AsString());
						value.tileId = (.)jsonValue["tileId"].AsNumber();
						value.color = .((uint32)jsonValue["color"].AsNumber());
					}

					enumDef.values = .(values, valueCount);
				}
				else
				{
					return .(.InvalidEnumDefProperties, "values");
				}
			}

			world.enums = .(enums, enumCount);
			return .(.None, "");
		}
		else
		{
			return .(.InvalidWorldProperties, "defs.enums must be an array.");
		}
	}

	private static LDtkError ReadTilesets(JsonObjectData jsonDefs, ref Allocator allocator, ref LDtkWorld world)
	{
		if (!jsonDefs.TryGetValue("tilesets", let jsonTilesetsElement))
		{
		    return .(.MissingWorldProperties, "defs.tilesets is not found");
		}

		if (jsonTilesetsElement case .Array(let jsonTilesets))
		{
			let tilesetCount = jsonTilesets.Count;
			let tilesets = new:allocator LDtkTileset[tilesetCount]*;

			for (let i < tilesetCount)
			{
				var tileset = ref tilesets[i];
				let jsonTileset = jsonTilesets[i].AsObject();

				tileset.id = (.)jsonTileset["uid"].AsNumber();
				tileset.index = (.)i;
				tileset.name = new:allocator String(jsonTileset["identifier"].AsString());
				tileset.path = new:allocator String(jsonTileset["relPath"].AsString());
				tileset.width = (.)jsonTileset["pxWid"].AsNumber();
				tileset.height = (.)jsonTileset["pxHei"].AsNumber();
				tileset.tileSize = (.)jsonTileset["tileGridSize"].AsNumber();
				tileset.spacing = (.)jsonTileset["spacing"].AsNumber();
				tileset.padding = (.)jsonTileset["padding"].AsNumber();

				if (jsonTileset.TryGetValue("tagsSourceEnumUid", let jsonTagsSourceEnumUid) && jsonTagsSourceEnumUid case .Number(let tagsEnumId))
				{
				    tileset.tagsEnumId = (.)tagsEnumId;
				}
				else
				{
				    tileset.tagsEnumId = 0;
				}
			}

			world.tilesets = .(tilesets, tilesetCount);
			return .(.None, "");
		}
		else
		{
			return .(.InvalidWorldProperties, "defs.tilesets must be an array.");
		}
	}

	private static LDtkError ReadLayerDefs(JsonObjectData jsonDefs, ref Allocator allocator, ref LDtkWorld world)
	{
		if (!jsonDefs.TryGetValue("layers", let jsonLayerDefsElement))
		{
		    return .(.MissingWorldProperties, "defs.layers is not found");
		}

		if (jsonLayerDefsElement case .Array(let jsonLayerDefs))
		{
			let layerDefCount = jsonLayerDefs.Count;
			let layerDefs = new:allocator LDtkLayerDef[layerDefCount]*;

			for (let i < layerDefCount)
			{
				var layerDef = ref layerDefs[i];
				let jsonLayerDef = jsonLayerDefs[i].AsObject();

				switch (jsonLayerDef["type"].AsString())
				{
				case "Tiles":
					layerDef.type = .Tiles;

				case "IntGrid":
					layerDef.type = .IntGrid;

				case "Entities":
					layerDef.type = .Entities;

				case "AutoLayer":
					layerDef.type = .AutoLayer;
				}

				layerDef.id = (.)jsonLayerDef["uid"].AsNumber();
				layerDef.name = new:allocator String(jsonLayerDef["identifier"].AsString());

				layerDef.gridSize = (.)jsonLayerDef["gridSize"].AsNumber();
				layerDef.opacity = (.)jsonLayerDef["displayOpacity"].AsNumber();
				layerDef.offsetX = (.)jsonLayerDef["pxOffsetX"].AsNumber();
				layerDef.offsetY = (.)jsonLayerDef["pxOffsetY"].AsNumber();
				layerDef.tilePivotX = (.)jsonLayerDef["tilePivotX"].AsNumber();
				layerDef.tilePivotY = (.)jsonLayerDef["tilePivotY"].AsNumber();

				int32 tilesetDefId = -1;
				if (jsonLayerDef.TryGetValue("tilesetDefUid", var jsonIdElement) && jsonIdElement case .Number(let id))
				{
					tilesetDefId = (.)id;
				}
				if (jsonLayerDef.TryGetValue("autoTilesetDefUid", out jsonIdElement) && jsonIdElement case .Number(let id))
				{
					tilesetDefId = (.)id;
				}

				if (tilesetDefId == -1)
				{
					//return .(.MissingLayerDefProperties, "'tilesetDefId' is invalid");
				}
				layerDef.tilesetDefId = tilesetDefId;

				if (!jsonLayerDef.TryGetValue("intGridValues", let jsonIntGridValuesElement))
				{
					return .(.MissingLayerDefProperties, "'intGridValues' is invalid");
				}

				if (jsonIntGridValuesElement case .Array(let jsonIntGridValues))
				{
					let intGridValueCount = jsonIntGridValues.Count;
					let intGridValues = new:allocator LDtkIntGridValue[intGridValueCount]*;

					for (let j < intGridValueCount)
					{
						var intGridValue = ref intGridValues[j];
						let jsonIntGridValue = jsonIntGridValues[j].AsObject();

						if (jsonIntGridValue["identifier"] case .String(let name))
						{
							intGridValue.name = new:allocator String(name);
						}

						intGridValue.value = (.)jsonIntGridValue["value"].AsNumber();
						intGridValue.color = .(jsonIntGridValue["color"].AsString());
					}

					layerDef.intGridValues = .(intGridValues, intGridValueCount);
				}
				else
				{
					return .(.MissingLayerDefProperties, "'intGridValues' is invalid");
				}
			}

			world.layerDefs = .(layerDefs, layerDefCount);
			return .(.None, "");
		}
		else
		{
			return .(.InvalidWorldProperties, "defs.layers must be an array.");
		}
	}

	private static LDtkError ReadEntityDefs(JsonObjectData jsonDefs, ref Allocator allocator, ref LDtkWorld world)
	{
		if (!jsonDefs.TryGetValue("entities", let jsonEntitiesElement))
		{
		    return .(.MissingWorldProperties, "defs.entities is not found");
		}

		if (jsonEntitiesElement case .Array(let jsonEntities))
		{
			let entityDefCount = jsonEntities.Count;
			let entityDefs = new:allocator LDtkEntityDef[entityDefCount]*;

			for (let i < entityDefCount)
			{
				var entityDef = ref entityDefs[i];
				let jsonEntityDef = jsonEntities[i].AsObject();

				entityDef.id = (.)jsonEntityDef["uid"].AsNumber();
				entityDef.name = new:allocator String(jsonEntityDef["identifier"].AsString());
				entityDef.width = (.)jsonEntityDef["width"].AsNumber();
				entityDef.height = (.)jsonEntityDef["height"].AsNumber();
				entityDef.color = .(jsonEntityDef["color"].AsString());
				entityDef.pivotX = (.)jsonEntityDef["pivotX"].AsNumber();
				entityDef.pivotY = (.)jsonEntityDef["pivotY"].AsNumber();

				if (jsonEntityDef["tilesetId"] case .Number(let tilesetId))
				{
					entityDef.tilesetId = (.)tilesetId;
				}

				if (jsonEntityDef["tileId"] case .Number(let tileId))
				{
					entityDef.tileId = (.)tileId;
				}				

				if (!jsonEntityDef.TryGetValue("tags", let jsonTagsElement))
				{
					return .(.MissingEntityDefProperties, "tags is missing");
				}

				if (jsonTagsElement case .Array(let jsonTags))
				{
					let tagCount = jsonTags.Count;
					let tags = new:allocator StringView[tagCount]*;
					for (let j < tagCount)
					{
						if (jsonTags[j] case .String(let jsonTagStr))
						{
							tags[j] = new:allocator String(jsonTagStr);
						}
						else
						{
							return .(.InvalidEntityDefProperties, "tag must be string");
						}	
					}

					entityDef.tags = .(tags, tagCount);
				}
				else
				{
					return .(.InvalidEntityDefProperties, "tags must be an array");
				}
			}

			world.entityDefs = .(entityDefs, entityDefCount);
			return .(.None, "");
		}
		else
		{
			return .(.InvalidWorldProperties, "defs.entities must be an array.");
		}
	}

	private static LDtkError ReadLayer(JsonObjectData jsonLayer, ref Allocator allocator, ref LDtkLayer layer, ref LDtkLevel level, ref LDtkWorld world)
	{
		// Name & type

		layer.name = new:allocator String(jsonLayer["__identifier"].AsString());

		let type = jsonLayer["__type"].AsString();
		switch (type)
		{
		case "Tiles":
			layer.type = .Tiles;

		case "Entities":
			layer.type = .Entities;

		case "IntGrid":
			layer.type = .IntGrid;

		case "AutoLayer":
			layer.type = .AutoLayer;
		}

		// Meta ids

		layer.levelId = (.)jsonLayer["levelId"].AsNumber();
		layer.layerDefId = (.)jsonLayer["layerDefUid"].AsNumber();

		// Base properties

		layer.cols = (.)jsonLayer["__cWid"].AsNumber();
		layer.rows = (.)jsonLayer["__cHei"].AsNumber();
		layer.tileSize = (.)jsonLayer["__gridSize"].AsNumber();
		layer.opacity = (.)jsonLayer["__opacity"].AsNumber();
		layer.offsetX = (.)jsonLayer["__pxTotalOffsetX"].AsNumber();
		layer.offsetY = (.)jsonLayer["__pxTotalOffsetY"].AsNumber();
		layer.visible = jsonLayer["visible"].AsBool();

		// Read tileset

		if (layer.type != .Entities)
		{
			var haveTileset = true;

			if (!jsonLayer.TryGetValue("__tilesetDefUid", let jsonTilesetDefUid) || !(jsonTilesetDefUid case .Number))
			{
				haveTileset = false;
			}

			if (!jsonLayer.TryGetValue("__tilesetRelPath", let jsonTilesetRelPath) || !(jsonTilesetRelPath case .String))
			{
				haveTileset = false;
			}

			if (haveTileset)
			{
				var tilesetIndex = -1;
				let tilesetId = (int)jsonTilesetDefUid.AsNumber();
				for (let tileset in ref world.tilesets)
				{
					if (tileset.id == tilesetId)
					{
						tilesetIndex = tileset.index;
						break;
					}
				}

				if (tilesetIndex == -1)
				{
					return .(.UnnameError, "Missing tileset.");
				}

				var tileset = ref world.tilesets[tilesetIndex];
				tileset.path = new:allocator String(jsonTilesetRelPath.AsString());

				layer.tileset = tileset;
			}
			else
			{
				layer.tileset = default;
			}
		}
		else
		{
			layer.tileset = default;
		}

		// Read Tiles

		StringView gridTilesFieldName = ?;
		if (layer.type == .IntGrid || layer.type == .AutoLayer)
		{
			gridTilesFieldName = "autoLayerTiles";
		}
		else
		{
			gridTilesFieldName = "gridTiles";
		}

		let coordIdIndex = (layer.type == .IntGrid || layer.type == .AutoLayer) ? 1 : 0;

		if (jsonLayer.TryGetValue(gridTilesFieldName, let jsonGridTilesElement) && jsonGridTilesElement case .Array(let jsonGridTiles))
		{
			let tileCount = jsonGridTiles.Count;
			let tiles = new:allocator LDtkTile[tileCount]*;

			for (let i < tileCount)
			{
				var tile = ref tiles[i];
				let jsonTile = jsonGridTiles[i].AsObject();

				tile.id = (.)jsonTile["t"].AsNumber();

				// coordId

				if (jsonTile.TryGetValue("d", let jsonDElement) && jsonDElement case .Array(let jsonD))
				{
					if (jsonD[coordIdIndex] case .Number(let coordId))
					{
						tile.coordId = (.)coordId;
					}
					else
					{
						return .(.UnnameError, "coordId must be number");
					}
				}
				else
				{
					return .(.UnnameError, "d is missing in tile");
				}

				// Position

				if (jsonTile.TryGetValue("px", let jsonPxElement) && jsonPxElement case .Array(let jsonPx))
				{
					let jsonX = jsonPx[0];
					let jsonY = jsonPx[1];
					if (!(jsonX case .Number && jsonY case .Number))
					{
					    return .(.UnnameError, "px items must be number");
					}

					int32 x = (.)jsonX.AsNumber();
					int32 y = (.)jsonY.AsNumber();
					int32 worldX = level.worldX + x;
					int32 worldY = level.worldY + y;

					tile.x = x;
					tile.y = y;
					tile.worldX = worldX;
					tile.worldY = worldY;
				}
				else
				{
					return .(.UnnameError, "px must be array");
				}

				// Texture rect

				if (jsonTile.TryGetValue("src", let jsonSrcElement) && jsonSrcElement case .Array(let jsonSrc))
				{
					let jsonTextureX = jsonSrc[0];
					let jsonTextureY = jsonSrc[1];
					if (!(jsonTextureX case .Number && jsonTextureY case .Number))
					{
					    return .(.UnnameError, "src items must be number");
					}

					tile.textureX = (.)jsonTextureX.AsNumber();
					tile.textureY = (.)jsonTextureY.AsNumber();
				}
				else
				{
					return .(.UnnameError, "src must be array");
				}

				// Flip

				if (jsonTile.TryGetValue("f", let jsonFElement) && jsonFElement case .Number(let jsonF))
				{
					let flip = (uint32)jsonF;
					let flipX = (flip  & 1u) 		!= 0;
					let flipY = ((flip >> 1u) & 1u) != 0;

					tile.flipX = flipX;
					tile.flipY = flipY;
				}
				else
				{
					return .(.UnnameError, "f must be array");
				}
			}

			layer.tiles = .(tiles, tileCount);
		}
		else
		{
			layer.tiles = null;
		}

		// Read IntGrid

		if (jsonLayer.TryGetValue("intGridCsv", let jsonIntGridCsvElement) && jsonIntGridCsvElement case .Array(let jsonIntGridCsv))
		{
			let intGridValueCount = jsonIntGridCsv.Count;
			let intGridValues = new:allocator LDtkIntGridValue[intGridValueCount]*;

			for (let i < intGridValueCount)
			{
				if (jsonIntGridCsv[i] case .Number(let intGridIndex))
				{
					intGridValues[i].value = (.)intGridIndex;
				}
				else
				{
					return .(.UnnameError, "");
				}
			}

			layer.values = .(intGridValues, intGridValueCount);
		}
		else if (jsonLayer.TryGetValue("intGrid", let jsonIntGridElement) && jsonIntGridElement case .Array(let jsonIntGrid))
		{
			LDtkLayerDef* layerDef = null;
			for (let worldLayerDef in ref world.layerDefs)
			{
			    if (worldLayerDef.id == layer.layerDefId)
			    {
			        layerDef = &worldLayerDef;
			        break;
			    }
			}
	
			if (layerDef == null)
			{
				return .(.UnnameError, "");
			}

			let intGridValueCount = jsonIntGrid.Count;
			let intGridValues = new:allocator LDtkIntGridValue[intGridValueCount]*;

			for (let i < intGridValueCount)
			{
				if (jsonIntGrid[i] case .Object(let jsonValuePair))
				{
					if (jsonValuePair.TryGetValue("coordId", let jsonCoordIdElement) && jsonCoordIdElement case .Number(let coordId)
						&& jsonValuePair.TryGetValue("v", let jsonVElement) && jsonVElement case .Number(let v))
					{
						intGridValues[(.)coordId] = layerDef.intGridValues[(.)v];
					}
					else
					{
						return .(.UnnameError, "");
					}
				}
				else
				{
					return .(.UnnameError, "");
				}
			}

			layer.values = .(intGridValues, intGridValueCount);
		}
		else
		{
			layer.values = null;
		}

		// Read Entities

		if (jsonLayer.TryGetValue("entityInstances", let jsonEntityInstancesElement) && jsonEntityInstancesElement case .Array(let jsonEntityInstances))
		{
			let entityCount = jsonEntityInstances.Count;
			let entities = new:allocator LDtkEntity[entityCount]*;

			for (let i < entityCount)
			{
				if (jsonEntityInstances[i] case .Object(let jsonEntity))
				{
					var entity = ref entities[i];
					entity.name = new:allocator String(jsonEntity["__identifier"].AsString());
					entity.defId = (.)jsonEntity["defUid"].AsNumber();
					entity.width = (.)jsonEntity["width"].AsNumber();
					entity.height = (.)jsonEntity["height"].AsNumber();

					// Position

					if (jsonEntity.TryGetValue("px", let jsonPxElement) && jsonPxElement case .Array(let jsonPx))
					{
						entity.x = (.)jsonPx[0].AsNumber();
						entity.y = (.)jsonPx[1].AsNumber();
						entity.worldX = level.worldX + entity.x;
						entity.worldY = level.worldY + entity.y;
					}

					// Grid

					if (jsonEntity.TryGetValue("__grid", let jsonGridElement) && jsonPxElement case .Array(let jsonGrid))
					{
						entity.gridX = (.)jsonGrid[0].AsNumber();
						entity.gridY = (.)jsonGrid[1].AsNumber();
					}

					// Pivot

					if (jsonEntity.TryGetValue("__pivot", let jsonPivotElement) && jsonPxElement case .Array(let jsonPivot))
					{
						entity.pivotX = (.)jsonPivot[0].AsNumber();
						entity.pivotY = (.)jsonPivot[1].AsNumber();
					}
				}
				else
				{
					return .(.UnnameError, "");
				}
			}

			layer.entities = .(entities, entityCount);
		}
		else
		{
			layer.entities = null;
		}

		return .(.None, "");
	}

	private static LDtkError ReadLevel(JsonObjectData jsonLevel, StringView levelDirectory, ref Allocator allocator, LDtkReadFileFn readFileFn, ref LDtkLevel level, LDtkParseFlags flags, ref LDtkWorld world)
	{
		// Reading base properties

		level.id = (.)jsonLevel["uid"].AsNumber();
		level.name = new:allocator String(jsonLevel["identifier"].AsString());
		
		level.worldX = (.)jsonLevel["worldX"].AsNumber();
		level.worldY = (.)jsonLevel["worldY"].AsNumber();
		level.width = (.)jsonLevel["pxWid"].AsNumber();
		level.height = (.)jsonLevel["pxHei"].AsNumber();

		// Reading background fields

		level.bgColor = .(jsonLevel["__bgColor"].AsString());
		level.bgPath = new:allocator String(jsonLevel["bgRelPath"].AsString());
		level.bgPivotX = (.)jsonLevel["bgPivotX"].AsNumber();
		level.bgPivotY = (.)jsonLevel["bgPivotY"].AsNumber();

		if (jsonLevel.TryGetValue("__bgPos", let jsonBgPosElement) && jsonBgPosElement case .Object(let jsonBgPos))
		{
			if (jsonBgPos.TryGetValue("topLeftPx", let jsonTopLeftPxElement) && jsonBgPosElement case .Array(let jsonTopLeftPx))
			{
				level.bgPosX = (.)jsonTopLeftPx[0].AsNumber();
				level.bgPosY = (.)jsonTopLeftPx[1].AsNumber();
			}

			if (jsonBgPos.TryGetValue("scale", let jsonScaleElement) && jsonScaleElement case .Array(let jsonScale))
			{
				level.bgScaleX = (.)jsonScale[0].AsNumber();
				level.bgScaleY = (.)jsonScale[1].AsNumber();
			}

			if (jsonBgPos.TryGetValue("cropRect", let jsonCropRectElement) && jsonCropRectElement case .Array(let jsonCropRect))
			{
				level.bgCropX      = (.)jsonCropRect[0].AsNumber();
				level.bgCropY      = (.)jsonCropRect[1].AsNumber();
				level.bgCropWidth  = (.)jsonCropRect[2].AsNumber();
				level.bgCropHeight = (.)jsonCropRect[3].AsNumber();
			}
		}

		// Reading neighbours

		// Reading field instances

		// Reading layer instances

		if (!jsonLevel.TryGetValue("layerInstances", var jsonLayerInstancesElement))
		{
			return .(.MissingLevelProperties, "layerInstances is not found");
		}
		
		// Something unclear here
		// Why we donot have a field to specify that
		// Layer instances are define in other files
		if (jsonLayerInstancesElement case .Null)
		{
			let externalRelPath = jsonLevel["externalRelPath"].AsString();
			let levelFilePath = scope $"{levelDirectory}/{externalRelPath}\0";

			int32 fileSize = 0;
			var readFileError = readFileFn(levelFilePath, null, &fileSize);
			if (readFileError.code != .None)
			{
				return readFileError;
			}

			let fileBuffer = new:allocator char8[fileSize]*;
			if (fileBuffer == null)
			{
				return .(.OutOfMemory, "Cannot read file because out of memory");
			}

			readFileError = readFileFn(levelFilePath, fileBuffer, &fileSize);
			if (readFileError.code != .None)
			{
				return readFileError;
			}

			let jsonTreeLevel = new JsonTree();
			defer:: delete jsonTreeLevel;

			if (Json.ReadJson(.(fileBuffer, fileSize), jsonTreeLevel) case .Err(let error))
			{
				return .(.ParseJsonFailed, error.ToString(..new:allocator String()));
			}

			if (jsonTreeLevel.root case .Object(let jsonLevelFile))
			{
				jsonLayerInstancesElement = jsonLevelFile.GetValueOrDefault("layerInstances");
			}
			else
			{
				return .(.InvalidLevelProperties, new:allocator $"layerInstances must be object. In external file: {levelFilePath}.");
			}
		}

		if (jsonLayerInstancesElement case .Array(let jsonLayerInstances))
		{			
			let layerCount = jsonLayerInstances.Count;
			let layers = new:allocator LDtkLayer[layerCount]*;

			for (let i < layerCount)
			{
				if (jsonLayerInstances[i] case .Object(let jsonLayer))
				{
					let readError = ReadLayer(jsonLayer, ref allocator, ref layers[i], ref level, ref world);
					if (readError.code != .None)
					{
						return readError;
					}	
				}
				else
				{
					return .(.InvalidLevelProperties, "layerInstance must be object");
				}
			}	

			if (flags.HasFlag(.LayerReverseOrder))
			{
				for (let i < (layerCount >> 1))
				{
					let tmp = layers[i];
					layers[i] = layers[layerCount - i - 1];
					layers[layerCount - i - 1] = tmp;
				}
			}
			
			level.layers = .(layers, layerCount);
			return .(.None, "");
		}
		else
		{
			return .(.InternalError, "unreachable code");
		}
	}

	private static LDtkError ReadLevels(JsonObjectData jsonDefs, StringView ldtkPath, ref Allocator allocator, LDtkReadFileFn readFileFn, LDtkParseFlags flags, ref LDtkWorld world)
	{
		if (!jsonDefs.TryGetValue("levels", let jsonLevelsElement))
		{
		    return .(.MissingWorldProperties, "defs.levels is not found");
		}

		let levelDirectory = ldtkPath.Substring(0, ldtkPath.LastIndexOf('/'));

		if (jsonLevelsElement case .Array(let jsonLevels))
		{
			let levelCount = jsonLevels.Count;
			let levels = new:allocator LDtkLevel[levelCount]*;

			for (let i < levelCount)
			{
				if (jsonLevels[i] case .Object(let jsonLevel))
				{
					let readLevelError = ReadLevel(jsonLevel, levelDirectory, ref allocator, readFileFn, ref levels[i], flags, ref world);
					if (readLevelError.code != .None)
					{
						return readLevelError;
					}
				}
				else
				{
					return .(.InvalidLevelProperties, "level must be object");
				}
			}

			world.levels = .(levels, levelCount);
			return .(.None, "");
		}
		else
		{
			return .(.InvalidWorldProperties, "defs.levels must be an object.");
		}
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