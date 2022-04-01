pragma solidity ^0.4.11;

contract Voting {


    uint bjp;
    uint cong;
    uint aap;


    // count individual votes of each state
    mapping (string => states_vote ) statesVotes;

    // main voting count
    mapping (string => uint) overallVotes;

    //set adhaar_no to voted
    mapping (address => bool) voted;


    //count of votes in each party
    struct states_vote{
        uint bjp;
        uint cong;
        uint aap;
    }

    uint dummyCreated;

    function compareStrings (string a, string b) view returns (bool){
        return keccak256(a) == keccak256(b);
    }

    modifier isValidVoter(address account){
        require(!voted[account]);
        _;
    }


    function vote(address account,string party,string state) public isValidVoter(account){
        overallVotes[party]+=1;
        var sv= statesVotes[state];

        //checkes the vote is for which party
        if (compareStrings(party,"bjp")){
            sv.bjp+=1;
            bjp+=1;

        }else if(compareStrings(party,"cong")){
            sv.cong+=1;
            cong+=1;

        }else{
            sv.aap+=1;
            aap+=1;
        }


        //mark as voted
        voted[account]=true;
    }


    function getStateResult(string state) view public returns(uint,uint,uint){
        var s = statesVotes[state];
        return (s.bjp,s.cong,s.aap);

    }

    function result() view public returns(uint,uint,uint){
        return (bjp,cong,aap);
    }

    function getTotalVotes() view public returns(uint){
        return (bjp+cong+aap);
    }

    function challenge(address account,bool _voted) view public returns(bool){
        return voted[account]==_voted;
    }

    function dummyData(string party,string state,uint number) public{
        if(dummyCreated<28*3){
            overallVotes[party]+=number;
            var sv= statesVotes[state];

            //checkes the vote is for which party
            if (compareStrings(party,"bjp")){
                sv.bjp+=number;
                bjp+=number;

            }else if(compareStrings(party,"cong")){
                sv.cong+=number;
                cong+=number;
            }else{
                sv.aap+=number;
                aap+=number;
            }
            dummyCreated+=1;
        }
    }


}