contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract uEscrow is owned{
	
    Escrow[] public escrows;
	
	mapping (uint => string) public escrowStatus;
	mapping (uint256 => uint256) public openedEscrowsIndex;
	mapping (uint256 => uint256) public withdrawEscrowsIndex;
	mapping (uint256 => uint256) public refundEscrowsIndex;
	
	uint256[] public openedEscrows;
	uint256[] public withdrawEscrows;
	uint256[] public refundEscrows;
	
	string[5] conditionType = [ "Open", "Withdraw", "Expired", "Executed", "Error" ];
	
	struct Escrow {
		uint  escrowId;
		uint creationTime;
		uint expirationTime;
		EscrowSide[] escrowA;
		EscrowSide[] escrowB;
		uint condition;
		bool closed;
		bytes32 sha3;
	}
	
	struct EscrowSide {
		string assetName;
		string withdrawAddress;
		uint amount;
		string depositAddress;
		string refundAddress;
	}
	
	struct EscrowStatus{
		uint escrowID;
		string status;
	}
        
    enum EscrowCondition { Open, Withdraw, Expired, Executed, Error }
	EscrowCondition conditions;
	
    function uEscrow() {
        owner = msg.sender;
    }
        
    modifier Owner {
        if (msg.sender != owner) throw;
    }

	/* Creates a new escrow */
	function newEscrow(string escrowAAssetName, string escrowAWithdrawAddress, uint escrowAAmount, string escrowADepositAddress, string escrowARefundAddress, string escrowBAssetName, string escrowBWithdrawAddress, uint escrowBAmount, string escrowBDepositAddress, string escrowBRefundAddress, uint expirationTimeInMinutes) onlyOwner returns (uint escrowID){
 
		escrowID = escrows.length++;		
		Escrow e = escrows[escrowID];
		e.creationTime = now;
		e.expirationTime = now + expirationTimeInMinutes * 1 minutes;
		e.escrowA[e.escrowA.length++] = EscrowSide({ assetName: escrowAAssetName, withdrawAddress: escrowAWithdrawAddress, amount: escrowAAmount, depositAddress: escrowADepositAddress, refundAddress: escrowARefundAddress });
		e.escrowA[e.escrowA.length++] = EscrowSide({ assetName: escrowBAssetName, withdrawAddress: escrowBWithdrawAddress, amount: escrowBAmount, depositAddress: escrowBDepositAddress, refundAddress: escrowBRefundAddress });
		e.condition = 0;
		e.closed = false;
		e.sha3 = sha3(escrowAAssetName, escrowAWithdrawAddress, escrowAAmount, escrowADepositAddress, escrowARefundAddress, escrowBAssetName, escrowBWithdrawAddress, escrowBAmount, escrowBDepositAddress, escrowBRefundAddress, expirationTimeInMinutes);
		escrowStatus[escrowID] = conditionType[0];
		uint256 arrayIndex = openedEscrows.length++;
		openedEscrows[arrayIndex] = escrowID;
		openedEscrowsIndex[escrowID] = arrayIndex;
	}
	
	/* Receive, compares balances and change status to withdraw */
	function sendBalances(uint escrowID, uint escrowADepositBalance, uint escrowBDepositBalance) onlyOwner {
		Escrow e = escrows[escrowID];
		if (escrowADepositBalance >= e.escrowA[0].amount && escrowBDepositBalance >= e.escrowA[1].amount){
			e.condition = 1;
			escrowStatus[escrowID] = conditionType[1];
			uint256 arrayIndex = withdrawEscrows.length++;
			withdrawEscrows[arrayIndex] = escrowID;
			withdrawEscrowsIndex[escrowID] = arrayIndex;
			
			delete openedEscrows[openedEscrowsIndex[escrowID]];
			delete openedEscrowsIndex[escrowID];
			
		}
	}
	
	/* Show the expected balance for any escrow */
	function escrowGetExpectedBalances(uint escrowID, uint side) constant returns (uint r){
		return escrows[escrowID].escrowA[side].amount;
	}
	
	/* If withdraw == success, it tags the escrow as executed and close it */
	function sendWithdrawSuccess(uint escrowID) onlyOwner {
		Escrow e = escrows[escrowID];
		e.condition = 3;
		e.closed = true;
		escrowStatus[escrowID] = conditionType[3];
		
		delete withdrawEscrows[withdrawEscrowsIndex[escrowID]];
		delete withdrawEscrowsIndex[escrowID];
	}
	
	/* List active sessions */
	function listOpenedEscrows() constant returns (uint256[] r){
		return openedEscrows;
	}
	
	function listWithdrawEscrows() constant returns (uint256[] r){
		return withdrawEscrows;
	}

	function listRefundEscrows() constant returns (uint256[] r){
		return refundEscrows;
	}
  
    function transferOwnership(address newOwner) onlyOwner{
        owner = newOwner;
    }
	
	function(){
		throw;
	}

}

