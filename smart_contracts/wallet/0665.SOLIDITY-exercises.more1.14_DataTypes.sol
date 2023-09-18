pragma solidity >=0.8.7;


contract DataTypes {
    
    uint myNumber = 9;
    int yourNumber = -68;
    uint8 herNumber = 17;
    bool public isSolidityCool = true;
    address public owner = msg.sender;
    bytes32 public byteMes = "hello byte";
    string public stringMes = "hello string";
    
    function getVariables() public view returns(uint, int, uint8, bool, address, bytes32, string memory) {
        return( myNumber, yourNumber, herNumber, isSolidityCool, owner, byteMes, stringMes);
    }
}