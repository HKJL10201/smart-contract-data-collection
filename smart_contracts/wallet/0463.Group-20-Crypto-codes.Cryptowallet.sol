//SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.6.2 <0.9.0;

contract crypto_wallet
{
       int bal;
         constructor()
       {
           bal=0;
       }
        //getbalance
       function getbalance() view public returns(int)
       {
           return bal;
       }
       //deposit
       function deposit(int amt)public {
           bal +=amt;
       }
       //withdraw
       function withdraw(int amt)public{
              bal -=amt;
       }}


