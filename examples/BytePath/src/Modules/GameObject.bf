namespace BytePath;

using System;
using Raylib;

class GameObject
{
	public append Timer timer = .();

	public using
	public Vector2 			position	= .Zero;
	public float 			scale		= 1.0f;
	public float 			rotation	= 0.0f;

	public virtual void Draw()
	{
	}

	public virtual void Update(float dt)
	{
		timer.Update(dt);
	}
}