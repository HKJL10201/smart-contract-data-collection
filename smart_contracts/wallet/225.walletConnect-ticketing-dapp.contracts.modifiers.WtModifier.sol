pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";


contract WtModifier is Ownable {

    modifier isIssuedTicket(uint256 _ticketId) {
        //require (now >= _time);
        _;
    }
    
}
