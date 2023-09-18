pragma solidity 0.6.0;
pragma experimental ABIEncoderV2;

contract Wallet{
    address[] public approvers;
    uint public quorum;
    struct Transfer {
        uint id;
        uint amount;
        // if we do not define address as payable then solodit will not allow to send ether
        address payable to;
        uint approvals;
        bool sent;
    }


    
    //Here we are taking an array to keep the transfers data
    Transfer[] public transfers;
    //mapping to record who has approved what 
    mapping(address => mapping(uint=> bool)) public approvals;



    constructor(address[] memory _approvers, uint _quorum) public {
        approvers = _approvers;
        quorum = _quorum;
    }

    function getApprovers() external view returns (address [] memory){
        return approvers;
    }

    function getTransfers() external view returns (Transfer [] memory){
        return transfers;
    }


    //attaching the onyApprover modifier here to make sure that only approvers can do it 
    function createTransfer(uint amount, address payable to) external onlyApprover{
        transfers.push(Transfer(
        transfers.length,
        amount,
        to,
        0,
        false
        ));
    }

    //attaching the onyApprover modifier here to make sure that only approvers can do it 
    function approveTransfer(uint id) external onlyApprover{
        //to make sure that it is not a transfer that has already been sent
        require (transfers[id].sent == false,'transfer has already been sent');
        //check that the sender of the transaction has not already approved the transfer
        // because you cannot approve a transfer twice
        require (approvals[msg.sender][id] == false, 'cannot approve transfer twice');

        //now we set the approvals to true so that you cannot call the same transfer to be approved again
        approvals[msg.sender][id] == true;
        transfers[id].approvals++;

        //checking if the quorum is reached for the transaction can happen
        if(transfers[id].approvals > quorum){
            transfers[id].sent == true;
            address payable to = transfers[id].to;
            uint amount = transfers[id].amount;
            // the tranfer method is one given by solidity itself
            to.transfer(amount);
        }

    }

    receive() external payable {}

    //we do not want anybody to be able to create and approve transaction
    //we only want the certain addresses in the approvers array to be able to do these,
    // so we need access control,
    // we do this by giving custom modofiers
    modifier onlyApprover(){
        bool allowed = false;
        for(uint i = 0; i < approvers.length; i++){
            if (approvers[i] == msg.sender){
                allowed = true;
            }
        }

        require(allowed = true, 'only apprver allowed');
        _;





    }

}
