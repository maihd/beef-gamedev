namespace BytePath;

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
	}

	protected override void Close()
	{
	}

	protected override void Draw()
	{
		Raylib.ClearBackground(.BLACK);
	}

	protected override void Update(float dt)
	{
	}
}