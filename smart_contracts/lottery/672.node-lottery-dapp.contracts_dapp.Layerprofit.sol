pragma solidity ^0.4.22;

contract layerprofit {
    function allocateProfit(uint balance,address player, uint type1) internal returns (uint){

        // uint maxAmountAllowedInTheBank = 200000000000000000;  /* 0.2 ether */
        // if( type1 == 1) {
        //     maxAmountAllowedInTheBank = 100000000000000000;
        // }
        // uint amount = balance - maxAmountAllowedInTheBank;
         // uint amount = address(this).balance - maxAmountAllowedInTheBank;

        // if (amount > 0) player.transfer(amount);

        if ( type1 == 1 && balance == 12) player.transfer(0.12 ether);
        if ( type1 == 1 && balance == 11) player.transfer(0.11 ether);

    }
}