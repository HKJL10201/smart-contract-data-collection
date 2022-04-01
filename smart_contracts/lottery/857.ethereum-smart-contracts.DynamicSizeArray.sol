//SPX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract DynamicSizeArray{

    uint [] public numbers;

    function getLength() public view returns(uint){

        return numbers.length;
    }

    function addElement(uint item) public{

        numbers.push(item);
    }

    function getElement(uint index) public view returns(uint){

        require(index < numbers.length,"element does not exist at this index");

        return numbers[index];

    }

    function popElement() public{

        numbers.pop();
    }

    function f() public{

        //creating a memeory array 
        uint[] memory y = new uint[](3);

        y[0] = 10;
        y[1] = 20;
        y[2] = 30;

        numbers = y;

    }


}