pragma solidity ^0.4.24;

import "./Debuggable.sol";
import "./OpenZeppelin/Ownable.sol";

contract HackathonVoting is Ownable, Debuggable {
  event Voted(
    address indexed _voter,
    uint indexed _teamId,
    uint8 _technical,
    uint8 _creativity,
    uint8 _usefulness,
    uint8 _general
  );

  event TeamCreated(
    uint teamId,
    address submitter,
    string name,
    string github
  );

  struct Team {
    address submitter;
    string name;
    string github;

    uint8 technical;
    uint8 creativity;
    uint8 usefulness;
    uint8 general;

    uint8 totalPoints;

    mapping (address => bool) voters;
  }

  Team[] public teams;
  mapping (address => uint) public submitterToTeamId;

  uint8 constant TECHNICAL_WEIGHTING = 3;
  uint8 constant CREATIVITY_WEIGHTING = 3;
  uint8 constant USEFULNESS_WEIGHTING = 1;
  uint8 constant GENERAL_WEIGHTING = 3;
  uint8 constant MAX_POINTS_PER_CATEGORY = 10;

  constructor() public {
    // team 0 is blank
    _createTeam("", "", address(0));
  }

  function totalTeams() public view returns (uint) {
    return teams.length - 1;
  }

  function submitTeam(string _name, string _github) public returns (uint) {
    // XXX allowing multiple submissions from a single address as demoing was annoying otherwise :(

    // each address may only submit one team
    // require(submitterToTeamId[msg.sender] == 0, "You have already submitted a team");

    address submitter = msg.sender;
    uint teamId = _createTeam(_name, _github, submitter);

    emit TeamCreated(teamId, submitter, _name, _github);

    return teamId;
  }

  function _createTeam(string _name, string _github, address _submitter) private returns (uint) {
    Team memory team = Team({
      name: _name,
      github: _github,
      submitter: _submitter,
      technical: 0,
      creativity: 0,
      usefulness: 0,
      general: 0,
      totalPoints: 0
    });

    uint teamId = teams.push(team) - 1;

    submitterToTeamId[msg.sender] = teamId;

    return teamId;
  }

  function vote(
    uint _teamId,
    uint8 _technical,
    uint8 _creativity,
    uint8 _usefulness,
    uint8 _general
  ) public {
    Team storage team = teams[_teamId];

    require(!team.voters[msg.sender], "This address has already voted for this team");
    require(
      _technical <= MAX_POINTS_PER_CATEGORY &&
      _creativity <= MAX_POINTS_PER_CATEGORY &&
      _usefulness <= MAX_POINTS_PER_CATEGORY &&
      _general <= MAX_POINTS_PER_CATEGORY
    , "You cannot award this number of points");

    team.voters[msg.sender] = true;

    team.technical = team.technical + _technical;
    team.creativity = team.creativity + _creativity;
    team.usefulness = team.usefulness + _usefulness;
    team.general = team.general + _general;

    team.totalPoints = calculatePointsFromStats(
      team.technical,
      team.creativity,
      team.usefulness,
      team.general
    );

    emit Voted(msg.sender, _teamId, _technical, _creativity, _usefulness, _general);
  }

  function calculatePointsFromStats(
    uint8 _technical,
    uint8 _creativity,
    uint8 _usefulness,
    uint8 _general
  ) private pure returns (uint8) {
    return (_technical * TECHNICAL_WEIGHTING) +
      (_creativity * CREATIVITY_WEIGHTING) +
      (_usefulness * USEFULNESS_WEIGHTING) +
      (_general * GENERAL_WEIGHTING);
  }

  function calculatePoints(uint _teamId) public view returns (uint points) {
    Team memory team = teams[_teamId];

    return calculatePointsFromStats(
      team.technical,
      team.creativity,
      team.usefulness,
      team.general
    );
  }

  // TODO handle ties
  function determineWinner() public view returns (uint) {
    uint winningTeamId = 0;
    uint winningTeamPoints = 0;

    for (uint i = 1; i < teams.length; i++) {
      Team memory team = teams[i];
      
      if (team.totalPoints > winningTeamPoints) {
        winningTeamId = i;
        winningTeamPoints = team.totalPoints;
      }
    }

    return winningTeamId;
  }

  function getTeam(uint _teamId) public view returns (
    address submitter,
    string name,
    string github,
    uint8 technical,
    uint8 creativity,
    uint8 usefulness,
    uint8 general,
    uint8 totalPoints
  ) {
    Team memory team = teams[_teamId];

    submitter = team.submitter;
    name = team.name;
    github = team.github;
    technical = team.technical;
    creativity = team.creativity;
    usefulness = team.usefulness;
    general = team.general;
    totalPoints = team.totalPoints;
  }
}