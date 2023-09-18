// SPDX-License-Identifier: ISC
pragma solidity ^0.7.4;

import "./Util.sol";

contract Auction {

    using Util for *;

    enum State {
        Progress,
        Fail,
        Success,
        Paid
    }

    event AuctionFinished (
        address addr,
        uint totalCollected,
        bool succeeded
    );

    string public name;  // pode ter diversos leilões
    uint public targetAmount;  // lance alvo
    uint public deadline;  //  prazo final
    address payable public beneficiary; // qualquer pessoa na blockchain possui uma wallet, por isso, address
    address public owner;
    State public state;

    mapping (address => uint) public amounts;
    bool public collected;
    uint public totalCollected;

    modifier inState(State expectedState) {
        require(state == expectedState, "Estado Invalido");
        _;
    }

    constructor (
        string memory contractName,
        uint targetAmountEth, // lembrar de confirmar qual o tipo da moeda da blockchain
        uint durationInMin,
        address payable beneficiaryAddress) 
        
    public {
        name = contractName;
        targetAmount = Util.etherToWei(targetAmountEth);
        deadline = currentTime() + Util.minutesToSeconds(durationInMin);
        beneficiary = beneficiaryAddress;
        owner = msg.sender;
        state = State.Progress;
    }

    function contribute() public payable inState(State.Progress) {
        require(beforeDeadline(), "Nao sao permitidos lances apos o deadline");
        amounts[msg.sender] += msg.value;
        totalCollected += msg.value;

        if (totalCollected >= targetAmount) {
            // atingiu o objetivo
            collected = true;
        }
    }

     function finishAuction() public inState(State.Progress) {
        require(!beforeDeadline(), "Nao e possivel terminar o leilao antes do deadline");

        if (!collected) {
            state = State.Fail;
        } else {
            state = State.Success;
        }

        emit AuctionFinished(address(this), totalCollected, collected);
    }

    function collect() public inState(State.Success) {
        if (beneficiary.send(totalCollected)) {
            state = State.Paid;
        } else {
            state = State.Fail;
        }
    }

    function withdraw() public inState(State.Fail) {
        require(amounts[msg.sender] > 0, "Nenhum lance foi emitido.");
        uint contributed = amounts[msg.sender];
        amounts[msg.sender] = 0;

        if (!msg.sender.send(contributed)) {
            amounts[msg.sender] = contributed;
        }
    }


    function beforeDeadline() public view returns(bool) {
        return currentTime() < deadline;
    }

       function currentTime() virtual internal view returns(uint) {
        return block.timestamp;
    }

    function getTotalCollected() public view returns(uint) {
        return totalCollected;
    }

    function inProgress() public view returns (bool) {
        return state == State.Progress || state == State.Success;
    }

    function isSuccessful() public view returns (bool) {
        return state == State.Paid;
    }

}