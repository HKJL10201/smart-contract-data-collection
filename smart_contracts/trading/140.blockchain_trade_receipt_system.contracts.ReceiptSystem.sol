pragma solidity ^0.4.11;

import './Ownable.sol';
import './SafeMath.sol';

contract ReceiptSystem is Ownable {
	using SafeMath for uint256;

	enum InstitutionType { //Types of institutions
		Bank,
		Shipping,
		Warehouse,
		Trader
	}

	struct Institution { //Data structure for institution info
		uint256 id;
		bytes32 name;
		InstitutionType insType;
	}

	struct ReceiptStats { //Receipt data
		bytes32 hash;
		bytes16 algorithm; //Hashing algorithm
		uint256 issuedBy;
		uint256 inPossessionBy;
		uint256 timestamp;
		bool valid;
	}

	uint256 private lastID = 0;
	mapping(address => uint256) public addrToIDs;
	mapping(uint256 => Institution) public idToInstitution;
	mapping(bytes32 => ReceiptStats) public receiptHashes;

	modifier onlyInstitution() {
		require(addrToIDs[msg.sender] != 0); //Must be issued by registered institution
		_;
	} 

	modifier onlyBank() {
		uint256 id = addrToIDs[msg.sender];
		require(id != 0); //Must be issued by registered institution
		require(idToInstitution[id].insType == InstitutionType.Bank);
		_;
	}

	modifier hashExists(bytes32 hash) {
		require(receiptHashes[hash].issuedBy != 0); //Must be an issued receipt
		_;
	}

	function ReceiptSystem() public {
		owner = msg.sender;
	}

	function registerInstitution(bytes32 name, uint8 insType, address addr) public onlyOwner {
		lastID = lastID.add(1);
		idToInstitution[lastID] = Institution(lastID, name, InstitutionType(insType));
		addrToIDs[addr] = lastID;
	}

	//Issuer publish receipt hash
	function issueReceipt(bytes32 hash, bytes16 algo) public onlyInstitution {
		require(receiptHashes[hash].issuedBy == 0); //Cannot re-issue
		receiptHashes[hash] = ReceiptStats(hash, algo, addrToIDs[msg.sender], 
			0, now, true);
	}

	//Issuer invalidate receipt after goods are moved out
	function invalidateReceipt(bytes32 hash) public onlyInstitution { 
		uint256 issuer = receiptHashes[hash].issuedBy;
		require(issuer == addrToIDs[msg.sender]); //Must be by issuer
		receiptHashes[hash].valid = false;
	}

	//Issuer redo invalidation if mistake was made
	function validateReceipt(bytes32 hash) public onlyInstitution {
		uint256 issuer = receiptHashes[hash].issuedBy;
		require(issuer == addrToIDs[msg.sender]); //Must be by issuer
		receiptHashes[hash].valid = true;
	}

	//Bank temporarity claim receipt after granting a loan
	function claimReceipt(bytes32 hash) public onlyBank hashExists(hash) {
		require(receiptHashes[hash].inPossessionBy == 0); //Must not be already claimed by another institution
		require(receiptHashes[hash].valid); //Must still be valid
		receiptHashes[hash].inPossessionBy = addrToIDs[msg.sender];
	}

	//Bank releasing the receipt after loan is repaid
	function declaimReceipt(bytes32 hash) public onlyBank hashExists(hash) {
		require(receiptHashes[hash].inPossessionBy == addrToIDs[msg.sender]); //Must have been claimed by msg.sender
		receiptHashes[hash].inPossessionBy = 0;
	}

	//Bank verify receipt information with hash
	function verifyReceipt(bytes32 hash) public constant 
		returns (bool exists, uint256 issuerID, bytes32 issuerName, uint256 timestamp,
		 bool valid, uint256 inPossessionBy, bytes32 possessorName) 
	{
		ReceiptStats storage r = receiptHashes[hash];
		exists = r.issuedBy != 0 ? true : false;
		issuerID = r.issuedBy;
		issuerName = idToInstitution[issuerID].name;
		timestamp = r.timestamp;
		valid = r.valid;
		inPossessionBy = r.inPossessionBy;
		possessorName = idToInstitution[inPossessionBy].name;
	}

	//Get institution information by id
	function getInstitution(uint256 id) public constant returns(bytes32 name, uint8 insType) {
		Institution storage i = idToInstitution[id]; 
		name = i.name;
		insType = uint8(i.insType);
	}

	//Get institution information by Ethereum address
	function getInstitutionByAddr(address addr) public constant 
	returns(bytes32 name, uint8 insType) {
		return getInstitution(addrToIDs[addr]);
	}
}