pragma solidity ^0.4.11;

contract Ownable {
	address public owner;
	address public ownerCandidate;
	event OwnerTransfer(address originalOwner, address currentOwner);

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function proposeNewOwner(address newOwner) public onlyOwner {
		require(newOwner != address(0) && newOwner != owner);
		ownerCandidate = newOwner;
	}

	function acceptOwnerTransfer() public {
		require(msg.sender == ownerCandidate);
		OwnerTransfer(owner, ownerCandidate);
		owner = ownerCandidate;
	}
}