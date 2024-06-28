/*
Beef GameFX Input - v1.1 - https://github.com/EinScott/json

NOTES

    This library use global allocations.

LICENSE

    See end of file for license information.

RECENT REVISION HISTORY:

    1.1 (2024-04-06) fix for strings with invalid codepoints
	1.0 (2022-09-22) initial commit

============================    Contributors    =========================
Basic functional
    EinScott

-- Contributing are welcome --
*/

using System;
using System.Text;
using System.Collections;
using System.Diagnostics;

namespace Json;

using internal Json;

typealias JsonResult = Result<void, JsonError>;
typealias JsonObjectData = Dictionary<StringView, JsonElement>;
typealias JsonArrayData = List<JsonElement>;

struct JsonError
{
	public int line, column;
	public JsonErrorType error;

	public override void ToString(String strBuffer)
	{
		strBuffer.Append("Error '");
		error.ToString(strBuffer);
		strBuffer.Append("' at Ln ");
		line.ToString(strBuffer);
		strBuffer.Append(" Col ");
		column.ToString(strBuffer);
	}
}

enum JsonErrorType
{
	Syntax_ExpectedValue,
	Syntax_InvalidValue,
	Syntax_UnterminatedString,
	Syntax_ControlCharInString,
	Synatx_ExpectedEnd,
	Syntax_InvalidEscapeSequence,
	Syntax_UnterminatedObject,
	Syntax_ExpectedKey,
	Syntax_ExpectedColon,
	Syntax_UnterminatedArray,
	Syntax_InvalidNumber,
	Constraint_DuplicateObjectKey,
	Constraint_DepthTooGreat,
	Lib_TreeRootWasAlreadyUsed
}

enum JsonElement
{
	case Null;
	case Object(JsonObjectData object);
	case Array(JsonArrayData array);
	case String(StringView string);
	case Number(double number);
	case Bool(bool boolean);

	public bool AsBool()
	{
		if (this case .Bool(let boolean))
			return boolean;
		Runtime.FatalError();
	}

	public double AsNumber()
	{
		if (this case .Number(let number))
			return number;
		Runtime.FatalError();
	}

	public StringView AsString()
	{
		if (this case .String(let string))
			return string;
		Runtime.FatalError();
	}

	public JsonArrayData AsArray()
	{
		if (this case .Array(let array))
			return array;
		Runtime.FatalError();
	}

	public JsonObjectData AsObject()
	{
		if (this case .Object(let object))
			return object;
		Runtime.FatalError();
	}
}

class JsonTree
{
	internal bool hasContent;
	append BumpAllocator alloc = .();
	public JsonElement root;

	[Inline]
	public JsonObjectData MakeOwnedObject(int reserve = 16) => new:alloc JsonObjectData((int32)reserve);

	[Inline]
	public JsonArrayData MakeOwnedArray(int reserve = 16) => new:alloc JsonArrayData(reserve);

	[Inline]
	public String MakeOwnedString(StringView str) => new:alloc String(str);

	[Inline]
	public String MakeOwnedString(int reserve = 32) => new:alloc String(reserve);
}

static class JsonPrinter
{
	static mixin Indent(String buffer, int indent)
	{
		for (int i < indent)
			buffer.Append('\t');
	}

	public static void Value(JsonElement el, String buffer, bool pretty, int indent)
	{
		var indent;
		switch (el)
		{
		case .Object(let object):
			buffer.Append('{');
			if (pretty)
			{
				indent++;
				buffer.Append('\n');
			}

			if (object.Count > 0)
			{
				for (let pair in object)
				{
					if (pretty)
						Indent!(buffer, indent);

					buffer.Append('"');
					buffer.Append(pair.key);
					buffer.Append("\":");

					Value(pair.value, buffer, pretty, indent);

					buffer.Append(',');
					if (pretty)
						buffer.Append('\n');
				}

				if (!pretty)
					buffer.RemoveFromEnd(1);
				else
				{
					buffer.RemoveFromEnd(2);
					buffer.Append('\n');
				}
			}

			if (pretty)
			{
				indent--;
				Indent!(buffer, indent);
			}

			buffer.Append('}');
		case .Array(let array):
			buffer.Append('[');
			if (pretty)
			{
				indent++;
				buffer.Append('\n');
			}

			if (array.Count > 0)
			{
				for (let value in array)
				{
					if (pretty)
						Indent!(buffer, indent);

					Value(value, buffer, pretty, indent);

					buffer.Append(',');
					if (pretty)
						buffer.Append('\n');
				}

				if (!pretty)
					buffer.RemoveFromEnd(1);
				else
				{
					buffer.RemoveFromEnd(2);
					buffer.Append('\n');
				}
			}

			if (pretty)
			{
				indent--;
				Indent!(buffer, indent);
			}

			buffer.Append(']');
		case .String(let string):
			buffer.Append('"');
			buffer.Append(string);
			buffer.Append('"');
		case .Number(let number):
			number.ToString(buffer);
		case .Bool(true):
			buffer.Append("true");
		case .Bool(false):
			buffer.Append("false");
		case .Null:
			buffer.Append("null");
		default:
			Runtime.FatalError();
		}
	}
}

