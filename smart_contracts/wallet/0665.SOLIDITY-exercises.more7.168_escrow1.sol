// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Escrow {

    address payable public buyer;
    address payable public seller;
    address payable public arbitrator;

    uint public amount;
    bool public buyerOk;
    bool public sellerOk;

    enum State {Created, Locked, Released, Inactive}
    State public state;

    constructor(
        address payable _buyer,
        address payable _seller,
        address payable _arbitrator,
        uint _amount
    ) {
        arbitrator = _arbitrator;
        buyer = _buyer;
        seller = _seller;
        amount = _amount;
    }

    function acceptBuyer() public {
        require(msg.sender == buyer);
        require(state == State.Created);
        buyerOk = true;
        if(sellerOk == true) {
            state = State.Locked;
        }
    }

    function acceptSeller() public {
        require(msg.sender == seller);
        require(state == State.Created);
        sellerOk = true;
        if(buyerOk == true) {
            state = State.Locked;
        }
    }

    function abort(uint fee) public {
        require(msg.sender == arbitrator);
        require(state == State.Created);
        state = State.Inactive;
        payable(arbitrator).transfer(fee);
        //To prevent scammers from exploiting system, a certain
        //amount will be sent to the owner, when tx is cancelled
        payable(buyer).transfer(address(this).balance - fee);
    }

    uint public feePercentage = 1;

    function changeFeePercentage(uint _newFee) public {
        require(msg.sender == arbitrator);
        require(_newFee <= 10 );
        feePercentage = _newFee;
    }

    function release() public {
        require(msg.sender == arbitrator);
        require(state == State.Locked);
        state = State.Released;
        uint releaseFee = (address(this).balance * feePercentage) / 100;
        uint amountToSeller = address(this).balance - releaseFee;
        payable(seller).transfer(amountToSeller);
    }

    function refund() public {
        require(msg.sender == arbitrator);
        state = State.Inactive;
        payable(buyer).transfer(address(this).balance);
    }

    function withdraw(uint _amount) public {
        require(msg.sender == arbitrator);
        payable(arbitrator).transfer(_amount);
    }
}