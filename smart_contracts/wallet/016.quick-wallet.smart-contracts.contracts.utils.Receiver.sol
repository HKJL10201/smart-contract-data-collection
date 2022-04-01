pragma solidity ^0.5.0;


contract Receiver {

    event Show(string text);

    function showMessage(string memory text)
        public payable returns (bool)
    {
        emit Show(text);
        return true;
    }

    function fail() public {
        revert("Receiver: function failed");
    }

}