static class Json
{
	public static int readerMaxDepth = 0x100;
	public enum DuplicateKeyBehavior
	{
		Override,
		Error
	}
	public static DuplicateKeyBehavior readerDuplicateKeyBehavior;

	public static JsonResult ReadJson(StringView jsonString, JsonTree unusedTree)
	{
		if (unusedTree.hasContent)
			return .Err(.() {
				error = .Lib_TreeRootWasAlreadyUsed
			});
		unusedTree.hasContent = true;

		let builder = scope JsonBuilder(unusedTree);
		return builder.Build(jsonString, ref unusedTree.root);
	}

	[Inline]
	public static void WriteJson(JsonTree tree, String jsonBuffer, bool pretty = false)
	{
		JsonPrinter.Value(tree.root, jsonBuffer, pretty, 0);
	}
}

class JsonBuilder
{
	JsonTree tree;
	StringView inStr;
	StringView origStr;
	int currDepth;

	public this(JsonTree tree)
	{
		this.tree = tree;
	}

	mixin ConsumeEmpty()
	{
		inStr.TrimStart();
	}

	JsonError DoError(JsonErrorType error)
	{
		JsonError e = default;
		e.error = error;

		let i = inStr.Ptr - origStr.Ptr;
		var mostRecentNewLine = -1;
		var lines = 1;
		for (let j < i)
			if (origStr[j] == '\n')
			{
				lines++;
				mostRecentNewLine = j;
			}

		e.line = lines;
		e.column = i - mostRecentNewLine;

		return e;
	}

	public JsonResult Build(StringView str, ref JsonElement root)
	{
		Runtime.Assert(inStr == default);
		Debug.Assert(str.Ptr != null);
		inStr = str;
		origStr = str;

		ConsumeEmpty!();

		if (Value(ref root) case .Err(let err))
		{
			inStr = default;
			return .Err(err);
		}

		Debug.Assert(currDepth == 0);

		if (inStr.Length != 0)
		{
			let err = DoError(.Synatx_ExpectedEnd);
			inStr = default;
			return .Err(err);
		}
		return .Ok;
	}

	JsonResult Unescape(StringView str, String outString)
	{
		var ptr = str.Ptr;
		char8* endPtr = ptr + str.Length;

		while (ptr < endPtr)
		{
			char8 c = *(ptr++);
			if (c == '\\')
			{
				if (ptr == endPtr)
					return .Err(DoError(.Syntax_UnterminatedString));

				char8 nextC = *(ptr++);
				switch (nextC)
				{
				case '\"': outString.Append("\"");
				case '\\': outString.Append("\\");
				case 'b': outString.Append("\b");
				case 'f': outString.Append("\f");
				case 'n': outString.Append("\n");
				case 'r': outString.Append("\r");
				case 't': outString.Append("\t");
				case 'u':
					uint16 num = 0;
					mixin DoParse()
					{
						for (let i < 4)
						{
							if (ptr == endPtr)
								return .Err(DoError(.Syntax_InvalidEscapeSequence));
							let hexC = *(ptr++);

							if ((hexC >= '0') && (hexC <= '9'))
								num = num*0x10 + (uint8)(hexC - '0');
							else if ((hexC >= 'A') && (hexC <= 'F'))
								num = num*0x10 + (uint8)(hexC - 'A') + 10;
							else if ((hexC >= 'a') && (hexC <= 'f'))
								num = num*0x10 + (uint8)(hexC - 'a') + 10;
							else return .Err(DoError(.Syntax_InvalidEscapeSequence));
						}
					}
					DoParse!();

					if (ptr != endPtr && *ptr == '\\' && ptr + 1 != endPtr && *(ptr + 1) == 'u')
					{
						ptr += 2;
						let prevNum = num;
						num = 0;
						DoParse!();
						char32 utf16 = ((char32)num << 16) + prevNum;
						UTF16.Decode(.((char16*)&utf16, 2), outString);
						break;
					}

					outString.Append((char32)num);
				default:
					return .Err(DoError(.Syntax_InvalidEscapeSequence));
				}
				continue;
			}

			outString.Append(c);
		}

		return .Ok;
	}

