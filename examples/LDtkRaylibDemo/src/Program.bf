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

	LDtkWorld ldtkWorld;
	LDtkRenderer ldtkRenderer;

	Texture	worldBgTexture;

	int currentLevelIndex = 0;
	LDtkLevel currentLevel;

	protected override void Init()
	{
		let bufferSize = 10 * 1024 * 1024;
		ldtkRenderer = new LDtkRenderer(bufferSize);

		ldtkRenderer.Load("assets/sample.ldtk").IgnoreError();
		ldtkWorld = ldtkRenderer.world;

		worldBgTexture = LoadTexture("assets/N2D - SpaceWallpaper1280x448.png");
		SetWindowSize(worldBgTexture.width, worldBgTexture.height);

		currentLevelIndex = 0;
		currentLevel = ldtkWorld.levels[currentLevelIndex];
		SetWindowSize(currentLevel.width, currentLevel.height);
	}

	protected override void Close()
	{
		DeleteAndNullify!(ldtkRenderer);
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
		ClearBackground(ldtkWorld.backgroundColor);

		if (currentLevelIndex > -1 && currentLevelIndex < ldtkWorld.levels.Length)
		{
			// Draw one level
			ldtkRenderer.DrawLevel(currentLevelIndex);
		}
		else
		{
			ldtkRenderer.DrawWorld(true);
		}

		// Draw tips

		DrawText("Left to previous level", 5, 5, 16, .WHITE);
		DrawText("Right to next level", 5, 25, 16, .WHITE);
	}
}