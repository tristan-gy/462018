/**
 * Various static utility functions
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class WebAdminUtils extends Object;

struct TranslitEntry
{
	/** from */
	var string f;
	/** to */
	var string t;
};

/** translit characters */
var localized array<TranslitEntry> translit;

var localized string msgUnknownTeam;

var const array<string> monthNames;
var const array<string> dayNames;
var const array<int> dowTable;

struct DateTime
{
	var int year;
	var int month;
	var int day;
	var int hour;
	var int minute;
	var int second;
};

static final function String translitText(coerce string inp)
{
	local int i;
	for (i = 0; i < default.translit.length; i++)
	{
		inp = Repl(inp, default.translit[i].f, default.translit[i].t);
	}
	return inp;
}

/**
 * Escape HTML tags in the given string. Expects the input to not contain any
 * escaped entities (i.e. &...;)
 */
static final function String HTMLEscape(coerce string inp)
{
	inp = translitText(inp);
	inp = Repl(inp, "&", "&amp;");
	inp = Repl(inp, "<", "&lt;");
	inp = Repl(inp, "\"", "&quot;");
	return Repl(inp, ">", "&gt;");
}

/**
 * Trim everything below ascii 32 from begin and end
 */
static final function String Trim(coerce string inp)
{
	local int b,e;
	b = 0;
	e = Len(inp)-1;
	while (b < e)
	{
		if (Asc(Mid(inp, b, 1)) > 32) break;
		b++;
	}
	while (e >= b)
	{
		if (Asc(Mid(inp, e, 1)) > 32) break;
		e--;
	}
	return mid(inp, b, e-b+1);
}

/**
 * Convert a color to the HTML equivalent
 */
static final function String ColorToHTMLColor(color clr)
{
	return "#"$Right(ToHex(clr.R), 2)$Right(ToHex(clr.G), 2)$Right(ToHex(clr.B), 2);
}

/**
 * Convert a HTML color to an unreal color
 */
static final function color HTMLColorToColor(string clr)
{
	local color res;
	local int col;
	clr = trim(clr);
	if (left(clr, 1) == "#")
	{
		clr = mid(clr, 1);
	}
	if (len(clr) != 6)
	{
		return res;
	}
	col = FromHex(clr);
	if (clr == "<<invalid>>")
	{
		return res;
	}
	res.R = (col & 0xff0000) >>> 16;
	res.G = (col & 0xff00) >>> 8;
	res.B = col & 0xff;
	res.A = 255;
	return res;
}

static final function int FromHex(out string hx)
{
	local int res, i, t, s;
	if (len(hx) > 8)
	{
		hx = "<<invalid>>";
		return -1;
	}
	hx = caps(hx);
	s = 0;
	for (i = len(hx) - 1; i >= 0; --i)
	{
		t = asc(mid(hx, i, 1));
		if (t >= 48 && t <= 57)
		{
			t -= 48;
		}
		else if (t >= 65 && t <= 70)
		{
			t -= 55;
		}
		else {
			hx = "<<invalid>>";
			return -1;
		}
		if (s > 0) {
			t = t << s;
		}
		res = res | t;
		s += 4;
	}
	return res;
}


/**
 * Parse a timestamp to a DateTime structure.
 * The format of the timestamp is: YYYY/MM/DD - HH:MM:SS
 */
static final function bool getDateTime(out DateTime record, string ts)
{
	local int idx;
	local array<string> parts;
	ts -= " ";
	idx = InStr(ts, "-");
	if (idx == INDEX_NONE) return false;
	ParseStringIntoArray(Left(ts, idx), parts, "/", false);
	if (parts.length != 3) return false;
	record.year = int(parts[0]);
	record.month = int(parts[1]);
	record.day = int(parts[2]);
	ParseStringIntoArray(Mid(ts, idx+1), parts, ":", false);
	if (parts.length != 3) return false;
	record.hour = int(parts[0]);
	record.minute = int(parts[1]);
	record.second = int(parts[2]);
	return true;
}

