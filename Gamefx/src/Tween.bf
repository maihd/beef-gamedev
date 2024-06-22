/*
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
*/

using System;
using System.Reflection;

static
{
	public struct Tweener<T, V, TEaseFunc> : this(T target, V startValue, V endValue, float duration, TEaseFunc easeFunc)
		where TEaseFunc : delegate float(float s, float e, float t)
	{
		private function void TweenRoutine(T target, V startValue, V endValue, float time, TEaseFunc easeFunc);

		private bool 	done 		= false;
		private float 	totalTime	= 0.0f;

		public void Update(float dt) mut
		{
			GenTweenRoutine();

			if (done)
			{
				return;
			}

			totalTime += dt;
			totalTime = Math.Min(totalTime, duration);

			routine(target, startValue, endValue, totalTime / duration, easeFunc);

			if (totalTime >= duration)
			{
				done = true;
			}
		}

		[Comptime]
		private static void GenTweenRoutine()
		{
			var typeV = typeof(V);
			if (typeV.IsPointer)
			{
				typeV = typeV.UnderlyingType;
			}
	
			// Generation tween function
			let code = scope String();
			code.Append("readonly TweenRoutine routine = (target, startValue, endValue, time, easeFunc) =>\n");
			code.Append("{\n");
	
			for (let fieldV in typeV.GetFields())
			{
				let fieldName = fieldV.Name;
				code.Append(scope $"	target.{fieldName} = easeFunc(startValue.{fieldName}, endValue.{fieldName}, time);\n");
			}
	
			code.Append("};");
			Compiler.MixinRoot(code);
		}

		[Comptime]
		private static void CheckTypes()
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
	}

#region Utils functions to use as global	

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

	public static Tweener<T, V, TEaseFunc> Tween<T, V, TEaseFunc>(T target, V startValue, V endValue, float duration, TEaseFunc easeFunc, Action onDone = null)
	    where TEaseFunc : delegate float(float s, float e, float t)
	{
		// Generate tween function with comptime features

		// States
		// With syntax like new:SchedulerArena
		return .(target, startValue, endValue, duration, easeFunc);
	}

	public static Tweener<T, V, TEaseFunc> TweenTo<T, V, TEaseFunc>(T target, V endValue, float duration, TEaseFunc easeFunc, Action onDone = null)
	    where TEaseFunc : delegate float(float s, float e, float t)
	{
		GenStartValueDecl<T, V>();
		return .(target, startValue, endValue, duration, easeFunc);
	}

	public static Tweener<T, V, TEaseFunc> TweenBy<T, V, TEaseFunc>(T target, V value, float duration, TEaseFunc easeFunc, Action onDone = null)
	    where TEaseFunc : delegate float(float s, float e, float t)
	{
		GenStartValueDecl<T, V>();
		GenEndValueDecl<T, V>();

		return .(target, startValue, endValue, duration, easeFunc);
	}

#endregion

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

		var tweenerX = TweenTo(entity, (x: 10.0f), 1.0f, => DefEaseFunc);

		tweenerX.Update(1.0f);
		Test.Assert(entity.x == 10.0f);

		var tweenerY = TweenTo(entity, (y: 20.0f), 1.0f, => DefEaseFunc);

		tweenerY.Update(0.5f);
		Test.Assert(entity.y == 10.0f);

		var tweenerPos = TweenTo(&entity.position, Vector2 { x = 0.0f, y = 0.0f }, 1.0f, => DefEaseFunc);

		tweenerPos.Update(0.5f);
		Test.Assert(entity.x == 5.0f && entity.y == 5.0f);

		var tweener = TweenTo(entity, Vector2 { x = 0.0f, y = 0.0f }, 1.0f, => DefEaseFunc);

		tweener.Update(0.5f);
		Test.Assert(entity.x == 2.5f && entity.y == 2.5f);
	}
#endregion
}