namespace BytePath;

using System;
using System.Collections;

class Area
{
	public append List<GameObject> gameObjects = .() ~ ClearAndDeleteItems!(_);

	public virtual void Update(float dt)
	{
		for (let gameObject in gameObjects)
		{
			gameObject.Update(dt);
		}
	}

	public virtual void Draw()
	{
		for (let gameObject in gameObjects)
		{
			gameObject.Draw();
		}
	}
}