// From:  07 Oct 2011 22:35:56 GMT
// To:    Fri, 07-Oct-2011 22:35:56 GMT
static final function string convertToRfc2109Date(string dateString)
{
	local array<string> parts;
	local int month, dow;
	ParseStringIntoArray(dateString, parts, " ", true);
	if (parts.Length != 5)
	{
		`log("Cannot convert date "$dateString$" to RFC 2019, not the correct number of parts",,'WebAdmin');
		return "";
	}
	month = default.monthNames.find(parts[1]);
	if (month == INDEX_NONE)
	{
		`log("Cannot convert date "$dateString$" to RFC 2019, unknown month: "$parts[1],,'WebAdmin');
		return "";
	}
	dow = getDayOfWeek(int(parts[2]), month, int(parts[0]));
	if (dow < 0 || dow > 6)
	{
		`log("Cannot convert date "$dateString$" to RFC 2019, wrong day of week value: "$dow,,'WebAdmin');
		return "";
	}
	return default.dayNames[dow]$", "$parts[0]$"-"$parts[1]$"-"$parts[2]@parts[3]@parts[4];
}

/**
 * return the day of the week. 0 = sunday, 1 = monday
 */
static final function int getDayOfWeek(int year, int month, int day)
{
	// Sakamoto's algorithm
	if (month < 3) {
		--year;
	}
    return (year + year/4 - year/100 + year/400 + default.dowTable[month-1] + day) % 7;
}

static final function string getLocalized(coerce string data)
{
	local array<string> parts;
	if (!(Left(data, 9) ~= "<Strings:")) return data;
	data = Mid(data, 9, Len(data)-10);
	ParseStringIntoArray(data, parts, ".", true);
	if (parts.length >= 3)
	{
		return Localize(parts[1], parts[2], parts[0]);
	}
	return "";
}

static final function parseUrlOptions(out array<KeyValuePair> options, string url)
{
	local string part;
	local array<string> parts;
	local int idx, i;
	local KeyValuePair kv;

	ParseStringIntoArray(url, parts, "?", true);
	foreach parts(part)
	{
		i = InStr(part, "=");
		if (i == INDEX_NONE)
		{
			kv.Key = part;
			kv.Value = "";
		}
		else {
			kv.Key = Left(part, i);
			kv.Value = Mid(part, i+1);
		}
		for (idx = 0; idx < options.length; idx++)
		{
			if (kv.key ~= options[idx].key)
			{
				break;
			}
		}
		`Log("Add "$kv.key$" at "$idx);
		options[idx] = kv;
	}
}

/**
 * Check if the target matches the mask, which can contain * for 0 or more
 * matching characters. Use ** for greedy matching. For example:
 * 'x*y' matches 'xzy', but not 'xzyy'. 'x**y' will match.
 */
static final function bool maskedCompare(coerce string target, string mask, optional bool caseInsensitive)
{
	local int idx;
	local string part;
	local bool greedy;

	if (caseInsensitive)
	{
		mask = caps(mask);
		target = caps(target);
	}

	do
	{
		// quick escape
		if (mask == "*" || mask == "**") return true;

		idx = InStr(mask, "*");
		if (idx < 0)
		{
			// no * thus match whole
			return target == mask;
		}

		if (idx > 0)
		{
			// check prefix
			part = left(mask, idx);
			mask = mid(mask, idx);

			if (left(target, len(part)) != part)
			{
				return false;
			}

			// remove matched part from target
			target = mid(target, len(part));
		}
		else {
			// idx can only be 0 at this point

			// find the substring between 2 wildcards
			greedy = (left(mask, 2) == "**");
			idx = InStr(mask, "*",,, greedy?2:1);
			if (idx < 0)
			{
				idx = len(mask);
			}
			if (greedy)
			{
				part = mid(mask, 2, idx-1);
				mask = mid(mask, idx+1);
			}
			else {
				part = mid(mask, 1, idx-1);
				mask = mid(mask, idx);
			}

			if (len(part) == 0)
			{
				// in case of ***?
				continue;
			}

			idx = InStr(target, part, greedy);
			if (idx == INDEX_NONE)
			{
				// part was not found in the string
				return false;
			}

			// remove everything up to and including the matched part
			target = mid(target, idx+len(part));
		}
	} until (len(mask) == 0 || len(target) == 0);

	return (target == mask) || (mask == "*") || (mask == "**");
}

