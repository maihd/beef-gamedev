/*
Beef GameFX Timer - v0.1 - https://github.com/maihd/beef-gamedev

NOTES

    This library use global allocations.

LICENSE

    See end of file for license information.

RECENT REVISION HISTORY:

    0.2 (2024-06-28) make sure memory lifecycle is right
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
    public void Update(float dt) mut;
}

public enum TimerFlags : uint32
{
    None      = 0,
    OwnMemory = 1,
}

[AlwaysInclude]
public class Timer
{
    private TimerFlags flags = .None;

    private append List<ITimerRoutine> routines = .();
    private append List<ITimerRoutine> addingRoutines = .();
    private append List<ITimerRoutine> removingRoutines = .();

    public this(TimerFlags flags = .None)
    {
        this.flags = flags;
    }

    public ~this()
    {
        Clear();
    }

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

        if (flags.HasFlag(.OwnMemory))
        {
            ClearAndDeleteItems!(removingRoutines);
        }
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
        addingRoutines.Add(new:this RoutineAfter<TAction>(this, delay, action));
    }
    
    [Inline]
    public void Every<TActionFn, TAfterFn>(float delay, TActionFn action, int count, TAfterFn after = null)
		where TActionFn : Action
		where TAfterFn : Action
    {
        Debug.Assert(action != null);
        addingRoutines.Add(new:this RoutineEvery<TActionFn, TAfterFn>(this, delay, action, count, after));
    }

    [Inline]
    public void During<TActionFn, TAfterFn>(float delay, TActionFn action, TAfterFn after = null)
		where TActionFn : Action
		where TAfterFn : Action
    {
        Debug.Assert(action != null);
        addingRoutines.Add(new:this RoutineDuring<TActionFn, TAfterFn>(this, delay, action, after));
    }

    // @todo(maihd): Add remove by tag
    public void Cancel()
    {

    }

    public void Clear()
    {
        ClearAndDeleteItems!(routines);
        ClearAndDeleteItems!(addingRoutines);
        ClearAndDeleteItems!(removingRoutines);
    }

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

#region Routines
    [Comptime]
    private static void ComptimeFuncDelete(Type type, StringView name)
    {
        /*This code will crash the IDE or compiler when build
        Runtime.FatalError(scope $"type full name: {typeof(T).GetFullName(..scope .())}");
        const let isDelegate = typeof(T).[Friend]mTypeFlags.HasFlag(.Delegate);
        if (isDelegate)
        {
            Compiler.MixinRoot(scope $"delete:timer {name};");
        }
        */

        if (type.[Friend]mTypeFlags.HasFlag(.Delegate))
        {
            Compiler.MixinRoot(scope $"delete:timer {name};");
        }
    }

    [AlwaysInclude]
    public class RoutineAfter<TAction> : ITimerRoutine, this(Timer timer, float delay, TAction action)
        where TAction : Action
    {
        private float time = 0.0f;

        ~this()
        {
            if (timer.flags.HasFlag(.OwnMemory))
            {
                ComptimeFuncDelete(typeof(TAction), nameof(action));
            }
        }

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
    public class RoutineEvery<TActionFn, TAfterFn> : ITimerRoutine, this(Timer timer, float delay, TActionFn action, int count, TAfterFn after)
        where TActionFn : Action
        where TAfterFn : Action
    {
        private float time = 0.0f;
        private int counter = 0;

        public ~this()
        {
            if (timer.flags.HasFlag(.OwnMemory))
            {
                ComptimeFuncDelete(typeof(TActionFn), nameof(action));
                ComptimeFuncDelete(typeof(TAfterFn), nameof(after));
            }
        }

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
    public class RoutineDuring<TActionFn, TAfterFn> : ITimerRoutine, this(Timer timer, float delay, TActionFn action, TAfterFn after)
        where TActionFn : Action
        where TAfterFn : Action
    {
        private float time = 0.0f;

        public ~this()
        {
            if (timer.flags.HasFlag(.OwnMemory))
            {
                ComptimeFuncDelete(typeof(TActionFn), nameof(action));
                ComptimeFuncDelete(typeof(TAfterFn), nameof(after));
            }
        }

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