namespace BytePath;

abstract class Room
{
	public append Area area = .();

	public virtual void Update(float dt)
	{
		area.Update(dt);
	}

	public virtual void Draw()
	{
		area.Draw();
	}
}