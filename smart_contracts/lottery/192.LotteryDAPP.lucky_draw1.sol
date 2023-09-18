pragma solidity >=0.5.0;

import './ownable.sol';
contract LuckyDraw is Ownable {
    //To store ID's of the participants
    uint public id=0;
    // A flag To ensure that the contest has been started by the owner
    uint start=0;
    //Minimum time after which the winner can be decided by the owner
    uint min_time=0;
   //used to create a random number
    uint nounce=0;
    //a mapping from id to address of the participants
    mapping(uint=>address) id_to_owner;
    event joined_contest(uint id,address indexed add);//event
    event winnerAnnounced(address add);//event
    event contestStarted(uint);//event

    //function to join the contest. a number must be passed by the participants

    function join_contest(uint _nounce) external payable{

        //0.1 ether is required to join the contest
        require(msg.value == 0.1 ether,"Must pay 0.1 ether to join the contest");

        //the function works only if contest is started
        require(start == 1,"The contest is not started yet");

        //map an id to address of the participant
        id_to_owner[id] = msg.sender;
        id++;

        //update the nounce
        nounce = nounce+_nounce;

        //emit the event
        emit joined_contest(id,msg.sender);
    }


    function no_of_participants() external view returns(uint) {     //function which returns number of participants
        return (id);
    }


    function draw_the_winner()external onlyOwner{                   //a function which draws the winner

        //this function works only after a minimum time and only if there //atleast one participant
        require(isTime() && id != 0,"No one has joined the contest yet or it's not the time to declare the winner");

        start = 0;

        //creates a random number
        uint  random = uint(keccak256(abi.encodePacked(now,nounce,owner())))%id;
        address ad = id_to_owner[random];
        address payable  winner = address(uint160(ad));

        //transfer the amount to the winner
        winner.transfer(address(this).balance);
        id = 0;
        nounce = 0;
        emit winnerAnnounced(ad);
        start_the_contest();//start the contest again

    }
    function isTime() internal view returns(bool){                  //returns true only if minimum time has been exceeded
        return (min_time <= now);
    }


    function start_the_contest() public {

        //initially the owner must start the contest
        //later on the contest automatically begins once the winner is decided

        require(owner() == msg.sender || msg.sender == address(this),"This function can be called only by the owner or the contract");
        start = 1;

        //a minimum time is given so that the owner does not misuse.
        min_time = now + 2 days;
        emit contestStarted(min_time);
    }
}