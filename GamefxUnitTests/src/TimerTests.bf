using System;
using System.IO;
using System.Diagnostics;

static
{
    [Test, AlwaysInclude]
    static void TimerTests()
    {
        let stream = scope Test.TestStream();
        stream.Write("Testing Timer...\n");

        Timer timer = scope .();

        int count = 0;

        timer.After(1.0f, scope [&count, =]() => {
            stream.Write("Timer.After done!\n");
            count++;
		});

        timer.Every(1.0f, scope [&count, =]() => {
            stream.Write("Timer.Every ticking...\n");
            count++;
		}, 5, scope [&count, =]() => {
            stream.Write("Timer.Every done!\n");
            count++;
		});

        timer.During(1.0f, scope [&count, =]() => {
            stream.Write("Timer.During ticking...\n");
            count++;
		}, scope [&count, =]() => {
            stream.Write("Timer.During done!\n");
            count++;
		});

        // First time, just let the routine starting
        timer.Update(0.0f);

        for (int i < 6)
        {
            timer.Update(1.0f);
        }

        // Test clear
        timer.After(1.0f, () => {});
        timer.Clear();

        // Test destructor
        timer.After(1.0f, () => {});

        // Check final result
        Test.Assert(count == 9);
    }
}