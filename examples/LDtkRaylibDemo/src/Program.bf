namespace LDtkRaylibDemo;

using System;
using Raylib;

class Program : Raylib.RaylibApp
{
	static void Main()
	{
		var program = scope Program()
			{
				title = "LDtkRaylibDemo",
				width = 800,
				height = 600
			};

		program.Run();
	}

	void* buffer;
	LDtkWorld ldtkWorld;

	Texture	worldBgTexture;
	Texture[32] levelBgTextures;
	Texture[32] tilesetTextures;

	int currentLevelIndex = 0;
	LDtkLevel currentLevel;

	protected override void Init()
	{
		let bufferSize = 10 * 1024 * 1024;
		buffer = Internal.Malloc(bufferSize);

		let ldtkContext = LDtkContext.UseWindows(buffer, bufferSize);
		ldtkWorld = LDtk.Parse("assets/sample.ldtk", ldtkContext, .LayerReverseOrder).GetValueOrDefault();

		for (let i < ldtkWorld.levels.Length)
		{
		    let texturePath = scope $"assets/{ldtkWorld.levels[i].bgPath}\0";
		    levelBgTextures[i] = LoadTexture(texturePath);
		}

		for (let i < ldtkWorld.tilesets.Length)
		{
		    let texturePath = scope $"assets/{ldtkWorld.tilesets[i].path}\0";
		    tilesetTextures[i] = LoadTexture(texturePath);
		}

		worldBgTexture = LoadTexture("assets/N2D - SpaceWallpaper1280x448.png");
		SetWindowSize(worldBgTexture.width, worldBgTexture.height);

		currentLevelIndex = 0;
		currentLevel = ldtkWorld.levels[currentLevelIndex];
		SetWindowSize(currentLevel.width, currentLevel.height);
	}

	protected override void Close()
	{
		Internal.Free(buffer);
	}

	protected override void Update(float dt)
	{
		if (IsKeyPressed(.KEY_LEFT))
		{
		    if (currentLevelIndex > 0)
		    {
		        currentLevelIndex--;
		        currentLevel = ldtkWorld.levels[currentLevelIndex];
		        SetWindowSize(currentLevel.width, currentLevel.height);
		    }
			else
			{
				currentLevelIndex = -1;
				SetWindowSize(800, 600);
			}
		}

		if (IsKeyPressed(.KEY_RIGHT))
		{
		    if (currentLevelIndex < ldtkWorld.levels.Length - 1)
		    {
		        currentLevelIndex++;
		        currentLevel = ldtkWorld.levels[currentLevelIndex];
		        SetWindowSize(currentLevel.width, currentLevel.height);
		    }
			else
			{
				currentLevelIndex = ldtkWorld.levels.Length;
				SetWindowSize(800, 600);
			}
		}
	}

	protected override void Draw()
	{
		ClearBackground(.(ldtkWorld.backgroundColor.r, ldtkWorld.backgroundColor.g, ldtkWorld.backgroundColor.b, ldtkWorld.backgroundColor.a));

		if (currentLevelIndex > -1 && currentLevelIndex < ldtkWorld.levels.Length)
		{
			// Draw one level
			DrawLevel(currentLevelIndex, ref currentLevel);
		}
		else
		{
			// Draw the whole world
			//DrawTexture(worldBgTexture, 0, 0, .WHITE);

			for (let i < ldtkWorld.levels.Length)
			{
				let level = ref ldtkWorld.levels[i];

				DrawTexturePro(
					levelBgTextures[i], 
					.(level.bgCropX, level.bgCropY, level.bgCropWidth, level.bgCropHeight),
					.(level.worldX + level.bgPosX, level.worldY + level.bgPosY, level.bgScaleX * level.bgCropWidth, level.bgScaleY * level.bgCropHeight),
					.(level.bgPivotX, level.bgPivotY),
					0.0f,
					.WHITE
				);
			}

			for (let i < ldtkWorld.levels.Length)
			{
				DrawLevel(i, ref ldtkWorld.levels[i], true);
			}
		}

		// Draw tips

		DrawText("Left to previous level", 5, 5, 16, .WHITE);
		DrawText("Right to next level", 5, 25, 16, .WHITE);
	}

	private void DrawLevel(int levelIndex, ref LDtkLevel level, bool useWorldPos = false)
	{
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