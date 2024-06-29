namespace BytePath;

using System;

static
{
	public static Input gInput;
}

class Program : Raylib.RaylibApp
{
	static void Main()
	{
		scope Program()
			{
				title = "BYTEPATH",
				width = 800,
				height = 600,
			}
			.Run();
	}

	protected override void Init()
	{
		gInput = new Input();

		gInput.Bind("left", .Key(.KEY_LEFT));
		gInput.Bind("left", .Key(.KEY_A));

		gInput.Bind("right", .Key(.KEY_RIGHT));
		gInput.Bind("right", .Key(.KEY_D));

		gInput.Bind("up", .Key(.KEY_UP));
		gInput.Bind("up", .Key(.KEY_W));

		gInput.Bind("down", .Key(.KEY_DOWN));
		gInput.Bind("down", .Key(.KEY_S));

		gInput.Bind(.KEY_GRAVE, new:gInput () => {
			Raylib.TraceLog(.LOG_WARNING, "GC Report will be printed in Beef IDE");
			GC.Report();
		});
	}

	protected override void Close()
	{
		DeleteAndNullify!(gInput);
	}

	protected override void Draw()
	{
		Raylib.ClearBackground(.BLACK);

#if DEBUG
		Raylib.DrawText(scope $"Mouse {gInput.MouseX}, {gInput.MouseY}", 10, 10, 12, .WHITE);
#endif		
	}

	protected override void Update(float dt)
	{
		gInput.Update();

		if (gInput.IsActionPressed("left"))
		{
			Raylib.TraceLog(.LOG_INFO, "Acted left");
		}
	}
}