	Result<int, JsonError> StringByteLength()
	{
		// leading " already gone

		let inLen = inStr.Length;
		var parsedStrLen = 0;
		bool isEscaped = false;
		int8 trailingBytes = 0;
		while (parsedStrLen < inLen && (isEscaped || inStr[[Unchecked]parsedStrLen] != '"'))
		{
			let char = inStr[[Unchecked]parsedStrLen];
			isEscaped = char == '\\' && !isEscaped;

			if (trailingBytes == 0 || (uint8)char <= 127)
			{
				trailingBytes = UTF8.sTrailingBytesForUTF8[char];

				if (char.IsControl)
					return .Err(DoError(.Syntax_ControlCharInString));
			}
			else trailingBytes--;
			
			parsedStrLen++;
		}

		if (inStr.Length <= parsedStrLen || inStr[[Unchecked]parsedStrLen] != '"')
			return .Err(DoError(.Syntax_UnterminatedString));
		return .Ok(parsedStrLen);
	}

	JsonResult StringProcess(int parsedStrLen, String finalString)
	{
		let stringContent = StringView(&inStr[0], parsedStrLen);
		Try!(Unescape(stringContent, finalString));
		Debug.Assert(!finalString.IsDynAlloc);

		// Remove string contents and ending quote (all guaranteed by StringLength())
		inStr.RemoveFromStart(parsedStrLen + 1);
		return .Ok;
	}

