/*
Beef GameFX LDtk Raylib Rendering - v0.1 - https://github.com/maihd/beef-gamedev

NOTES

    This library use global allocations.

LICENSE

    See end of file for license information.

RECENT REVISION HISTORY:

    0.1 (2024-07-01) designing the API

============================    Contributors    =========================
Basic functional
    MaiHD

-- Contributing are welcome --
*/

using Raylib;
using System;
using System.IO;

extension LDtkContext
{
	public static LDtkContext UseRaylib(void* buffer, int32 bufferSize)
	{
		return .(){
			buffer = buffer,
			bufferSize = bufferSize,
			readFileFn = => ReadFileWindows
		};
	}

	/*
	public static LDtkError RaylibReadFile(StringView filePath, void* buffer, int32* bufferSize)
	{
		int32 readBytes = 0;
		uint8* internalBuffer = Raylib.LoadFileData(filePath.Ptr, (.)&readBytes);
		if (internalBuffer == null)
		{
			return .(.FileNotFound, "");
		}

		if (*bufferSize >= readBytes)
		{
			Internal.MemCmp(buffer, internalBuffer, readBytes);
		}

		*bufferSize = readBytes;
		Internal.Free(internalBuffer);
		return .(.None, "");
	}
	*/
}

class LDtkRenderer
{
	public LDtkWorld world;

	public void* buffer;
	public int32 bufferSize;

	public Texture[] levelBgTextures;
	public Texture[] tilesetTextures;

	public this(int32 bufferSize)
	{
		this.buffer = new uint8[bufferSize]*;
		this.bufferSize = bufferSize;
	}

	public ~this()
	{
		DeleteAndNullify!(buffer);
		bufferSize = 0;

		Unload();
	}

	public Result<void, LDtkError> Load(StringView ldtkPath)
	{
		let context = LDtkContext.UseRaylib(buffer, bufferSize);
		world = Try!(LDtk.Parse(ldtkPath, context, .LayerReverseOrder));

		let parentDir = Path.GetDirectoryPath(ldtkPath, ..scope .());

		levelBgTextures = new Texture[world.levels.Length];
		tilesetTextures = new Texture[world.tilesets.Length];

		for (let i < world.levels.Length)
		{
		    let texturePath = scope $"{parentDir}/{world.levels[i].bgPath}\0";
		    levelBgTextures[i] = LoadTexture(texturePath);
		}

		for (let i < world.tilesets.Length)
		{
		    let texturePath = scope $"{parentDir}/{world.tilesets[i].path}\0";
		    tilesetTextures[i] = LoadTexture(texturePath);
		}

		return .Ok;
	}

	public void Unload()
	{
		for (var texture in ref levelBgTextures)
		{
			texture.Unload();
		}

		for (var texture in ref tilesetTextures)
		{
			texture.Unload();
		}

		DeleteAndNullify!(levelBgTextures);
		DeleteAndNullify!(tilesetTextures);
	}

	public void DrawWorld(bool useWorldPos = false)
	{
		for (let i < world.levels.Length)
		{
			DrawLevelBackground(i, useWorldPos);
		}

		for (let i < world.levels.Length)
		{
			DrawLevel(i, useWorldPos);
		}
	}

	public void DrawLevelBackground(int levelIndex, bool useWorldPos = false)
	{
		let level = ref world.levels[levelIndex];

		if (useWorldPos)
		{
			DrawTexturePro(
				levelBgTextures[levelIndex], 
				.(level.bgCropX, level.bgCropY, level.bgCropWidth, level.bgCropHeight),
				.(level.worldX + level.bgPosX, level.worldY + level.bgPosY, level.bgScaleX * level.bgCropWidth, level.bgScaleY * level.bgCropHeight),
				.(level.bgPivotX, level.bgPivotY),
				0.0f,
				.WHITE
			);
		}
		else
		{
			/*
			DrawTexturePro(
				levelBgTextures[levelIndex], 
				.(level.bgCropX, level.bgCropY, level.bgCropWidth, level.bgCropHeight),
				.(level.bgPosX, level.bgPosY, level.bgScaleX * level.bgCropWidth, level.bgScaleY * level.bgCropHeight),
				.(level.bgPivotX, level.bgPivotY),
				0.0f,
				.WHITE
			);
			*/
		}
	}

	public void DrawLevel(int levelIndex, bool useWorldPos = false)
	{
		let level = ref world.levels[levelIndex];

		if (useWorldPos)
		{
			/*
			DrawTexturePro(
				levelBgTextures[levelIndex], 
				.(level.bgCropX, level.bgCropY, level.bgCropWidth, level.bgCropHeight),
				.(level.worldX + level.bgPosX, level.worldY + level.bgPosY, level.bgScaleX * level.bgCropWidth, level.bgScaleY * level.bgCropHeight),
				.(level.bgPivotX, level.bgPivotY),
				0.0f,
				.WHITE
			);
			*/
		}
		else
		{
			DrawTexturePro(
				levelBgTextures[levelIndex], 
				.(level.bgCropX, level.bgCropY, level.bgCropWidth, level.bgCropHeight),
				.(level.bgPosX, level.bgPosY, level.bgScaleX * level.bgCropWidth, level.bgScaleY * level.bgCropHeight),
				.(level.bgPivotX, level.bgPivotY),
				0.0f,
				.WHITE
			);
		}

		for (let layer in ref level.layers)
		{
			LDtkTileset tileset = layer.tileset;
			Texture tilesetTexture = tilesetTextures[tileset.index];

			for (let tile in layer.tiles)
			{
			    let scaleX = tile.flipX ? -1.0f : 1.0f;
			    let scaleY = tile.flipY ? -1.0f : 1.0f;

				if (useWorldPos)
				{
					DrawTextureRec(
						tilesetTexture,
						.(tile.textureX, tile.textureY, tileset.tileSize * scaleX, tileset.tileSize * scaleY),
						.(tile.worldX, tile.worldY),
						.WHITE
					);
				}
			    else
				{
					DrawTextureRec(
						tilesetTexture,
						.(tile.textureX, tile.textureY, tileset.tileSize * scaleX, tileset.tileSize * scaleY),
						.(tile.x, tile.y),
						.WHITE
					);
				}
			}

			for (let entity in layer.entities)
			{

			}
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