/*
Beef GameFX Input - v1.0 - https://github.com/maihd/beef-gamedev

NOTES

    This library use global allocations.

LICENSE

    See end of file for license information.

RECENT REVISION HISTORY:
	1.0 (2024-06-29) first usable version
    0.1 (2024-06-28) designing the API

============================    Contributors    =========================
Basic functional
    MaiHD

============================    Acknowledges    =========================
SSYGEN for his Love2D Input.lua
-- Contributing are welcome --
*/

using System;
using System.Collections;

class Input
{
	public enum InputButtonKind
	{
		case Key(KeyCode);
		case Mouse(MouseButton);
		case Gamepad(GamepadButton);
	};

	public append Dictionary<KeyCode, Event<Action>> keyBindings = .();
	public append Dictionary<MouseButton, Event<Action>> mouseBindings = .();
	public append Dictionary<GamepadButton, Event<Action>> gamepadBindings = .();
	
	public append Dictionary<StringView, bool> actionStates = .();
	public append Dictionary<StringView, Event<Action>> actionBindings = .();
	public append Dictionary<StringView, List<InputButtonKind>> actionButtonBindings = .();

	public ~this()
	{
		Clear();
	}

	public void Update()
	{
		for (let (key, action) in ref keyBindings)
		{
			if (IsKeyPressed(key))
			{
				action.Invoke();
			}
		}

		for (let (button, action) in ref mouseBindings)
		{
			if (IsMousePressed(button))
			{
				action.Invoke();
			}
		}	

		for (let (button, action) in ref gamepadBindings)
		{
			if (IsGamepadButtonDown(button))
			{
				action.Invoke();
			}
		}

		// Handle actions

		for (let (action, buttons) in actionButtonBindings)
		{
			var pressed = false;
			for (let button in buttons)
			{
				switch (button)
				{
				case .Key(let key): 				pressed = IsKeyPressed(key);
				case .Mouse(let mouseButton): 		pressed = IsMousePressed(mouseButton);
				case .Gamepad(let gamepadButton): 	pressed = IsGamepadButtonPressed(gamepadButton);
				}

				if (pressed)
				{
					break;
				}
			}

			actionStates[action] = pressed;
		}

		for (let (action, pressed) in actionStates)
		{
			if (pressed)
			{
				actionBindings[action].Invoke();
			}
		}
	}

	public void Clear()
	{
		for (let (_, action) in ref keyBindings)
		{
			action.Dispose();
		}

		for (let (_, action) in ref mouseBindings)
		{
			action.Dispose();
		}

		for (let (_, action) in ref gamepadBindings)
		{
			action.Dispose();
		}

		keyBindings.Clear();
		mouseBindings.Clear();
		gamepadBindings.Clear();

		// Clear actions

		for (let (_, action) in ref actionBindings)
		{
			action.Dispose();
		}

		for (let (_, buttons) in actionButtonBindings)
		{
			delete buttons;
		}

		actionStates.Clear();
		actionBindings.Clear();
		actionButtonBindings.Clear();
	}

	public void Bind(KeyCode key, Action action)
	{
		if (!keyBindings.ContainsKey(key))
		{
			keyBindings.Add(key, .());
		}
		
		var listeners = ref keyBindings[key];
		listeners.Add(action);
	}

	public void Bind(MouseButton button, Action action)
	{
		if (!mouseBindings.ContainsKey(button))
		{
			mouseBindings.Add(button, .());
		}

		var listeners = ref mouseBindings[button];
		listeners.Add(action);
	}	

	public void Bind(GamepadButton button, Action action)
	{
		if (!gamepadBindings.ContainsKey(button))
		{
			gamepadBindings.Add(button, .());
		}
		
		var listeners = ref gamepadBindings[button];
		listeners.Add(action);
	}

	public void Unbind(KeyCode key, Action action)
	{
		if (keyBindings.ContainsKey(key))
		{
			var listeners = ref keyBindings[key];
			listeners.Remove(action);
		}
	}

	public void Unbind(MouseButton button, Action action)
	{
		if (mouseBindings.ContainsKey(button))
		{
			var listeners = ref mouseBindings[button];
			listeners.Remove(action);
		}
	}

	public void Unbind(GamepadButton button, Action action)
	{
		if (gamepadBindings.ContainsKey(button))
		{
			var listeners = ref gamepadBindings[button];
			listeners.Remove(action);
		}
	}

	public void UnbindAll(KeyCode key)
	{
		if (keyBindings.ContainsKey(key))
		{
			var listeners = ref keyBindings[key];
			listeners.Dispose();
		}
	}

	public void UnbindAll(MouseButton button)
	{
		if (mouseBindings.ContainsKey(button))
		{
			var listeners = ref mouseBindings[button];
			listeners.Dispose();
		}
	}

	public void UnbindAll(GamepadButton button)
	{
		if (gamepadBindings.ContainsKey(button))
		{
			var listeners = ref gamepadBindings[button];
			listeners.Dispose();
		}
	}

#region Actions
	public bool HasAction(StringView actionName)
	{
		return actionBindings.ContainsKey(actionName);
	}

	public bool IsActionPressed(StringView actionName)
	{
		return HasAction(actionName) && actionStates[actionName];
	}

	private void CheckAndCreateAction(StringView actionName)
	{
		if (!HasAction(actionName))
		{
			// @note(maihd): we donot care memory allocations here, because in common case, because we dont have many much action names
			String savedActionName = actionName.Intern();

			actionStates.Add(savedActionName, false);
			actionBindings.Add(savedActionName, .());
			actionButtonBindings.Add(savedActionName, new .()); // @todo(maihd): support new:this
		}
	}

	public void Bind(StringView actionName, InputButtonKind button)
	{
		CheckAndCreateAction(actionName);

		var buttons = actionButtonBindings[actionName];
		buttons.Add(button);
	}

