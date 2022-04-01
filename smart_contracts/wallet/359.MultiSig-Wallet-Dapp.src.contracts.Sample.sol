pragma solidity ^0.5.7;

contract Sample {
    
event Output(
    string val);
    
  function uint2str(uint _i) public payable returns (string memory _uintAsString) {
    if (_i == 0) {
        return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
        len++;
        j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len - 1;
    while (_i != 0) {
        bstr[k--] = byte(uint8(48 + _i % 10));
        _i /= 10;
    }
    emit Output(string(bstr));
    return string(bstr);
}
}

