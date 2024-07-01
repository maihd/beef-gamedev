namespace Gamefx;

using System;

class TimerTweenTests
{
	[AlwaysInclude]
	static float DefEaseFunc(float s, float e, float t)
	{
		return (s * (1.0f - t)) + (e * t);
	}

    [Test]
    static void TimerTweenTests()
    {
        let timer = scope Timer();

        Entity entity = scope Entity() { x = 0.0f, y = 0.0f };

		timer.TweenTo(entity, (x: 10.0f), 1.0f, new:timer => DefEaseFunc);
        //timer.TweenTo(entity, (x: 10.0f), 1.0f, => DefEaseFunc);
        timer.Update(0.0f);
        timer.Update(1.0f);
        Test.Assert(entity.x == 10.0f);

        /*
        var tweenerY = TweenTo(entity, (y: 20.0f), 1.0f, => DefEaseFunc); 

        tweenerY.Update(0.5f);
        Test.Assert(entity.y == 10.0f);

        var tweenerPos = TweenTo(&entity.position, Vector2 { x = 0.0f, y = 0.0f }, 1.0f, => DefEaseFunc);

        tweenerPos.Update(0.5f);
        Test.Assert(entity.x == 5.0f && entity.y == 5.0f);

        var tweener = TweenTo(entity, Vector2 { x = 0.0f, y = 0.0f }, 1.0f, => DefEaseFunc);

        tweener.Update(0.5f);
        Test.Assert(entity.x == 2.5f && entity.y == 2.5f);
        */
    }
}