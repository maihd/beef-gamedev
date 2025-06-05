namespace BytePath;

using System;
using BytePath.GameObjects;

static
{
	public static Input gInput;
	public static Timer gTimer;
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

	Player tmpPlayer;

	protected override void Init()
	{
		gInput = new Input();
		gTimer = new Timer();

		gInput.Bind("left", .Key(.KEY_LEFT));
		gInput.Bind("left", .Key(.KEY_A));

		gInput.Bind("right", .Key(.KEY_RIGHT));
		gInput.Bind("right", .Key(.KEY_D));

		gInput.Bind("up", .Key(.KEY_UP));
		gInput.Bind("up", .Key(.KEY_W));

		gInput.Bind("down", .Key(.KEY_DOWN));
		gInput.Bind("down", .Key(.KEY_S));

		gInput.Bind(.KEY_GRAVE, new () => {
			Raylib.TraceLog(.LOG_WARNING, "GC Report will be printed in Beef IDE");
			GC.Report();
		});
		

		tmpPlayer = new Player();
		tmpPlayer.y = Raylib.GetScreenHeight() * 0.5f;
		gInput.Bind(.KEY_SPACE, new () => {
			gTimer.TweenTo(tmpPlayer, (x: Raylib.GetScreenWidth() * 0.5f), 2.0f, new:gTimer (s, e, t) => Raylib.Easings.EaseBackInOut(t, s, e, 1.0f));
		});

		RoomManager.Init();
		RoomManager.SetRoom(new BytePath.Rooms.Stage());
	}

	protected override void Close()
	{
		RoomManager.Deinit();

		DeleteAndNullify!(tmpPlayer);

		DeleteAndNullify!(gInput);
		DeleteAndNullify!(gTimer);
	}

	protected override void Draw()
	{
		Raylib.ClearBackground(.BLACK);

		tmpPlayer.Draw();
		RoomManager.Draw();

#if DEBUG
		Raylib.DrawText(scope $"Mouse {gInput.MouseX}, {gInput.MouseY}", 10, 10, 12, .WHITE);
#endif
	}

	protected override void Update(float dt)
	{
		gInput.Update();
		gTimer.Update(dt);

		if (gInput.IsActionPressed("left"))
		{
			Raylib.TraceLog(.LOG_INFO, "Acted left");
		}

		RoomManager.Update(dt);
	}
}