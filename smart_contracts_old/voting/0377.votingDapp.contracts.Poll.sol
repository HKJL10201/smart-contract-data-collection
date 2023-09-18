pragma solidity ^0.5.1;
import './Library/Lpoll.sol';


contract Poll {
    using Lpoll for address;
    string private question;
    mapping(string=>uint) pollList;
    //mapping(string=>uint) public options;
    string[] options;
    uint[] votes;
    uint i;
    
    address private store;
    
    constructor (string memory _question, address _store) public
    {
        question = _question;
        store = _store;
        i = 0;
    }
    
    function addOptions(string memory _option) public
    {
        options.push(_option);
        votes.push(0);
        i=i+1;
    }
    
        function numberOfOptions() public view returns(uint){
        return i;
    }

    function getQuestion() view public returns (string memory) 
    {
        return question;
    }
    
    function getOptions(uint ind) view public returns (string memory)
    {
        return (options[ind]);
    }
    
    function getVotes(uint ind) view public returns (uint)
    {
        return (votes[ind]);
    }
    
    function checkParams(string memory voterHash) public view returns (bool,uint)
    {
        return (store.callVoterExist(voterHash),pollList[voterHash] );    
    }
    
    function vote(uint ind, string memory voterHash) public
    {
        require(store.callVoterExist(voterHash));
        require(pollList[voterHash]==0);
        pollList[voterHash]++;
        votes[ind]++;
    }
    
}