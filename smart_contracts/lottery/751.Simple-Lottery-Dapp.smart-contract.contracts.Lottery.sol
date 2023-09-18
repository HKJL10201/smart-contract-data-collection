// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Lottery {
    address private owner;
    uint private min_amount_to_donate;
    mapping(address => uint) moneyDonated;
    address[] public contestents;
    
    event DonationSuccessful(address _from, uint _amount, string msg);
    event WinnerDeclaration(address _winner, uint _amount, string msg);

    constructor(uint _min_amount_to_donate) {
        owner = msg.sender;
        min_amount_to_donate = _min_amount_to_donate;
    }

    function getOwner() public view returns(address) {
        return owner;
    }

    function minAmount() public view returns(uint) {
        return min_amount_to_donate;
    }

    function setMinAmount(uint _amount) public onlyOwner {
        min_amount_to_donate = _amount;
    }

    function donate(address _from, uint _amount) public payable donationSpec {
        if(moneyDonated[_from] == 0) {
            contestents.push(_from);
        }
        moneyDonated[_from] += _amount;
        emit DonationSuccessful(_from, _amount, "ETH successfully donated !!");
    }

    function contractBalance() public view returns(uint) {
        return address(this).balance;
    }

    function declareWinner(uint _random) public onlyOwner {
        uint randInt = contestents.length % _random;
        randInt = randInt == contestents.length ? --randInt : randInt;
        uint _amount = contractBalance();
        payable(contestents[randInt]).transfer(_amount);
        emit WinnerDeclaration(contestents[randInt],_amount, "Winner Announced !!");  
    }

    function getDonatedAmount(address _address) public view returns(uint) {
        return moneyDonated[_address];
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner required !!");
        _;
    }

    modifier donationSpec() {
        require(msg.value >= min_amount_to_donate, "Donation amount should be greater than threshold amount !!");
        _;
    }

    receive() external payable {
        donate(msg.sender, msg.value);
    }

}