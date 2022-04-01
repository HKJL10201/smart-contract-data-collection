pragma solidity^0.4.18;

contract Mortal {
    address owner;

    // used to modify a function
    // wraps the function
    // underscore is replaced by function content
    modifier onlyowner() {
        if (owner == msg.sender) {
            _;
        } else {
            revert();
        }
    }

    function Mortal() public {
        owner = msg.sender;
    }

    function kill() public onlyowner {
        selfdestruct(owner);
    }
}
