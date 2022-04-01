pragma solidity ^0.4.18;

import './StandartToken.sol';

contract NaughtCoin is StandardToken {

    string public constant name = 'NaughtCoin';
    string public constant symbol = 'NTC';
    uint public constant decimals = 18;
    uint public INITIAL_SUPPLY = 1000000 * (10 ** decimals);
    address public player;

    function NaughtCoin(address _player) public {
        player = _player;
        totalSupply_ = INITIAL_SUPPLY;
        balances[player] = INITIAL_SUPPLY;
        Transfer(0x0, player, INITIAL_SUPPLY);
    }
}