	public void Bind(StringView actionName, Action action)
	{
		CheckAndCreateAction(actionName);

		var listeners = ref actionBindings[actionName];
		listeners.Add(action);
	}

	public void UnbindButton(StringView actionName, InputButtonKind button)
	{
		if (HasAction(actionName))
		{
			var buttons = actionButtonBindings[actionName];
			buttons.Remove(button);
		}
	}

	public void UnbindListener(StringView actionName, Action action)
	{
		if (HasAction(actionName))
		{
			var listeners = actionBindings[actionName];
			listeners.Remove(action);
		}
	}

	public void UnbindAllButtons(StringView actionName)
	{
		if (HasAction(actionName))
		{
			var buttons = actionButtonBindings[actionName];
			buttons.Clear();
		}
	}

	public void UnbindAllListeners(StringView actionName)
	{
		if (HasAction(actionName))
		{
			var listeners = actionBindings[actionName];
			listeners.Dispose();
		}
	}

	public void UnbindAll(StringView actionName)
	{
		if (HasAction(actionName))
		{
			var buttons = actionButtonBindings[actionName];
			delete buttons;

			var listeners = actionBindings[actionName];
			listeners.Dispose();

			actionStates.Remove(actionName);
			actionBindings.Remove(actionName);
			actionButtonBindings.Remove(actionName);
		}
	}
#endregion

/* UNUSED
	[Inline]
	public bool IsUp(KeyCode key)
	{
		return IsKeyUp(key);
	}

	[Inline]
	public bool IsDown(KeyCode key)
	{
		return IsKeyDown(key);
	}

	[Inline]
	public bool IsPressed(KeyCode key)
	{
		return IsKeyPressed(key);
	}

	[Inline]
	public bool IsReleased(KeyCode key)
	{
		return IsKeyReleased(key);
	}

	[Inline]
	public bool IsUp(MouseButton button)
	{
		return IsMouseUp(button);
	}

	[Inline]
	public bool IsDown(MouseButton button)
	{
		return IsMouseDown(button);
	}

	[Inline]
	public bool IsPressed(MouseButton button)
	{
		return IsMousePressed(button);
	}

	[Inline]
	public bool IsReleased(MouseButton button)
	{
		return IsMouseReleased(button);
	}

	[Inline]
	public bool IsUp(GamepadButton button)
	{
		return IsGamepadButtonUp(button);
	}

	[Inline]
	public bool IsDown(GamepadButton button)
	{
		return IsGamepadButtonDown(button);
	}

	[Inline]
	public bool IsPressed(GamepadButton button)
	{
		return IsGamepadButtonPressed(button);
	}

	[Inline]
	public bool IsReleased(GamepadButton button)
	{
		return IsGamepadButtonReleased(button);
	}
*/

#if RAYLIB
	public typealias KeyCode = Raylib.KeyboardKey;
	public typealias MouseButton = Raylib.MouseButton;
	public typealias GamepadButton = Raylib.GamepadButton;

	[Inline]
	public float MouseX => Raylib.GetMouseX();

	[Inline]
	public float MouseY => Raylib.GetMouseY();

	[Inline]
	public float MouseWheel => Raylib.GetMouseWheelMove();

	[Inline]
	public Raylib.Vector2 MousePosition => Raylib.GetMousePosition();

	[Inline]
	public bool IsKeyUp(KeyCode key)
	{
		return Raylib.IsKeyUp(key);
	}

	[Inline]
	public bool IsKeyDown(KeyCode key)
	{
		return Raylib.IsKeyDown(key);
	}

	[Inline]
	public bool IsKeyPressed(KeyCode key)
	{
		return Raylib.IsKeyReleased(key);
	}

	[Inline]
	public bool IsKeyReleased(KeyCode key)
	{
		return Raylib.IsKeyReleased(key);
	}

	[Inline]
	public bool IsMouseUp(MouseButton button)
	{
		return Raylib.IsMouseButtonUp(button);
	}

	[Inline]
	public bool IsMouseDown(MouseButton button)
	{
		return Raylib.IsMouseButtonDown(button);
	}

	[Inline]
	public bool IsMousePressed(MouseButton button)
	{
		return Raylib.IsMouseButtonPressed(button);
	}

	[Inline]
	public bool IsMouseReleased(MouseButton button)
	{
		return Raylib.IsMouseButtonReleased(button);
	}

	[Inline]
	public bool IsGamepadButtonUp(GamepadButton button)
	{
		return Raylib.IsGamepadButtonUp(0, button);
	}

	[Inline]
	public bool IsGamepadButtonDown(GamepadButton button)
	{
		return Raylib.IsGamepadButtonDown(0, button);
	}

	[Inline]
	public bool IsGamepadButtonPressed(GamepadButton button)
	{
		return Raylib.IsGamepadButtonPressed(0, button);
	}

	[Inline]
	public bool IsGamepadButtonReleased(GamepadButton button)
	{
		return Raylib.IsGamepadButtonReleased(0, button);
	}
#endif

#region memory allocations
	public void* Alloc(int size, int align)
	{
	    return Internal.StdMalloc(size);
	}

	public void* AllocTyped(Type type, int size, int align)
	{
	    void* data = Alloc(size, align);
	    if (type.HasDestructor)
	        MarkRequiresDeletion(data);
	    return data;
	}

	public void Free(void* ptr)
	{
	    Internal.StdFree(ptr);
	}

	public void MarkRequiresDeletion(void* obj)
	{
	    /* TODO: call this object's destructor when the allocator is disposed */
	}
#endregion
}

/*
------------------------------------------------------------------------------
MIT License

Copyright (c) 2024 MaiHD

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
------------------------------------------------------------------------------
*/