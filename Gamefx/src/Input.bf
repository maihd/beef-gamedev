/*
Beef GameFX Input - v0.1 - https://github.com/maihd/beef-gamedev

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

class Input
{
#if RAYLIB	

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