static final function string removeUrlOption(string url, coerce string option)
{
	local array<string> opts;
	opts[0] = option;
	return removeUrlOptions(url, opts);
}

static final function string removeUrlOptions(string url, array<string> options)
{
	local string opt;
	local int idx, end;

	foreach options(opt)
	{
		idx = 0;
		while (idx != -1)
		{
			idx = InStr(url,opt,,true,idx);
			if (idx == -1) continue;
			// doesn't start with ? or nothing; so not an option
			if (idx > 0 && Mid(url, idx-1, 1) != "?")
			{
				idx += Len(opt);
				continue;
			}
			// find end
			end = idx+Len(opt);
			if (end >= len(url))
			{
				// nop
			}
			else if (Mid(url, end, 1) == "=")
			{
				// start of a value
				end = InStr(url, "?",,, idx);
				if (end == -1) end = Len(url);
			}
			else if (Mid(url, end, 1) != "?")
			{
				// ?foobar?quux was found for option 'foo'
				idx = end;
				continue;
			}
			url = Mid(url, 0, idx-1)$Mid(url, end);
		}
	}
	return url;
}

static function string getTeamNameEx(TeamInfo team)
{
	if (team == none) return getTeamName(-1);
	if (team.GetHumanReadableName() ~= "Team")
	{
		return getTeamName(team.TeamIndex);
	}
	return team.GetHumanReadableName();
}

static function string getTeamName(int index)
{
//FIXME
/*	if (index == `AXIS_TEAM_INDEX)
	{
		return Localize("ROLocalMessageGame", "Axis", "ROGame");
	}
	else if (index == `ALLIES_TEAM_INDEX)
	{
		return Localize("ROLocalMessageGame", "Allies", "ROGame");
	}*/
	return repl(default.msgUnknownTeam, "%d", index+1);
}

/**
 * Extract the IP from a string. Makes sure that if a ip:port is passed, only ip is returned.
 */
static function string extractIp(string str)
{
	// assumes IPv4
	local int idx;
	if (InStr(str, ".") > 0)
	{
		idx = InStr(str, ":");
		if (idx != INDEX_NONE)
		{
			str = Left(str, idx);
		}
	}
	// TODO: verify ip-ness?
	return str;
}

static function string UniqueNetIdToString(UniqueNetId aId)
{
	local UniqueNetId empty;
	if (empty == aId)
	{
		return "";
	}
	return class'OnlineSubsystem'.static.UniqueNetIdToString(aId);
}

static function string iso8601datetime(int year, int month, int day, int hour,int minute, int second,int msec)
{
	return ""$year$"-"$right("0"$month, 2)$"-"$right("0"$day, 2)$"T"$
		right("0"$hour, 2)$":"$right("0"$minute, 2)$":"$right("0"$second, 2)$"."$right("00"$msec, 3);
}

defaultproperties
{
	monthNames[1]="Jan"
	monthNames[2]="Feb"
	monthNames[3]="Mar"
	monthNames[4]="Apr"
	monthNames[5]="May"
	monthNames[6]="Jun"
	monthNames[7]="Jul"
	monthNames[8]="Aug"
	monthNames[9]="Sep"
	monthNames[10]="Oct"
	monthNames[11]="Nov"
	monthNames[12]="Dec"

	dayNames[0]="Sun"
	dayNames[1]="Mon"
	dayNames[2]="Tue"
	dayNames[3]="Wed"
	dayNames[4]="Thu"
	dayNames[5]="Fri"
	dayNames[6]="Sat"

	dowTable[0]=0
	dowTable[1]=3
	dowTable[2]=2
	dowTable[3]=5
	dowTable[4]=0
	dowTable[5]=3
	dowTable[6]=5
	dowTable[7]=1
	dowTable[8]=4
	dowTable[9]=6
	dowTable[10]=2
	dowTable[11]=4
}
