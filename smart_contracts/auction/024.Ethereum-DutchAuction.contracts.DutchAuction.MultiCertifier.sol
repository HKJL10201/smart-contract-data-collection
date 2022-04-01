//! MultiCertifier contract.
//! By Parity Technologies, 2017.
//! Released under the Apache Licence 2.

pragma solidity ^0.4.24;

import '../Libraries/Ownable.sol';


// From Certifier.sol
contract Certifier {
	event Confirmed(address indexed who);
	event Revoked(address indexed who);
	function certified(address) public view returns (bool);
}

/**
 * Contract to allow multiple parties to collaborate over a certification contract.
 * Each certified account is associated with the delegate who certified it.
 * Delegates can be added and removed only by the contract owner.
 */
contract MultiCertifier is Certifier, Ownable {
	modifier only_delegate { require (msg.sender == owner || delegates[msg.sender]); _; }
	modifier only_certifier_of(address who) { require (msg.sender == owner || msg.sender == certs[who].certifier); _; }
	modifier only_certified(address who) { require (certs[who].active); _; }
	modifier only_uncertified(address who) { require (!certs[who].active); _; }

	event Confirmed(address indexed who, address indexed by);
	event Revoked(address indexed who, address indexed by);
	event NewOwner(address indexed old, address indexed current);

	struct Certification {
		address certifier;
		bool active;
	}

	constructor() public {
		owner = msg.sender;
	}

	function certify(address _who)
		public
		only_delegate
		only_uncertified(_who)
	{
		certs[_who].active = true;
		certs[_who].certifier = msg.sender;
		emit Confirmed(_who, msg.sender);
	}

	function revoke(address _who)
		public
		only_certifier_of(_who)
		only_certified(_who)
	{
		certs[_who].active = false;
		emit Revoked(_who, msg.sender);
	}

	function certified(address _who) public view returns (bool) { return certs[_who].active; }
	function getCertifier(address _who) public view returns (address) { return certs[_who].certifier; }
	function addDelegate(address _new) public onlyOwner { delegates[_new] = true; }
	function removeDelegate(address _old) public onlyOwner { delete delegates[_old]; }

	mapping (address => Certification) public certs;
	mapping (address => bool) public delegates;
}
