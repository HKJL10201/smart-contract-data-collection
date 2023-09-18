// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Solirey.sol";

contract Escrow {
    Solirey solirey;

    struct EscrowInfo {
        uint value;
        address payable seller;
        address payable buyer;
        // The state variable has a default value of the first member, `State.created`
        State state;
        uint256 tokenId;
    }
    
    enum State { Created, Locked, Inactive }
    mapping (uint => EscrowInfo) public _escrowInfo;

    event CreateEscrow(uint id);
    event PurchaseConfirmed(uint id);
    event ItemReceived(uint id);
    
    modifier inState(State _state, uint id) {
        require(
            _escrowInfo[id].state == _state,
            "Invalid state"
        );
        _;
    }

    constructor(address solireyAddress) {
        solirey = Solirey(solireyAddress);
    }
    
    function createEscrow() external payable {
        solirey.incrementUid();
        uint256 uid = solirey.currentUid();
        
        emit CreateEscrow(uid);

        solirey.incrementToken();

        uint256 newTokenId = solirey.currentToken();
        solirey.mint(msg.sender, newTokenId);
        
        _escrowInfo[uid].value = msg.value / 2;
        require((2 * _escrowInfo[uid].value) == msg.value, "Value has to be even");
        _escrowInfo[uid].seller = payable(msg.sender);
        _escrowInfo[uid].tokenId = newTokenId;
        // Register the original artist
        solirey.updateArtist(newTokenId, msg.sender);
    }
    
    function resell(uint256 tokenId) external payable returns (uint) {
        require(solirey.ownerOf(tokenId) == msg.sender, "Unauthorized");

        solirey.incrementUid();
        uint256 uid = solirey.currentUid();

        emit CreateEscrow(uid);
        
        _escrowInfo[uid].value = msg.value / 2;
        require((2 * _escrowInfo[uid].value) == msg.value, "Value has to be even");
        _escrowInfo[uid].seller = payable(msg.sender);
        _escrowInfo[uid].tokenId = tokenId;

        return uid;
    }
    
    function abort(uint id) external inState(State.Created, id) {
        require(msg.sender == _escrowInfo[id].seller, "Unauthorized");
        
        _escrowInfo[id].state = State.Inactive;
        _escrowInfo[id].seller.transfer(_escrowInfo[id].value * 2);
    }
    
    function confirmPurchase(uint id) external payable inState(State.Created, id) {
        require(msg.value == _escrowInfo[id].value * 2, "Wrong payment amount");
        
        emit PurchaseConfirmed(id);
        _escrowInfo[id].buyer = payable(msg.sender);
        _escrowInfo[id].state = State.Locked;
    }
    
    function confirmReceived(uint id) external inState(State.Locked, id) {
        require(msg.sender == _escrowInfo[id].buyer, "Unauthorized");
        
        emit ItemReceived(id);
        _escrowInfo[id].state = State.Inactive;
        
        uint value = _escrowInfo[id].value;
        uint fee = value * 2 / 100;
        uint payment = value * 3 - (fee * 2);
        
        address artist = solirey._artist(_escrowInfo[id].tokenId);
        payable(artist).transfer(fee);    
        
        solirey.admin().transfer(fee);
        _escrowInfo[id].seller.transfer(payment);
        _escrowInfo[id].buyer.transfer(value);
    }
}