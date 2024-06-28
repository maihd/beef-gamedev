/*
Beef GameFX Timer+Tween extensions - v0.1 - https://github.com/maihd/beef-gamedev

REQUIREMENTS

    Beef GameFX Timer >= v0.1
    Beef GameFX Tween >= v1.0

NOTES

    This library use global allocations.

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

[AlwaysInclude]
public extension Timer
{
    [AlwaysInclude]
    public void Tween<T, V, TEaseFunc>(T target, V startValue, V endValue, float duration, TEaseFunc easeFunc, Action onDone = null)
        where TEaseFunc : delegate float(float s, float e, float t)
    {
    	addingRoutines.Add(new TweenerRoutine<T, V, TEaseFunc>(target, startValue, endValue, duration, easeFunc));
    }

    [AlwaysInclude]
    public void TweenTo<T, V, TEaseFunc>(T target, V endValue, float duration, TEaseFunc easeFunc, Action onDone = null)
        where TEaseFunc : delegate float(float s, float e, float t)
    {
    	GenStartValueDecl<T, V>();
    	addingRoutines.Add(new TweenerRoutine<T, V, TEaseFunc>(target, startValue, endValue, duration, easeFunc));
    }

    [AlwaysInclude]
    public void TweenBy<T, V, TEaseFunc>(T target, V value, float duration, TEaseFunc easeFunc, Action onDone = null)
        where TEaseFunc : delegate float(float s, float e, float t)
    {
    	GenStartValueDecl<T, V>();
    	GenEndValueDecl<T, V>();

    	addingRoutines.Add(new TweenerRoutine<T, V, TEaseFunc>(target, startValue, endValue, duration, easeFunc));
    }

    [AlwaysInclude]
    public class TweenerRoutine<T, V, TEaseFunc> : ITimerRoutine
        where TEaseFunc: delegate float(float s, float e, float t)
    {
        public Tweener<T, V, TEaseFunc> tweener;
    
        public bool IsCompleted => tweener.IsCompleted;
    
        public this(T target, V startValue, V endValue, float duration, TEaseFunc easeFunc)
        {
            tweener = .(target, startValue, endValue, duration, easeFunc);
        }
    
        public void Dispose()
        {
        }
    
        public void Update(float dt)
        {
            tweener.Update(dt);
        }
    }
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