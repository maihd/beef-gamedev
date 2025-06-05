namespace BytePath;

static class RoomManager
{
	public static Room currentRoom { get; private set; }

	public static void Init()
	{

	}

	public static void Deinit()
	{
		if (currentRoom != null)
		{
			DeleteAndNullify!(currentRoom);
		}
	}

	public static void Update(float dt)
	{
		if (currentRoom != null)
		{
			currentRoom.Update(dt);
		}
	}

	public static void Draw()
	{
		if (currentRoom != null)
		{
			currentRoom.Draw();
		}
	}

	public static void SetRoom(Room room)
	{
		if (currentRoom != null)
		{
			delete currentRoom;
		}

		currentRoom = room;
	}
}