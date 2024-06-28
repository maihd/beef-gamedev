namespace Gamefx;

using System;
using System.IO;
using System.Diagnostics;

static
{
    [Test]
    static void TimerTests()
    {
        let stream = scope Test.TestStream();
        stream.Write("Testing Timer...\n");

        Timer timer = new .(.OwnMemory);
        defer delete timer;

        int count = 0;

        timer.After(1.0f, new:timer [&count, =]() => {
            stream.Write("Timer.After done!\n");
            count++;
		});

        timer.Every(1.0f, new:timer [&count, =]() => {
            stream.Write("Timer.Every ticking...\n");
            count++;
		}, 5, new:timer [&count, =]() => {
            stream.Write("Timer.Every done!\n");
            count++;
		});

        timer.During(1.0f, new:timer [&count, =]() => {
            stream.Write("Timer.During ticking...\n");
            count++;
		}, new:timer () => {
            stream.Write("Timer.During done!\n");
		});

        // First time, just let the routine starting
        timer.Update(0.0f);

        for (int i < 6)
        {
            timer.Update(1.0f);
        }

        // Test clear
        timer.After(1.0f, new:timer () => {});
        timer.Clear();

        // Test destructor
        timer.After(1.0f, new:timer () => {});

        // Check final result
        Test.Assert(count == 8);
    }
}