// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Fomo3D {
    enum State {
        INACTIVE,
        ACTIVE
    }
    State currentState = State.INACTIVE;
    address payable public king;
    uint public start;
    uint public end;
    uint public hardEnd;
    uint public pot;
    uint public houseFee = 2;
    uint public initialKeyPrice;
    uint public totalKeys;
    address payable[] public keyHolders;
    mapping(address => uint) keys;
    
    function kickStart() 
        external 
        inState(State.INACTIVE) {
        currentState = State.ACTIVE;
        _createRound();
    }
    
    function bet() 
        external 
        payable 
        inState(State.ACTIVE) {
        if(block.timestamp > end || block.timestamp > hardEnd) {
            msg.sender.transfer(msg.value);
            _distribute();
            _createRound();
            return;
        }
        
        //Keys
        uint keyCount = msg.value / getKeyPrice();
        keys[msg.sender] += keyCount;
        totalKeys += keyCount;
        bool alreadyAdded = false;
        for(uint i = 0; i < keyHolders.length; i++) {
            if(keyHolders[i] == msg.sender) {
                alreadyAdded = true;
            }
        }
        if(alreadyAdded == false) {
            keyHolders.push(msg.sender);
        }
        
        //Other
        pot += msg.value;
        end = end + 30 > hardEnd ? hardEnd : end + 30;
        king = msg.sender;
    }
    
    function getKeyPrice() view public returns(uint) {
        uint periodCount = (block.timestamp - start) / 30;
        return initialKeyPrice + periodCount * 0.01 ether;
    }
    
    function _distribute() internal {
        uint netPot = (pot * (100 - houseFee)) / 100;
        uint percent = (netPot * 50) / 100; 
        king.transfer(percent);
        for(uint i = 0; i < keyHolders.length; i++) {
            address payable keyHolder = keyHolders[i];
            if(keyHolder != king) {
                keyHolder.transfer((keys[keyHolder] * percent) / totalKeys);
            }
        }
    }
        
    function _createRound() internal  {
        for(uint i = 0; i < keyHolders.length; i++) {
            delete keys[keyHolders[i]];
        }
        delete keyHolders;
        totalKeys = 0;
        start = block.timestamp;
        end = block.timestamp + 30;
        hardEnd = block.timestamp + 86400;
        initialKeyPrice = 1 ether;
    }
    
    modifier inState(State state) {
        require(currentState == state, 'not possible in current state');
        _;
    }
    
}