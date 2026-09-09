//
//  encoding.h
//  mkxp-z
//
//  Created by ゾロアーク on 6/22/21.
//

#ifndef encoding_h
#define encoding_h

#include <string>
#include <string.h>

#include "util/encoding.h"
#include <iconv.h>
#include <uchardet.h>
#include <errno.h>

namespace Encoding {

// Validate the bytes before using statistical legacy-encoding detection.
// In particular, uchardet can fail to recognize UTF-8 supplementary characters.
static bool isValidUTF8(const std::string &str) {
    for (size_t i = 0; i < str.size();) {
        unsigned char lead = static_cast<unsigned char>(str[i++]);
        if (lead < 0x80) continue;
        unsigned int codepoint, minimum;
        size_t continuation;
        if (lead >= 0xC2 && lead <= 0xDF) {
            codepoint = lead & 0x1F; minimum = 0x80; continuation = 1;
        } else if (lead >= 0xE0 && lead <= 0xEF) {
            codepoint = lead & 0x0F; minimum = 0x800; continuation = 2;
        } else if (lead >= 0xF0 && lead <= 0xF4) {
            codepoint = lead & 0x07; minimum = 0x10000; continuation = 3;
        } else {
            return false;
        }
        if (str.size() - i < continuation) return false;
        while (continuation--) {
            unsigned char next = static_cast<unsigned char>(str[i++]);
            if ((next & 0xC0) != 0x80) return false;
            codepoint = (codepoint << 6) | (next & 0x3F);
        }
        if (codepoint < minimum || codepoint > 0x10FFFF ||
            (codepoint >= 0xD800 && codepoint <= 0xDFFF)) return false;
    }
    return true;
}

static std::string getCharset(std::string &str) {
    if (isValidUTF8(str)) return "UTF-8";

    uchardet_t ud = uchardet_new();
    uchardet_handle_data(ud, str.c_str(), str.length());
    uchardet_data_end(ud);
    
    std::string ret(uchardet_get_charset(ud));
    uchardet_delete(ud);
    
    if (ret.empty())
        throw Exception(Exception::MKXPError, "Could not detect string encoding", str.c_str());
    return ret;
}

static std::string convertString(std::string &str, const char *charset) {
    // Conversion doesn't need to happen if it's already UTF-8
    if (!strcmp(charset, "UTF-8") || !strcmp(charset, "ASCII")) {
        return std::string(str);
    }
    
    iconv_t cd = iconv_open("UTF-8", charset);
    
    size_t inLen = str.size();
    size_t outLen = inLen * 4;
    std::string buf(outLen, '\0');
    char *inPtr = const_cast<char*>(str.c_str());
    char *outPtr = const_cast<char*>(buf.c_str());
    
    errno = 0;
    size_t result = iconv(cd, &inPtr, &inLen, &outPtr, &outLen);
    
    iconv_close(cd);
    
    if (result != (size_t)-1 && errno == 0)
    {
        buf.resize(buf.size()-outLen);
    }
    else {
        throw Exception(Exception::MKXPError, "Unable to convert string (Guessed encoding: %s)", charset);
    }
    
    return buf;
}

static std::string convertString(std::string &str) {
    std::string converted = convertString(str, getCharset(str).c_str());
    // A leading BOM describes the file encoding; it is not JSON/title text.
    if (converted.compare(0, 3, "\xEF\xBB\xBF") == 0) converted.erase(0, 3);
    return converted;
}
}

#endif /* encoding_h */
