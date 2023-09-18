pragma solidity >=0.8.7;

contract Counter {
    uint private number = 1;

    function incrementNumber()public {
        number+=11;
    }
    function decreaseNumber()public {
        number = number-1;
    }

    function getNumber()public view returns(uint) {
        return number;
    }
}