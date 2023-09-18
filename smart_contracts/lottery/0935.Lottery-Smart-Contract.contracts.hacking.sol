//SPDX-License-Identifier: MIT
// To overcome this challenge, append your name to the array of champions.

pragma solidity ^0.8.17; 

contract Pwn{
    mapping(address => uint256) private contributionAmount;    
    mapping(address => bool) private pwned;
    address public owner;
    uint256 private constant MAXIMUM_CONTRIBUTION = (1 ether)/5;
    address[] public champions;
    mapping(address => string) public  Names;
   
    
    constructor(){
        owner = msg.sender;
    }

    function isContract(address account) internal view returns(bool){
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }    

    function pwnMe(string memory _name) external payable{
       
        require(tx.origin != msg.sender, "Well we are not allowing EOAs, sorry");
        require(!isContract(msg.sender), "Well we don't allow Contracts either");
        require(msg.value <= MAXIMUM_CONTRIBUTION, "How did you get so much money? Max allowed is 0.2 ether");
        contributionAmount[msg.sender] += msg.value;
        string memory name_ = Names[tx.origin];
        require(keccak256(abi.encode(name_)) == keccak256(abi.encode("")), "Not a unique winner");
        Names[tx.origin] = _name;
        pwned[tx.origin] = true;
        if(champions.length < 5){
        champions.push(tx.origin);
        }
    }
    
    function verify(address account) external view returns(bool){
     require(account != address(0), "You trynna trick me?");
     return pwned[account];
    }
    
    function retrieveAndStop() external{
        require(msg.sender == owner, "Are you the owner?");
        require(address(this).balance > 0, "No balance");

        payable(owner).transfer(address(this).balance);
        
    }

    function getAllwiners() external view returns (string[] memory _names){
            _names = new string[](champions.length); 
            for(uint i; i < champions.length; i++){
                _names[i] = Names[champions[i]];
            }
     }


     receive() external payable{}

     

    
}