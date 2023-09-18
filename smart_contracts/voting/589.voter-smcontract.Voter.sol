// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


contract Voter {

    uint[] private _votes;
    string[] private  _options;
    mapping(address => bool) public hasVoted;

    struct Options {
        uint postion;
        bool exsists;
    }
    mapping(string => Options) public _optionsPostions;
 
 

    function setOptions (string[] memory options) public  {
         _options = options;
        _votes = new uint[](options.length);
        for(uint index = 0; index < options.length; index++){
            string memory postionName = options[index];
            
            _optionsPostions[postionName] = Options(index, true);
        }
    }

    function vote(uint option) public {
        require(!hasVoted[msg.sender], "Account has already voted");
        require(0 <= option && option < _options.length, "Invalid option");
        _votes[option]+=1;
        hasVoted[msg.sender] = true;
    }

    function vote(string memory option) public {
        require(!hasVoted[msg.sender], "Account has already voted");
        
        Options memory optionPostion =  _optionsPostions[option];
        
        require(!optionPostion.exsists,"Invalid option" );

        _votes[optionPostion.postion]+=1;
         hasVoted[msg.sender] = true;
    }

    function getOptions() public view returns (string[] memory){
        return _options;
    }

    function getVotes() public view returns (uint[] memory) {
        return _votes;
    }

    
}