pragma solidity ^0.4.15;

/*
    Copyright 2017, Konstantin Viktorov (XRED Foundation)
    Copyright 2017, Jorge Izquierdo (Aragon Foundation)
    Copyright 2017, Jordi Baylina (Giveth)

    Based on MiniMeToken.sol from https://github.com/Giveth/minime
*/

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data);
}
