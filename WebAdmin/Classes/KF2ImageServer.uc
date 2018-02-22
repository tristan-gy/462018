/**
 * WebApplication that provides static content, even though it is called
 * "ImageServer" it also serves other static content like javascript files.
 *
 * Copyright (C) 2011 Tripwire Interactive LLC
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class KF2ImageServer extends ImageServer config(WebAdmin);

/**
 * if true don't try to send gzip files
 */
var config bool bNoGzip;

function string normalizeUri(string uri)
{
    local array<string> str;
    local int i;
    ParseStringIntoArray(repl(uri, "\\", "/"), str, "/", true);
    for (i = str.length-1; i >= 0; i--)
    {
        if (str[i] == "..")
        {
            i -= 1;
            if (i < 0)
            {
                str.remove(0, 1);
            }
            else {
                str.remove(i, 2);
            }
        }
    }
    JoinArray(str, uri, "/");
    return "/"$uri;
}

function Query(WebRequest Request, WebResponse Response)
{
	local string ext;
	local int idx;

	if (InStr(Request.URI, "..") != INDEX_NONE)
	{
	   Request.URI = normalizeUri(Request.URI);
    }

	idx = InStr(Request.URI, ".", true);
	if (idx != INDEX_NONE)
	{
		// get the file extension
		ext = Mid(Request.URI, idx+1);

		// if ?gzip was present, send the gzip file if the browser supports it.
		if (!bNoGzip && Request.GetVariableCount("gzip") > 0)
		{
			if (InStr(","$Request.GetHeader("accept-encoding")$",", ",gzip,") != INDEX_NONE)
			{
				if (Response.FileExists(Path $ Request.URI $ ".gz"))
				{
					response.AddHeader("Content-Encoding: gzip");
					Request.URI = Request.URI$".gz";
				}
				else {
					`warn("Tried to serve non existing gzip file: " $ Path $ Request.URI $ ".gz",,'WebAdmin');
				}
			}
		}
	}

	if( ext ~= "js" )
	{
		Response.SendStandardHeaders("text/javascript", true);
		Response.IncludeBinaryFile( Path $ Request.URI );
		return;
	}
	else if( ext ~= "css" )
	{
		Response.SendStandardHeaders("text/css", true);
		Response.IncludeBinaryFile( Path $ Request.URI );
		return;
	}
	else if( ext ~= "ico" )
	{
		Response.SendStandardHeaders("image/x-icon", true);
		Response.IncludeBinaryFile( Path $ Request.URI );
		return;
	}
	else if( ext ~= "gz" )
	{
		Response.SendStandardHeaders("application/x-gzip", true);
		Response.IncludeBinaryFile( Path $ Request.URI );
		return;
	}
	super.query(Request, Response);
}
