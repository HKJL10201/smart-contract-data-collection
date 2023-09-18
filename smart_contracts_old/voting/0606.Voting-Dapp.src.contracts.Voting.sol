pragma solidity ^0.5.1;

contract Voting{
    
    address Owner;
    constructor() public{
        Owner = msg.sender;
    }
    struct prop{
        string name;
        uint votes;
        string profile;
    }
    struct His{
        address user;
        string selected;
    }
    event Eprop(
        string name,
        uint votes,
        string profile
    );
    event EHis(
        address user,
        string selected
    );
    prop[] public arr;
    His[] public History;
    uint256 public total=0;
    uint256 public till = 0;
    mapping(string => uint) index;
    mapping(string => bool) present;
    mapping(address => bool) voted;
    mapping(string => uint) count;
    modifier OnlyOwner{
        require(Owner == msg.sender,"You are not authorised to add candidates");
        _;
    }
    function add(string memory Name,string memory Profile) public OnlyOwner{
        require(present[Name] == false,"Candidate already exist");
        index[Name] = total;
        arr.push(prop(Name,0,Profile));
        total+=1;
        present[Name] = true;
        count[Name] = 0;
        emit Eprop(Name,0,Profile);
    }
    function Vote(string memory Name) public {
        require(voted[msg.sender] == false,"Trying to vote more than ones");
        ++count[Name];
        arr[index[Name]].votes = count[Name];
        voted[msg.sender] = true;
        History.push(His(msg.sender,Name));
        till+=1;
        emit EHis(msg.sender,Name);
    }
}