pragma solidity >=0.8.2 <0.9.0;

contract lottery
{
    address public manager;
    address payable[] public participants;
    constructor()
    {
        manager=msg.sender; //global variable
    }
    receive() external payable { //we can use only once receive function in the contract.
        require(msg.value==1 ether); //require is used to check the value,if true
                                    //then next instruction work.
        participants.push(payable (msg.sender));
    }
    function getBalance() public view returns (uint)//
    {
        require(msg.sender==manager);
        return address(this).balance; // this keyword refers to the current object in a method or constructor.
    }
    function random() public view returns(uint)
    {
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,participants.length))); //random function
    } 
    function selectWinner() public
    
    {
        require(msg.sender==manager);
        require(participants.length>=3);
        uint r=random();
        address payable winner;
        uint index =r%participants.length; // here modulo is used to find the winner 
        //which is obviously less than the no. of participants.
        winner=participants[index];
        winner.transfer(getBalance()); // transfer the money to the winner account
        participants=new address payable [](0); // reset the lottery
    }
}
