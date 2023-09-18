pragma solidity ^0.5.0;

/*
  *  web3.eth.getAccounts().then(function(acc) { account = acc; }) - this gets all the accounts
  *  Allows you to call account[0] for first accounts
  *  app.pick(1, {from: account[0]}) - will cast pick to team 1 from account 0
*/

contract Wager {
    // Model team

    /*
    * Can't access this vars using id, name, pickCount
    * Must us position in function
    * ex team[1] will return id
    * team[0].toNumber will return int
    */
    struct Team {
      uint id;
      string name;
      uint pickCount;
    }
    // Store users who have placed wager
    mapping(address => bool) public players;

    // Store team
    // Fetch Team
    /*
    * Keeps list of teams
    */
    mapping(uint => Team) public teams;
    // Store team count
    // Fetches all possible teams from mapping
    uint public teamsCount;

    //pick event
    event pickEvent (
      uint indexed _teamID
    );

    // Constructor
    constructor() public {
      // Want to add teams based on ML algo
      addTeam("Seahawks");
      addTeam("Patriots");
    }

    // private means no one but the contract can addTeam
    function addTeam (string memory _name) private {
        teamsCount ++;
        teams[teamsCount] = Team(teamsCount, _name, 0);
    }

    // Sol allows metadata to also be passed to function
    function pick (uint _teamID) public{
      // Check valid team
      require(_teamID > 0 && _teamID <= teamsCount);

      //Record that player has placed a pick
      players[msg.sender] = true;  // Ref players mapping and setting val to True

      //Update team pick count
      teams[_teamID].pickCount ++; //Ref teams mapping and inc count
      emit pickEvent(_teamID);
    }
}
