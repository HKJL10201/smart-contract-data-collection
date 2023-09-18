pragma solidity ^0.5.0;

contract ApprovalContract {

  address public sender;
  address payable public receiver;
  address constant public approver = 0xC5fdf4076b8F3A5357c5E395ab970B5B54098Fef;

  constructor() public {
    // tbd
  }

  function deposit(address payable _receiver) external payable {
    require(msg.value > 0);
    sender = msg.sender;
    receiver = _receiver;
  }

  function viewApprover() external pure returns(address) {
    return(approver);
  }

  function approve() external {
    require(msg.sender == approver);
    receiver.transfer(address(this).balance);
  }

}
