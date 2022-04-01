pragma solidity ^0.4.18;
//pragma experimental ABIEncoderV2;

contract CreateVote{
    
    event SucceedSetVote(
        address sender,
        uint32 serial,
        string theme);
    /*ºòÑ¡Ïî
    struct Proposal{
        string proposalName;
        uint32 count;
    }*/
    
    //±¾´ÎÍ¶Æ±
    struct MyVote{
        address proposer;
        string theme;
        string proposalNames;
        //Proposal[] proposals;
        uint startTime;
        uint32 endTime;
        bool state;
        uint32[20] count;
        mapping(address => string) voterToProposalName;
        address[] allVoters;
    }
    
    
    //±àºÅ´æ´¢
    uint32[] serials;
    
    //±àºÅµ½Í¶Æ±µÄÓ³Éä
    mapping (uint32 => MyVote) toMyVote;
    
    //´´½¨ÈËµØÖ·µ½±àºÅµÄÓ³Éä
    mapping(address => uint32) toMySerial;
    
    //ÑéÖ¤ÐòÁÐºÅ
    function verifySerial(uint32 serial) internal view returns (bool result){
        uint32 i=0;
        for(i;i<serials.length;i++){
            if (serial == serials[i]){
                return false;
            }
        }
        return true;
    }
    
    //create vote
    function setVote(uint32 serial, uint32 endTime, string theme , string proposalNames) public returns (string result){
        
        require(serial>0 && endTime>0);
        assert(verifySerial(serial));
        
        toMyVote[serial].proposer = msg.sender;
        toMyVote[serial].endTime = endTime;
        toMyVote[serial].theme = theme;
        toMyVote[serial].proposalNames = proposalNames;
        toMyVote[serial].startTime = block.timestamp;
        toMyVote[serial].state = true;
        
        toMySerial[msg.sender] = serial;
        serials.push(serial);
        emit SucceedSetVote(msg.sender,serial,theme);
        return "success!";
    }
    
     //¹Ø±ÕÍ¶Æ±
    function endVote(uint32 serial) public {
        //assert(toMyVote[serial].proposer == msg.sender);
        assert(!verifySerial(serial));
        toMyVote[serial].state = false;
    }
}
