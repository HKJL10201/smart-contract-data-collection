pragma solidity^0.4.18;
//pragma experimental ABIEncoderV2;

import "./CreateVote.sol";

contract Vote is CreateVote{
    
    //set of event
    event SucceedInVote(
        address sender,
        uint32 serial);
    
    event SucceedCheck(
        address sender,
        uint32 serial,
        uint32[20] array,
        string voterToProposalName
        );
    event returnProposal(string proposalstr);
        
    //投票人结构体
    struct Voter{
        address voterAddress;
        bool state;
    }

    //投票人到投票人选择的映射
    //mapping(address => string) voterToProposalName;

    //存储已投过票的地址
    //address[] allVoters;
    
    //add sender's select to struct 
    //function addSelect(uint32, serial)
    
    //verify address
    function verifyAddress(uint32 serial,address thisAddress) internal view returns(bool result){
        uint32 i=0;
        for(i;i<toMyVote[serial].allVoters.length;i++){
            if(toMyVote[serial].allVoters[i]==thisAddress)
                return true;
            if(i==toMyVote[serial].allVoters.length-1){
                return false;
            }
        }
    }
    
    // function vote
    function toVote(uint32 serial, uint32 index, string proposalName) public {
        
        require(serial>0);
        require(toMyVote[serial].state);
        assert(!verifySerial(serial));
        assert(!verifyAddress(serial,msg.sender));
        
        toMyVote[serial].allVoters.push(msg.sender);
        toMyVote[serial].voterToProposalName[msg.sender] = proposalName;
        toMyVote[serial].count[index]++;
        //count[i] = count[i]+1;
        
        emit SucceedInVote(msg.sender,serial);
    }
    
    //get  all proposals by serial
    function getProposals(uint32 serial) public  {
        emit returnProposal(toMyVote[serial].proposalNames);
    }
    
    //check vote
    function checkVote(uint32 serial) public  {
        
        require(serial>0);
        assert(!verifySerial(serial));
        assert(verifyAddress(serial,msg.sender));
        
        emit SucceedCheck(msg.sender,serial,toMyVote[serial].count,toMyVote[serial].voterToProposalName[msg.sender]);
    }
}
    
 
    
   

