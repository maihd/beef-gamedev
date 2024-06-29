namespace BytePath.GameObjects;

public class Player : GameObject
{
	public override void Draw()
	{
		Raylib.DrawCircleV(position, 10.0f, .WHITE);	
	}
}