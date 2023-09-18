//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
contract lottery{
    address public manager;
    constructor(){
        manager=msg.sender;
    }
    uint256 public ct=0;
    mapping (uint256=>address) public addressMap;
    //address[] public  participants;

    function random(uint256 number)public view returns(uint256){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender))) % number;
    }
    //uint256 x;
    function ContractBalance() public view returns(uint256){
        return address(this).balance;
    }

    function buy(address x)public payable{
        x=msg.sender;
        require(x.balance>=2 ether,"Insufficient ether in account");
        require(msg.value>=2 ether,"Insufficient funds");
        require(msg.value%2==0,"Each token costs 2 ether");
        uint256 n=msg.value/2 ether;
        for(uint256 i=ct;i<ct+n;i++){
            addressMap[i]=x;
        }
        ct+=n;
    }
    uint256 f=0;
    function DeclareWinner() public returns(address){
        require(msg.sender==manager,"Only Manager can Declare Winner");
        require(ct>=3,"Not enough Participants");
        uint256 winNumber=random(ct);
        payable(addressMap[winNumber]).transfer(address(this).balance);
        f=1;
        return(addressMap[winNumber]);
    }
    function resetContract()public{
        require(msg.sender==manager,"only manager can reset contract");
        require(f==1,"a lottery is ongoing and winner is not declared yet");
        f=0;
        for(uint256 i=0;i<ct;i++){
            delete addressMap[i];
        }
        ct=0;
    }
}
//0x5B38Da6a701c568545dCfcB03FcB875f56beddC4->manager
//0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2->89.9
//0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db->97.9
//0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB->97.9