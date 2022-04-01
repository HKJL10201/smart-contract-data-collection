pragma solidity 0.5.16;

contract ApprovalContract {

	address public sender;
	address payable public receiver;
	address public constant approver = 0x7E1235108999b53a2159EF7733d8960c2E5fD8eE ;

// Conforms to payable. 
// External means it can be called publicly
	function deposit(address payable _receiver) external payable {

		require(msg.value > 0);
		sender = msg.sender;
		receiver = _receiver;
	}

// pure - reads a constant so will not cost any gas for execution
	function viewApprover() external pure returns(address) {
		return approver;
	}

	function approve() external {
		require(msg.sender == approver);
		receiver.transfer(address(this).balance);
	}
}
