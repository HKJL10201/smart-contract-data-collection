// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Voting {

 //This is a smart contract where you going to vote for movies

    uint256 public constant _maxVotePerVoter = 4;
    uint256 public moviesCount;

  struct Movie {
    uint256 id;
    string title;
    string cover;
    uint256 votes;
  }

   mapping(uint256 => Movie) public movies;
  
   mapping(address => uint256) public votes;

   event Voted ();
   event NewMovie ();


  constructor() {
      _moviesCount = 0;
  }

    function vote(uint256 _movieID) public {
     require(votes[msg.sender] < _maxVotePerVoter, "Voter has no votes left. Sorry!");
     require(_movieID > 0 && _movieID <= _moviesCount, "Movie ID is out of range.");

     votes[msg.sender]++;
     movies[_movieID].votes++;

     emit Voted();
   }

   //this where you will add movie of your choice with the Movie title and cover
    function addMovie(string memory _title, string memory _cover) public {
      _moviesCount++;

      Movie memory movie = Movie(_moviesCount, _title, _cover, 0);
      movies[_moviesCount] = movie;

      emit NewMovie();
      vote(_moviesCount);
  }
}