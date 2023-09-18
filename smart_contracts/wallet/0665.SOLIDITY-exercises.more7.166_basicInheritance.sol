//SPDX-License-Identifier: MIT

pragma solidity >=0.8.18;

contract Apple {
    string internal tokenName;
    uint internal tokenMaxSupply;

    constructor(string memory _name, uint _supply) {
        tokenName = _name;
        tokenMaxSupply = _supply;
    }
}

contract Orange is Apple {

    constructor(string memory _word, uint _num) Apple(_word, _num) {
    }

    function getSupply() external view returns(uint) {
        return tokenMaxSupply;
    }

    function getName() external view returns(string memory) {
        return tokenName;
    }

}