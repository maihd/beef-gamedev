using System;
using System.Reflection;

static
{
	[Comptime]
	private static void CheckTypes<T, V>()
	{
		var typeT = typeof(T);
		var typeV = typeof(V);

		let nameT = typeT.GetFullName(..scope String());
		let nameV = typeV.GetFullName(..scope String());

		// Make sure T is reference type
		if (typeT.IsValueType)
		{
			Runtime.FatalError(scope $"{nameT} must be a reference type");
		}

		// Make sure V is value type, or can be causing access violation exception
		// Maybe check if V is ref type, and then allocation memory for startValue. But not recommended.
		if (!typeV.IsValueType)
		{
		    //@note: current version of Beef (nightly) always mark typeV.IsValueType = false
		    //Runtime.FatalError(scope $"{nameV} must be a value type. Otherwise may cause access violation exception. No support for allocation new startValue because of performance issues.");
		}

		// T must has all fields of V
		const let checkFields = true;
		if (checkFields)
		{
			// Currently Beef pointer is void* only
		    if (typeT.IsPointer)
		    {
		        typeT = typeT.UnderlyingType;
		    }

			// Currently Beef pointer is void* only
			if (typeV.IsPointer)
			{
				typeV = typeV.UnderlyingType;
			}

			for (let fieldV in typeV.GetFields())
			{
		        var found = false;

		        for (let fieldT in typeT.GetFields())
		        {
		            if (fieldT.Name == fieldV.Name)
		            {
		                found = true;
		                break;
		            }
		        }

		        if (!found)
		        {
		            var foundGetter = false;
		            var foundSetter = false;

		            let getterName = scope $"get__{fieldV.Name}";
		            let setterName = scope $"set__{fieldV.Name}";

		            const let useGetMethod = true;
		            if (!useGetMethod)
		            {
		                for (let methodT in typeT.GetMethods())
		                {
		                    if (methodT.Name == getterName)
		                    {
		                        foundGetter = true;
		                    }

		                    if (methodT.Name == setterName)
		                    {
		                        foundSetter = true;
		                    }

		                    if (foundGetter && foundSetter)
		                    {
		                        found = true;
		                        break;
		                    }
		                }
		            }
		            else
		            {
		                foundGetter = typeT.GetMethod(getterName) case .Err(.NoResults);
		                foundSetter = typeT.GetMethod(setterName) case .Err(.NoResults);
		                found = foundGetter && foundSetter;
		            }
		        }

				if (!found)
				{
					Runtime.FatalError(scope $"{nameT} does not contains all fields/properties of {nameV}. Requiring \"{fieldV.Name}\".");
				}
			}
		}
	}

	[Comptime]
	private static void GenStartValueDecl<T, V>()
	{
		var typeV = typeof(V);
		if (typeV.IsPointer)
		{
			typeV = typeV.UnderlyingType;
		}

		// Generation tween function
		let code = scope String();
		code.Append("#unwarn\n");
		code.Append("V startValue = ?;\n");
		for (let fieldV in typeV.GetFields())
		{
			let fieldName = fieldV.Name;
			code.Append(scope $"startValue.{fieldName} = target.{fieldName};\n");
		}
		code.Append("\n");
		Compiler.MixinRoot(code);
	}

	[Comptime]
	private static void GenEndValueDecl<T, V>()
	{
		var typeV = typeof(V);
		if (typeV.IsPointer)
		{
			typeV = typeV.UnderlyingType;
		}

		// Generation tween function
		let code = scope String();
		code.Append("#unwarn\n");
		code.Append("V endValue = ?;\n");
		for (let fieldV in typeV.GetFields())
		{
			let fieldName = fieldV.Name;
			code.Append(scope $"envValue.{fieldName} = target.{fieldName} + value.{fieldName};\n");
		}
		code.Append("\n");
		Compiler.MixinRoot(code);
	}

	[Comptime]
	private static void GenTweenRoutine<T, V>()
	{
		var typeV = typeof(V);
		if (typeV.IsPointer)
		{
			typeV = typeV.UnderlyingType;
		}

		// Generation tween function
		let code = scope String();
		code.Append("readonly TweenRoutine<T, V, TEaseFunc> routine = (target, startValue, endValue, time, easeFunc) =>\n");
		code.Append("{\n");

		for (let fieldV in typeV.GetFields())
		{
			let fieldName = fieldV.Name;
			code.Append(scope $"	target.{fieldName} = easeFunc(startValue.{fieldName}, endValue.{fieldName}, time);\n");
		}

		code.Append("};");
		Compiler.MixinRoot(code);
	}

	struct TweenState
	{
		public bool 	done 		= false;
		public float 	totalTime	= 0.0f;
	}

	public function void TweenRoutine<T, V, TEaseFunc>(T target, V startValue, V endValue, float time, TEaseFunc easeFunc) where TEaseFunc : delegate float(float s, float e, float t);
	public delegate void TweenRunner(float dt);

	public static TweenRunner Tween<T, V, TEaseFunc>(T target, V startValue, V endValue, float duration, TEaseFunc easeFunc, Action onDone = null)
	    where TEaseFunc : delegate float(float s, float e, float t)
	{
		// Generate tween function with comptime features
		CheckTypes<T, V>();
		GenTweenRoutine<T, V>();

		// States
		// With syntax like new:SchedulerArena
		let state = new TweenState();

		// Runner, can add schedule allocator
		// With syntax like new:SchedulerArena
		TweenRunner runner = new [=](dt) => {
			if (state.done)
			{
				return;
			}

			state.totalTime += dt;
			state.totalTime = Math.Min(state.totalTime, duration);

			routine(target, startValue, endValue, state.totalTime / duration, easeFunc);

			if (state.totalTime >= duration)
			{
				state.done = true;
				onDone?.Invoke();

				// Unschedule
			}
		} ~ {
			// Should use better dellocations
			delete state;
		};

		// Add runner to timer/scheduler
		return runner;
	}

	public static TweenRunner TweenTo<T, V, TEaseFunc>(T target, V endValue, float duration, TEaseFunc easeFunc, Action onDone = null)
	    where TEaseFunc : delegate float(float s, float e, float t)
	{
		GenStartValueDecl<T, V>();
		return Tween(target, startValue, endValue, duration, easeFunc, onDone);
	}

	public static TweenRunner TweenBy<T, V, TEaseFunc>(T target, V value, float duration, TEaseFunc easeFunc, Action onDone = null)
	    where TEaseFunc : delegate float(float s, float e, float t)
	{
		GenStartValueDecl<T, V>();
		GenEndValueDecl<T, V>();

		return Tween(target, startValue, endValue, duration, easeFunc, onDone);
	}

#region Unit tests
	struct Vector2
	{
	    public float x;
	    public float y;
	}

	class Entity
	{
	    using public Vector2 position;
	}

	private static float DefEaseFunc(float s, float e, float t)
	{
		return (s * (1.0f - t)) + (e * t);
	}

	[Test]
	private static void TestTween()
	{
		Entity entity = new Entity() { x = 0.0f, y = 0.0f };
		defer delete entity;

		let tweenerX = TweenTo(entity, (x: 10.0f), 1.0f, => DefEaseFunc);
		defer delete tweenerX;

		tweenerX(1.0f);
		Test.Assert(entity.x == 10.0f);

		let tweenerY = TweenTo(entity, (y: 20.0f), 1.0f, => DefEaseFunc);
		defer delete tweenerY;

		tweenerY(0.5f);
		Test.Assert(entity.y == 10.0f);

		let tweenerPos = TweenTo(&entity.position, Vector2 { x = 0.0f, y = 0.0f }, 1.0f, => DefEaseFunc);
		defer delete tweenerPos;

		tweenerPos(0.5f);
		Test.Assert(entity.x == 5.0f && entity.y == 5.0f);

		let tweener = TweenTo(entity, Vector2 { x = 0.0f, y = 0.0f }, 1.0f, => DefEaseFunc);
		defer delete tweener;

		tweener(0.5f);
		Test.Assert(entity.x == 2.5f && entity.y == 2.5f);
	}
#endregion
}