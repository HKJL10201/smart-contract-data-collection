pragma solidity >= 0.4.0 < 0.8.0;

contract SimpleStorage {
    uint storedData;
    function set(uint x) public {
        storedData = x;
    }
    function get() public view returns (uint) {
        return storedData;
    }
}


contract TransferEthers {
    function invest() external payable {
    }

    function balanceOf() external view returns(uint) {
        return address(this).balance;
    }

    function sendEther(address payable recepient) external {
        recepient.transfer(3 ether);
    }
}