/*
Beef GameFX Aren - v0.1 - https://github.com/maihd/beef-gamedev

NOTES

    This library use OS virtual page allocations.

LICENSE

    See end of file for license information.

RECENT REVISION HISTORY:

    0.1 (2024-07-20) designing the API

============================    Contributors    =========================
Basic functional
    MaiHD

============================    Acknowledges    =========================
Ryan Fleury for ideas of simple arena allocations without vtable or generics
-- Contributing are welcome --
*/

using System;

public class Arena
{
	public void* Alloc(int size, int align)
	{
		return null;
	}

	public void Free(void* ptr)
	{

	}

#region OS API
	[Inline]
	public static void* VirtualAlloc(void* page, int size)
	{
		return null;
	}

	[Inline]
	public static void VirtualFree(void* ptr)
	{

	}

	[Inline]
	public static void* VirtualCommit(void* page, int size)
	{
		return null;
	}

	[Inline]
	public static void VirtualDecommit(void* page, int size)
	{
	}

#if BF_PLATFORM_WINDOWS
	enum AllocationType : uint32
	{
		Commit	= 0x00001000,
		Reserve	= 0x00002000,
	}

	enum ProctectFlags : uint32
	{
		PAGE_READWRITE = 0x04
	}

	enum FreeType : uint32
	{
		Decommit 				= 0x00004000,
		Release  			 	= 0x00008000,
		CoalescePlaceholders 	= 0x00000001,
		PreservePlaceholder		= 0x00000002,
	}

	[CLink, LinkName("VirtualAlloc")]
	private extern static void* Win_VirtualAlloc(void* page, uint size, AllocationType allocationType, ProctectFlags protectFlags);

	[CLink, LinkName("VirtualFree")]
	private extern static void Win_VirtualFree(void* page, uint size, FreeType freeType);
#else
	[CLink, LinkName("mmap")]
	private extern static void* Unix_VirtualAlloc(void* page, uint length, int32 prot, int32 flags, int32 fd, int64 offset);

	[CLink, LinkName("munmap")]
	private extern static void Uni_VirtualFree(void* page, uint length);
#endif
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