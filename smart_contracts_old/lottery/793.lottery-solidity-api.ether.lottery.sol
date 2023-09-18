// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract Lottery {
    
    mapping(address => uint256[]) _voteNumber;
    mapping(address => mapping(uint256 => uint256)) _checkJackpot;
    mapping(address => uint256) _balances;
    mapping(uint256 => uint256) _countVote;
    
    uint256 _total;
    uint256 _jackpot;
    
    bool canVote;
    bool canRedeem;
    bool canSetJackpot;
    
    address owner;
    
    ERC20 erc20;
    
    constructor (address erc20Address) {
        erc20 = ERC20(erc20Address);
        owner = msg.sender;
        canVote = true;
        canSetJackpot = true;
    }
    
    function voteTo(uint256 number) public {
        require(canVote, "Vote is closed");

        _voteNumber[msg.sender].push(number);
        _countVote[number]++;
        _checkJackpot[msg.sender][number]++;
        
        erc20.transferFrom(msg.sender, address(this), 100);
        _total += 100;
    }
    
    function setJackpot(uint256 number) public {
        require(msg.sender == owner, "You're not authorized");
        require(canSetJackpot, "Jackpot has already set");
        
        _jackpot = number;
        canRedeem = true;
        canVote = false;
        canSetJackpot = false;
    }
    
    function checkVoteByAddress() public view returns(address, uint256[] memory) {
        return (msg.sender, _voteNumber[msg.sender]);
    }
    
    function countVoteNumber(uint256 number) public view returns(uint256) {
        return _countVote[number];
    }
    
    function redeemReward() public {
        require(canRedeem, "Jackpot's not set");
        require(_checkJackpot[msg.sender][_jackpot] != 0, "You're loser");
        
        uint256 prize = _total/_countVote[_jackpot];
        erc20.transferFrom(address(this), msg.sender, prize);
        _total -= prize;
    }
    
    function balanceOf() public view returns(uint256) {
        return erc20.balanceOf(msg.sender);
    }
    
    function checkTotal() public view returns(uint256) {
        return _total;
    }
}

abstract contract ERC20 {
    function balanceOf(address account) public virtual view returns(uint256);
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns(bool);
}