// Exploring different ways to update contracts and their storage.
// Notes:
// Using the lower level func delegatecall you can delegate the definition of storage in one contract from another one. Ie. In the example below, you can change the FirstCaller num and sender variables, using the second caller contract.
// Note that for the delegatecall to work, the two contracts needs to share the same variable layout, ie. have the same variables and types that you'd update when making that funciton call

pragma solidity ^0.5.0;

contract Base {
    uint public num;
    address public sender;
    function setNum(uint _num) public {
        num = _num;
        sender = msg.sender;
    }
}

contract FirstCaller {
      uint public num;
      address public sender;
        
      function setBaseNum(address _base, uint _num) public{
                  Base base = Base(_base);
                        base.setNum(_num);
        }

        function callSetNum(address _base, uint _num) public {
            (bool status, bytes memory returnData) = _base.call(abi.encodeWithSignature("setNum(uint256)", _num));
        }

        function delegatecallSetNum(address _base, uint _num) public {
            (bool status, bytes memory returnData) = _base.delegatecall(abi.encodeWithSignature("setNum(uint256)", _num));
        }
}

contract SecondCaller {
    function callThrough(FirstCaller _fc, Base _base, uint _num) public {_fc.delegatecallSetNum(address(_base), _num);
    }
}
