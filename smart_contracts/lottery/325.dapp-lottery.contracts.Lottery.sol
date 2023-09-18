// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;


contract Lottery {
    address public manager; /* address datatype is used, because we are sending ether and receiving ehter.. simply
                                dealing with address */
    address payable[] public players; /* "payable" was used because once we find the winner, we need to 
    transfer ether to that address, simple "he needs to be payable"... otherwise how can we send him...*/
    /* we used array "[]" because there can be multiple number of participants... above in manager we didn't use
    any array, because he is just a single person */

    address payable public winner;

    /* now we have to find who is going to deploy this contract... here manager will be deploying contract
    so at the start (using constructor, we will inform/say that authorizty to deploy/controller 
    of this contract will be on "Manager only */
    constructor()// this function will be used for only one time
    {
        manager=msg.sender;
        /* here "msg.sender" is a global variable... the account address "0x583.." of this remix ID will be given
        to manager... we are just making him controller of this lottery ---> to make him controller, 
        we will use "require statement) */
        /* require statment is simply like "if-else statement"... easy way to write if-else */
    }
    /* now we will be receiving ether from participant, so we want to make is as "payable"...also we will be
    receiving ether from "external" participants.. so we use "external" keyword... here "receive()" will run 
    for only one time */
    receive() external payable /* when participant sends ether --> [[how much of ether (i.e, 2 ether) can be set using
    require statement)]]... this function will run */
    {
        require(msg.value==1 ether,"Please pay 1 ether"); /* if this condition is satisfied, the below line will be executed else not..
        meaning: if the user is not paying 1 ether, participant's address will not be sent to array of participants  */
        players.push(payable(msg.sender)); /* this line will push the address of sender(participant) into array
        of participants... "participants" above is dynamic array,,, so we can insert the address/value into it...
        */
    }

    function getBalance() public view returns(uint)
    {
        require(msg.sender==manager,"You are not the manager"); /* if the sender address(current user's address.. when we choose from the list of account) 
        matches that address of manager, he will be able to see the contract balance */
        return address(this).balance; // will give the balance of specific/this "contract"
    }

    /* now we are going to select randomly the participant... for that we are going to create function...inside that
    we are going to use "keccak256" algorithm...
    */
    function random() internal view returns(uint) // this function will give random value
    {
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players.length))); 
        /* this line is just for example... solidity is deterministic... hacker can predict what the random number will be
        if he finds timestamp function or how it works */
    }
    /* now we are going to select the player randomly... if we use % and then anyvalue.... output < that value..eg: % 10...
    output will always be less than 10 i.e 0-9...*/
    function pickWinner() public 
    {
        require(msg.sender==manager,"You are not the manager"); // manager is doing this things
        require(players.length >= 3,"Players are less than 3");
        uint r=random();
       
        uint index = r % players.length; // index value will always be less than players.length..
        winner = players[index];
        winner.transfer(getBalance()); // transfer all the balance to the winner
        /* once the balance has been transfered, we have to reset the participants dynamic array to zero */
        players = new address payable[](0);
    }

    function allPlayers() public view returns(address payable[] memory){
        return players;
    }
}

/* 0x50F9802ce7CF23236ef75f61eea7CB20214204a0 */


/* ganache contract address      0xb774BfaA8895B824eF655f1ccbbF4BAc0BbC53a1 */

/* after this we have to deploy this code to test network.. we are going to test in the Rinkeby Test network .. in the deploy and run
transaction section, from the environment we will be choosing "Injected Web3"...this will automatcally open "Metamask Wallet"...in 
network section of metamask wallet, please select "Rinkeby Test Network" only, don't select main network....what happens
here is in the Account section in deployment, there will be address of the user of metamask wallet...*/

/* Note: participants will be sending ether to "contract address"... not to manager account... what manager can do is: once all the 
ether is transferred to "contract addres", he will be able to see the balance or run "getBalance function"...once it is confirmed that balance 
is obtained or that's it.,, he will run "selectWinner function" */
