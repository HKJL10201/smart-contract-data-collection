// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Lottery {
    struct Candidate {
        address addr;
        uint8 slot; 
    }
    mapping(uint256 => Candidate) candidate;
    uint8 currentId;
    uint8 winningNumber;
    address manager;
    bool hasEnded;
    bool canClaim;
    bool isInit;


    /// Amount less than one ether
    error AmountLessThatOneEther();

    /// You are not a manager
    error YouAreNotAManager();

    /// You cannot claim now
    error CannotClaimNow();

    /// Contract cannot be init
    error CannotInit();


    modifier onlyManager {
        if(msg.sender != manager) {
            revert YouAreNotAManager(); 
        }
        _;
    }

    modifier cannotInit {
        if(isInit) {
            revert CannotInit();
        }
        _;
    }


    /// @dev this function is serving as the constructor in this case
    function initialize(address _manager) public cannotInit {
        manager = _manager;
    }

    /// @dev when a user hits this function, they would be added to the lottery
    function cast(uint8 _slot) public payable {
        if(msg.value < 1 ether) {
            revert AmountLessThatOneEther();
        }

        candidate[currentId].addr = msg.sender;
        candidate[currentId].slot = _slot;

        currentId++;
    }

    function revealWinner() public onlyManager {
        uint256 randomNumber = uint256(keccak256(abi.encode(block.timestamp, block.difficulty)));
        winningNumber = uint8(randomNumber % 255);
        canClaim = true;
    }

    function claimLottery() public onlyManager {
        if(!canClaim) {
            revert CannotClaimNow();
        }

        // sending ether to all the lucky winners
        for(uint8 i = 0; i < currentId; i++) {
            if(candidate[i].slot == winningNumber) {
                payable(candidate[i].addr).transfer(10 ether);
            }
        }

        

        hasEnded = true;
    }

    function withdraw() public payable onlyManager {
        if(!hasEnded) {
            revert CannotClaimNow(); // player must be paid before the manager can withdraw the funds from the contract
        }
        payable(manager).transfer(address(this).balance);
    }

    function revealWinnerNumber() public view returns(uint8) {
        return winningNumber;
    }
}