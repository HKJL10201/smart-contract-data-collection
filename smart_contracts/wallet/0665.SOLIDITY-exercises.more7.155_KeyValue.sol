//SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

contract KeyValue {

    function multiValues(uint a, uint b, uint c, address somebody, bool isSomething) public pure returns(uint) {
        return 5;
    }

    //classic way: function parameters in order
    function call() external view returns(uint) {
        uint xx = multiValues(7, 8, 9, address(0), false);
        return xx;
    }

    //the same function as above, but function parameters not in the order
    function call2() external view returns(uint) {
        uint yy = multiValues({ a: 7, somebody: address(0), isSomething: true, c: 4, b: 88});
        return yy;
    }
}

contract KeyValue2 {

    uint public myNum = 8;
    string public myWord = "apple";
    bool public isSomething = true;

    function changeValues(uint _number, string memory _word, bool _status) public {
        myNum = _number;
        myWord = _word;
        isSomething = _status;
    }
    //in order
    function call1(uint _num, string memory _wor, bool _sta) external {
        changeValues(_num, _wor, _sta);
    }
    //not in order
    function call2(uint _n, string memory _w, bool _s) external {
        changeValues({_number: _n, _status: _s, _word: _w});
    }
}