	JsonResult Value(ref JsonElement el)
	{
		if (inStr.Length < 1)
			return .Err(DoError(.Syntax_ExpectedValue));

		switch (inStr[[Unchecked]0])
		{
		case '{':
			inStr.RemoveFromStart(1);
			ConsumeEmpty!();
			
			if (inStr.Length < 1)
				return .Err(DoError(.Syntax_UnterminatedObject));
			if (inStr[[Unchecked]0] == '}')
			{
				inStr.RemoveFromStart(1);
				el = .Object(tree.MakeOwnedObject(0));
				break;
			}

			currDepth++;
			if (currDepth > Json.readerMaxDepth)
				return .Err(DoError(.Constraint_DepthTooGreat));

			let obj = tree.MakeOwnedObject(16);
			el = .Object(obj);

			while (true)
			{
				if (inStr[[Unchecked]0] != '"')
					return .Err(DoError(.Syntax_ExpectedKey));
				inStr.RemoveFromStart(1);

				let len = Try!(StringByteLength());

				let keyStrTemp = scope String(len);
				StringProcess(len, keyStrTemp);

				ConsumeEmpty!();
				if (inStr.Length < 1 || inStr[[Unchecked]0] != ':')
					return .Err(DoError(.Syntax_ExpectedColon));
				inStr.RemoveFromStart(1);
				ConsumeEmpty!();

				JsonElement valueEl = default;
				Try!(Value(ref valueEl)); // Will do ConsumeEmpty!()

				let newlyAdded = obj.TryAdd(keyStrTemp, let keyStrPtr, let valuePtr);
				if (newlyAdded)
				{
					Debug.Assert(*keyStrPtr == keyStrTemp);
					*keyStrPtr = tree.MakeOwnedString(keyStrTemp);
				}
				else if (Json.readerDuplicateKeyBehavior == .Error)
					return .Err(DoError(.Constraint_DuplicateObjectKey));
				*valuePtr = valueEl;

				if (inStr.Length < 1)
					return .Err(DoError(.Syntax_UnterminatedObject));
				if (inStr[[Unchecked]0] != ',')
					break;

				// Prepare for next k/v pair

				inStr.RemoveFromStart(1);
				ConsumeEmpty!();

				if (inStr.Length < 1)
					return .Err(DoError(.Syntax_UnterminatedObject));
			}

			if (inStr.Length < 1 || inStr[[Unchecked]0] != '}')
				return .Err(DoError(.Syntax_UnterminatedObject));
			inStr.RemoveFromStart(1);

			currDepth--;
		case '[':
			inStr.RemoveFromStart(1);
			ConsumeEmpty!();
			
			if (inStr.Length < 1)
				return .Err(DoError(.Syntax_UnterminatedArray));
			if (inStr[[Unchecked]0] == ']')
			{
				inStr.RemoveFromStart(1);
				el = .Array(tree.MakeOwnedArray(0));
				break;
			}
			
			currDepth++;
			if (currDepth > Json.readerMaxDepth)
				return .Err(DoError(.Constraint_DepthTooGreat));

			let arr = tree.MakeOwnedArray(32);
			el = .Array(arr);

			while (true)
			{
				JsonElement valueEl = default;
				Try!(Value(ref valueEl)); // Will do ConsumeEmpty!()

				arr.Add(valueEl);

				if (inStr.Length < 1)
					return .Err(DoError(.Syntax_UnterminatedArray));
				if (inStr[[Unchecked]0] != ',')
					break;

				// Prepare for next entry

				inStr.RemoveFromStart(1);
				ConsumeEmpty!();

				if (inStr.Length < 1)
					return .Err(DoError(.Syntax_UnterminatedObject));
			}

			if (inStr.Length < 1 || inStr[[Unchecked]0] != ']')
				return .Err(DoError(.Syntax_UnterminatedArray));
			inStr.RemoveFromStart(1);
			currDepth--;
		case '"':
			inStr.RemoveFromStart(1);
			let len = Try!(StringByteLength());

			let str = tree.MakeOwnedString(len);

			StringProcess(len, str);
			el = .String(str);
		case 't':
			inStr.RemoveFromStart(1);
			if (inStr.StartsWith("rue"))
			{
				el = .Bool(true);
				inStr.RemoveFromStart(3);
			}
			else return .Err(DoError(.Syntax_InvalidValue));
		case 'f':
			inStr.RemoveFromStart(1);
			if (inStr.StartsWith("alse"))
			{
				el = .Bool(false);
				inStr.RemoveFromStart(4);
			}
			else return .Err(DoError(.Syntax_InvalidValue));
		case 'n':
			inStr.RemoveFromStart(1);
			if (inStr.StartsWith("ull"))
			{
				el = .Null;
				inStr.RemoveFromStart(3);
			}
			else return .Err(DoError(.Syntax_InvalidValue));
		case '-', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9':
			int numLen = 1; // First was already detected just now
			if (inStr.Length > 0)
			{
				while (inStr.Length > numLen && {
					let char = inStr[numLen];
					char.IsNumber || char == '.' || char == '-' || char == '+' || char.ToLower == 'e'
				})
					numLen++;
			}
			var num = inStr.Substring(0, numLen);

			bool isNeg = false;
			if (num[0] == '-')
			{
				isNeg = true;
				num.RemoveFromStart(1);
			}

			double result = 0;
			double decimalMultiplier = 0;
			bool decimalStarted = false;

			let len = num.Length;
			for (var i = 0; i < len; i++)
			{
				char8 c = num[[Unchecked]i];

				if (c == 'e' || c == 'E')
				{
					if (!decimalStarted
						|| i == len - 1)
						return .Err(DoError(.Syntax_InvalidNumber));

					// Parsing this is the last thing we do, so just use i here as well...
					i++;
					let firstChar = i;

					bool expIsNeg = false;
					int expRes = 0;

					for (; i < len; i++)
					{
						char8 expChar = num[[Unchecked]i];

						if (i == firstChar)
						{
							if (expChar == '-')
							{
								expIsNeg = true;
								continue;
							}
							else if (expChar == '+')
								continue;
						}

						if ((expChar >= '0') && (expChar <= '9'))
						{
							expRes *= 10;
							expRes += (int32)(expChar - '0');
						}
						else return .Err(DoError(.Syntax_InvalidNumber));
					}

					int exponent = expIsNeg ? -expRes : expRes;
					result *= Math.Pow(10, exponent);

					break;
				}

				decimalStarted = true;

				if (c == '.')
				{
					if (decimalMultiplier != 0 || i == len - 1 || !num[i + 1].IsNumber)
						return .Err(DoError(.Syntax_InvalidNumber));
					decimalMultiplier = 0.1;

					continue;
				}
				if (decimalMultiplier != 0)
				{
					if ((c >= '0') && (c <= '9'))
					{
						result += (.)(c - '0') * decimalMultiplier;
						decimalMultiplier *= 0.1;
					}
					else return .Err(DoError(.Syntax_InvalidNumber));

					continue;
				}

				if ((c >= '0') && (c <= '9'))
				{
					result *= 10;
					result += (.)(c - '0');
				}
				else return .Err(DoError(.Syntax_InvalidNumber));
			}
			
			inStr.RemoveFromStart(numLen);
			el = .Number(isNeg ? (result * -1) : result);
		default:
			return .Err(DoError(.Syntax_InvalidValue));
		}

		ConsumeEmpty!();
		return .Ok;
	}
}

/*
------------------------------------------------------------------------------
MIT License

Copyright (c) 2022 EinScott

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