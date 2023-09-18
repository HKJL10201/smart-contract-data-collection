// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.22 <0.9.0;


contract TokenVoting {
    
    address admin;
    
    struct Voter {
        uint ballots;
        uint[] votedList;
    }
    struct Proposal {
        string name;
        uint ballots;
    }
    Proposal[]  _proposalList;
    
    uint _ballotPrice;
    
    mapping(address=>Voter)  _voters;
    
    mapping(address=>uint[]) public voterVoteList;
    
    event Left(uint);
    
    
    constructor(string[] memory proposalList, uint ballotPrice) {
        for (uint i = 0;i<proposalList.length;i++){
            _proposalList.push(Proposal({
                name: proposalList[i],
                ballots: 0
            }));
        }
        _ballotPrice = ballotPrice;
    }
    
    function buy()public payable{
        uint value = msg.value;
        uint ballots = value / _ballotPrice;
        uint left = value % _ballotPrice;
        address payable sender = payable(msg.sender);
        _voters[sender].ballots += ballots;
        emit Left(left);
        sender.transfer(left);

    }
    
    function vote(uint proposal, uint ballots)public payable{
        address sender = msg.sender;
        require(_voters[sender].ballots >= ballots, "ballots not enough");
        require(_proposalList[proposal].ballots + ballots > _proposalList[proposal].ballots, "overflow");
        _proposalList[proposal].ballots += ballots;
        _voters[sender].ballots -= ballots;
        if (_voters[sender].votedList.length < _proposalList.length) {
            for (uint i = 0;i < _proposalList.length;i++){
                _voters[sender].votedList.push(0);
            }
        }
        _voters[sender].votedList[proposal] += ballots;
        // voterVoteList[sender][proposal] += ballots;
        
    }
    // function getProposalList()public view returns(string[] memory, uint[] memory) {
    //     string[] memory nameList = new string[](_proposalList.length);
    //     uint[] memory ballotsList = new uint[](_proposalList.length);
    //     for (uint i = 0;i<_proposalList.length;i++){
    //         nameList[i] = _proposalList[i].name;
    //         ballotsList[i] = _proposalList[i].ballots;
    //     }
    //     return (nameList,ballotsList);
    // }
    
    

    
    function proposalList()public view returns(Proposal[] memory){
        return _proposalList;
    }
    function getVoter() public view returns(Voter memory){
        return _voters[msg.sender];
    }
        
    
    receive()external payable{}
}