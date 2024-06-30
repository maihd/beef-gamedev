namespace LDtkRaylibDemo;

class Program : Raylib.RaylibApp
{
	static void Main()
	{
		var program = scope Program()
			{
				title = "title",
				width = 800,
				height = 600
			};

		program.Run();
	}

	protected override void Init()
	{
		let bufferSize = 10 * 1024 * 1024;
		let buffer = System.Internal.Malloc(bufferSize);
		defer System.Internal.Free(buffer);

		let ldtkContext = LDtkContext.UseWindows(buffer, bufferSize);
		let ldtkWorld = LDtk.Parse("assets/sample.ldtk", ldtkContext, .None).GetValueOrDefault();
	}
}