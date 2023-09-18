// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


contract Forward{
    //An int value for assigning
    uint globalIndex = 0;
    //Blocked money
    uint blockedBal = 0;
    //When someone issued a contract
    event Issued(
        uint indexed id,
        address issuer,
        string product,
        uint dueDate,
        uint amount
    );
    //
    event Offered(uint indexed id, address marginSigner,uint price, uint margin);
    event ContractSigned(uint indexed id, address signer);
    event MarginCallDone(uint indexed mc_id);
    //event Conflict(uint id, address indexed user, uint amount);

    //Definiton for a futures contract
    struct Contract{
        string product;
        address payable issuer;
        address payable signer;
        uint price;
        uint amount;
        uint dueDate;
        uint marginIssuer;
        uint marginSigner;
        uint index;
	    Offer[] offers;
    }
    struct Offer{
	uint margin;
	uint price;
	address payable offering;
	uint index;
        
    }
    struct MarginCall{
	bool marginSigner;	
	bool marginIssuer;
	address payable owner;
    }    
    mapping (uint=>Contract) public contracts;
    mapping (uint=>MarginCall) marginCall;
    modifier onlyIssuer(uint contrID) {
        require(msg.sender==contracts[contrID].issuer,"Unauthorized");
        _;
    }


    //Launching the event with three parameters (using time() function here)
    function createContract(
        string calldata _product,
        uint _dueDate
    ) payable external returns (uint index) {
        require(_dueDate>block.timestamp+86400,"At least one day");
        blockedBal += msg.value;
        emit Issued(globalIndex,msg.sender,_product,_dueDate,msg.value);
        globalIndex++;
        return globalIndex;
        }

    function giveOffer(uint contractID, uint _price) payable external{
	contracts[contractID].offers.push(Offer(msg.value,_price,payable(address(msg.sender)),globalIndex));
	blockedBal += msg.value;
	emit Offered(globalIndex++,msg.sender,_price,msg.value);
	}
	
    function acceptOffer(uint offID, uint contractID) external onlyIssuer(contractID)  {
	contracts[contractID].marginSigner = contracts[contractID].offers[offID].margin;
	contracts[contractID].signer = contracts[contractID].offers[offID].offering;
	marginCall[contractID] = MarginCall(false,false,payable(address(0)));
	}


    function margincallRequestorAccept(uint contractID) external {
	if(msg.sender == contracts[contractID].issuer &&marginCall[contractID].owner==payable(address(0))) {
		marginCall[contractID].owner = contracts[contractID].signer;
        marginCall[contractID].marginSigner = true;
         }
	if(msg.sender == contracts[contractID].signer &&marginCall[contractID].owner==payable(address(0))) {
		marginCall[contractID].owner = contracts[contractID].issuer;
        marginCall[contractID].marginIssuer = true;
        }
    }
   function margin_Call(uint contractID) external payable {
    require(marginCall[contractID].marginIssuer == true && marginCall[contractID].marginSigner == true, "Not accepted");
        marginCall[contractID].owner.transfer(contracts[contractID].marginIssuer+contracts[contractID].marginSigner);
        emit MarginCallDone(contractID);
}


    //function conflict()







    

}