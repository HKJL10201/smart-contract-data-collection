pragma solidity ^0.5.1;
library Tools {
    function uint2str(uint a) internal pure returns(string memory) {
        uint8 b;
        string memory str = "";
        byte c;
        bytes memory d = new bytes(1);
        do {
            b = uint8(a % 10);
            c = byte(b + 48);
            d[0] = c; //2781 2781
            str = concatStrings(string(d),str);
            a /= 10;
        } while (a > 0);
        return(str);
    }
    function concatStrings(string memory a, string memory b) 
        internal pure returns(string memory) {
        bytes memory sa = bytes(a);
        bytes memory sb = bytes(b);
        uint len = sa.length + sb.length;
        bytes memory sc = new bytes(len);
        uint i;
        for (i=0; i < sa.length; i++)
            sc[i] = sa[i];
        for (i=0; i < sb.length; i++)
            sc[i+sa.length] = sb[i];
        return(string(sc));  
    } 
    function concatStrings(string memory a, string memory b, string memory c) 
        internal pure returns(string memory) {
        return(concatStrings(concatStrings(a, b), c));
    }
    function concatStrings(string memory a, string memory b, string memory c, string memory d) 
        internal pure returns(string memory) {
        return(concatStrings(concatStrings(a, b), concatStrings(c, d)));
    }
    function isStringsEqual(string memory a, string memory b) 
        internal pure returns(bool) {
        if (bytes(a).length != bytes(b).length)
            return(false);
        for (uint i=0; i < bytes(a).length; i++)
            if (bytes(a)[i] != bytes(b)[i])
                return(false);
        return(true);
    }
}