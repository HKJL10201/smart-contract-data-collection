pragma solidity >=0.4.22 <0.7.0;

contract MiContrato {

    uint256 number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @return value of 'number'
     */
    function retreive() public view returns (uint256){
        return number;
    }
}