// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

/**
@title Contract that faciliate the voting of Star Wars Characters
 */
contract StarWarsPoll {
    //Total Number of Characters in the Poll
    uint256 private _totalCharacters;

    // Read/write
    mapping(address => bool) private _addressVoted; //Address and has voted

    //Read/write
    mapping(uint256 => uint256) private _candidates; //Id and vote count

    constructor() public {
        _totalCharacters = 0;
    }

    /**
    @dev Casts a vote for a star wars character based on thier id
    @param _id The id of the Star wars character
     */
    function castVote(uint256 _id) external {
        //Checking that the address has not voted before
        require(!_addressVoted[msg.sender], "This address has already voted");
        //Get the mapping of the id and vote count
        _candidates[_id]++;
        //Setting the address value to voted
        _addressVoted[msg.sender] = true;
    }

    /**
    @dev Checks if the account has already voted
    @return Returns a boolean value based on if the account has already made a vote
     */
    function hasAddressVoted() external view returns (bool) {
        return _addressVoted[msg.sender];
    }

    /**
    @dev Gets vote count of each character
    @return An array with each characters vote count 
     */
    function getAll() external view returns (uint[] memory) {
        require(_totalCharacters != 0,"There are no characters to vote for in the pool");
        uint[] memory ret = new uint[](_totalCharacters);
        for (uint256 i = 0; i < _totalCharacters; i++) {
            ret[i] = _candidates[i];
        }
        return ret;
    }

    /**
    @dev Sets the total number of charactesr in the poll
    @param _numCharacters The number of characters in the poll
     */
    function setTotalCharacters(uint256 _numCharacters) external {
        require(
            _numCharacters != _totalCharacters,
            "The Amount of Characters Is already set at the value entered"
        );

        //Setting the number of characters in the poll
        _totalCharacters = _numCharacters;
    }

    /**
    @dev Gets the total amount of characters in the poll
    @return returns a uint representing the total amount of charcters
     */
    function getTotalCharacters() external view returns (uint256) {
        return _totalCharacters;
    }
}
