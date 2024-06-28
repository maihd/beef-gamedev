/*
Beef GameFX Timer - v0.1 - https://github.com/maihd/beef-gamedev

LICENSE

    See end of file for license information.

RECENT REVISION HISTORY:

    0.1 (2024-06-28) designing the API

============================    Contributors    =========================
Basic tweening functional
    MaiHD

-- Contributing are welcome --
*/

using System;
using System.Collections;
using System.Diagnostics;

public interface ITimerRoutine
{
    public bool IsCompleted { get; }
    public void Dispose();
    public void Update(float dt);
}

[AlwaysInclude]
public class Timer
{
    private append List<ITimerRoutine> routines = .() ~ ClearAndDeleteItems!(_);
    private append List<ITimerRoutine> addingRoutines = .() ~ ClearAndDeleteItems!(_);
    private append List<ITimerRoutine> removingRoutines = .() ~ ClearAndDeleteItems!(_);

    public void Update(float dt)
    {
        for (let routine in routines)
        {
            routine.Update(dt);

            if (routine.IsCompleted)
            {
                routine.Dispose();
                removingRoutines.Add(routine);
            }
        }

        for (let routine in removingRoutines)
        {
            routines.Remove(routine);
        }

        for (let routine in addingRoutines)
        {
            routines.Add(routine);
        }

        addingRoutines.Clear();
        ClearAndDeleteItems!(removingRoutines);
    }

    public void AddRoutine(ITimerRoutine routine)
    {
        if (addingRoutines.IndexOf(routine) < 0)
        {
            addingRoutines.Add(routine);
        }
    }

    public void RemoveRoutine(ITimerRoutine routine)
    {
        if (removingRoutines.IndexOf(routine) < 0)
        {
            removingRoutines.Add(routine);
        }
    }
    
    [Inline]
    public void After<TAction>(float delay, TAction action) where TAction : Action
    {
        Debug.Assert(action != null);
        addingRoutines.Add(new RoutineAfter<TAction>(delay, action));
    }
    
    [Inline]
    public void Every<TAction>(float delay, TAction action, int count = 0, TAction after = null) where TAction : Action
    {
        Debug.Assert(action != null);
        addingRoutines.Add(new RoutineEvery<TAction>(delay, action, count, after));
    }

    [Inline]
    public void During<TAction>(float delay, TAction action, TAction after = null) where TAction : Action
    {
        Debug.Assert(action != null);
        addingRoutines.Add(new RoutineDuring<TAction>(delay, action, after));
    }

    // @todo(maihd): Add remove by tag
    public void Cancel()
    {

    }

    public void Clear()
    {
        for (let routine in routines)
        {
            routine.Dispose();
        }

        for (let routine in addingRoutines)
        {
            routine.Dispose();
        }

        for (let routine in removingRoutines)
        {
            routine.Dispose();
        }

        ClearAndDeleteItems!(routines);
        ClearAndDeleteItems!(addingRoutines);
        ClearAndDeleteItems!(removingRoutines);
    }

#region Routines
    [AlwaysInclude]
    public class RoutineAfter<TAction> : ITimerRoutine, this(float delay, TAction action)
        where TAction : Action
    {
        private float time = 0.0f;

        public bool IsCompleted
        {
            get
            {
                return time >= delay;
            }
        }

        public void Dispose()
        {
            action();
        }

        public void Update(float dt)
        {
            time += dt;
        }
    }

    [AlwaysInclude]
    public class RoutineEvery<TAction> : ITimerRoutine, this(float delay, TAction action, int count, TAction after)
        where TAction : Action
    {
        private float time = 0.0f;
        private int counter = 0;

        public bool IsCompleted
        {
            get
            {
                return count > 0 && counter >= count;
            }
        }

        public void Dispose()
        {
            if (after != null)
            {
                after();
            }
        }

        public void Update(float dt)
        {
            time += dt;
            if (time >= delay)
            {
                time -= delay;

                action();
                counter++;
            }
        }
    }

    [AlwaysInclude]
    public class RoutineDuring<TAction> : ITimerRoutine, this(float delay, TAction action, TAction after)
        where TAction : Action
    {
        private float time = 0.0f;

        public bool IsCompleted
        {
            get
            {
                return time >= delay;
            }
        }

        public void Dispose()
        {
            if (after != null)
            {
                after();
            }
        }

        public void Update(float dt)
        {
            action();
            time += dt;
        }
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