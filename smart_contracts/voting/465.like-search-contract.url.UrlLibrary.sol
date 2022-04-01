// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// ┌────────────────────────────────────────────────────────────────────────────────────────────────┐
// │                                              href                                              │
// ├──────────┬──┬─────────────────────┬────────────────────────┬───────────────────────────┬───────┤
// │ protocol │  │        auth         │          host          │           path            │ hash  │
// │          │  │                     ├─────────────────┬──────┼──────────┬────────────────┤       │
// │          │  │                     │    hostname     │ port │ pathname │     search     │       │
// │          │  │                     │                 │      │          ├─┬──────────────┤       │
// │          │  │                     │                 │      │          │ │    query     │       │
// "  https:   //    user   :   pass   @ sub.example.com : 8080   /p/a/t/h  ?  query=string   #hash "
// │          │  │          │          │    hostname     │ port │          │                │       │
// │          │  │          │          ├─────────────────┴──────┤          │                │       │
// │ protocol │  │ username │ password │          host          │          │                │       │
// ├──────────┴──┼──────────┴──────────┼────────────────────────┤          │                │       │
// │   origin    │                     │         origin         │ pathname │     search     │ hash  │
// ├─────────────┴─────────────────────┴────────────────────────┴──────────┴────────────────┴───────┤
// │                                              href                                              │
// └────────────────────────────────────────────────────────────────────────────────────────────────┘
library UrlLibrary {
    using UrlLibrary for UrlLibrary.Url;
    bytes1 private constant NULL = 0x00;
    bytes1 private constant US = 0x1F;
    struct Url {
        string scheme; //protocol without :
        string username;
        string hostname; // IPV6 without []
        uint16 port;
        string pathname;
        string search;
        string fragment; // hash without #
    }

    // https://url.spec.whatwg.org/
    // The WHATWG algorithm defines four "percent-encode sets" that describe ranges of characters that must be percent-encoded
    function c0ControlSet(bytes1 codePoint) internal pure returns (bool) {
        return (codePoint >= NULL && codePoint <= US) || codePoint > "~";
    }

    function fragmentSet(bytes1 codePoint) internal pure returns (bool) {
        return
            c0ControlSet(codePoint) ||
            codePoint == " " ||
            codePoint == '"' ||
            codePoint == "<" ||
            codePoint == ">" ||
            codePoint == "`";
    }

    function pathSet(bytes1 codePoint) internal pure returns (bool) {
        return
            fragmentSet(codePoint) ||
            codePoint == "#" ||
            codePoint == "?" ||
            codePoint == "{" ||
            codePoint == "}";
    }

    function userinfoSet(bytes1 codePoint) internal pure returns (bool) {
        return
            pathSet(codePoint) ||
            codePoint == "/" ||
            codePoint == ":" ||
            codePoint == ";" ||
            codePoint == "=" ||
            codePoint == "@" ||
            codePoint == "[" ||
            codePoint == "\\" ||
            codePoint == "]" ||
            codePoint == "^" ||
            codePoint == "|";
    }

    function forbiddenHostSet(bytes1 codePoint) internal pure returns (bool) {
        return
            codePoint == " " ||
            codePoint == "#" ||
            codePoint == "%" ||
            codePoint == "/" ||
            codePoint == ":" ||
            codePoint == "?" ||
            codePoint == "@" ||
            codePoint == "[" ||
            codePoint == "\\" ||
            codePoint == "]";
    }

    function ASCIILowwerAlpha(bytes1 codePoint) internal pure returns (bool) {
        return codePoint >= "a" && codePoint <= "z";
    }

    function hexDigit(bytes1 codePoint) internal pure returns (bool) {
        return ASCIIDigit(codePoint) || (codePoint >= "a" && codePoint <= "f");
    }

    function ASCIIDigit(bytes1 codePoint) internal pure returns (bool) {
        return codePoint >= "0" && codePoint <= "9";
    }

    function validate(Url memory url)
        internal
        pure
        returns (bool, string memory)
    {
        uint256 c;
        bytes memory scheme = bytes(url.scheme);
        if (scheme.length == 0) {
            return (false, "s0");
        }
        bytes memory username = bytes(url.username);
        c = 0;
        while (c < username.length) {
            if (userinfoSet(username[c])) {
                return (false, "u0");
            }
            c++;
        }
        bytes memory hostname = bytes(url.hostname);
        // ipv6
        if (hostname.length > 0) {
            if (hostname[0] == "[" && hostname[hostname.length - 1] == "]") {
                c = 1;
                while (c < hostname.length - 1) {
                    if (!hexDigit(hostname[c]) && hostname[c] != ":") {
                        return (false, "h0");
                    }
                    c++;
                }
            } else {
                c = 0;
                while (c < hostname.length) {
                    if (
                        !ASCIILowwerAlpha(hostname[c]) &&
                        !ASCIIDigit(hostname[c]) &&
                        hostname[c] != "." &&
                        hostname[c] != "-"
                    ) {
                        return (false, "h1");
                    }
                    c++;
                }
            }
        }
        bytes memory pathname = bytes(url.pathname);
        c = 0;
        while (c < pathname.length) {
            if (pathSet(pathname[c])) {
                return (false, "p0");
            }
            c++;
        }
        bytes memory search = bytes(url.search);
        c = 0;
        while (c < search.length) {
            if (c0ControlSet(search[c])) {
                return (false, "sch0");
            }
            c++;
        }
        bytes memory fragment = bytes(url.fragment);
        c = 0;
        while (c < fragment.length) {
            if (fragmentSet(fragment[c])) {
                return (false, "f0");
            }
            c++;
        }
        return (true, "");
    }
}
