//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/utils/Counters.sol";

contract VotingOrganizer {

    //struct of contenstants
    struct Contestant {
        string election_name;
        address creator;
        uint256 if_registered;
        uint256 number_of_votes;
        string contestant_name;
        string contestant_image;
        address address_contestant;

    }

    //voter struct
    struct Voting {
        uint if_voted;
    }

    using Counters for Counters.Counter;
    Counters.Counter private contestant_num;
 

    mapping(address=>Contestant) private contestants;//mapping address to Contestant struct
    mapping(string => mapping(address => Voting)) private name_of_election_to_voter;//mapping voter to name of election voted
    mapping(string => mapping(address => Contestant)) private name_of_election_to_contestants;//mapping name of election to contestants

    //array of addresses of contestants
    address[] private addresses;
    //array of election names
    string[] private election_names;

    event Created_Contestant(
        address indexed _address_contestant,
        string _contestant_name,
        string _contestant_image,
        string _election_name
    );

    event Voted(address _address_contestant, address _voter, uint256 number_of_votes);


    /**
    * @dev creates a contestants for an election
    * @param _election_name name of the election the contestant will be added to
    * @param _contestant_name name of the contestant
    * @param _address_contestant address of the contestant
    * @param _contestant_image image url of the contestant
    */
    function createContestant(
        string calldata _election_name,
        string calldata _contestant_name,
        address _address_contestant,
        string calldata _contestant_image
        ) external {


        require(name_of_election_to_contestants[_election_name][_address_contestant].if_registered==0,"Address active as a contenstant");
        contestant_num.increment();
        uint256 constestant_num_Id = contestant_num.current();
        Contestant memory newContestant = Contestant(_election_name,msg.sender,constestant_num_Id, 0, _contestant_name, _contestant_image, _address_contestant);
        name_of_election_to_contestants[_election_name][_address_contestant] = newContestant;
        addresses.push(_address_contestant);
        election_names.push(_election_name);


        emit Created_Contestant(_address_contestant, _contestant_name, _contestant_image,_contestant_name);
    }
    
    /**
    * @dev gets all Contestants
    */
    function getContestants() external view returns ( Contestant[] memory) {
        
        uint Count = contestant_num.current();

        Contestant[] memory contestantArray = new Contestant[](Count);
      
        for (uint i = 0; i < Count; i++) {
        
           Contestant memory contestant = name_of_election_to_contestants[election_names[i]][addresses[i]];
           contestantArray[i] = contestant;
        }
        return contestantArray;
        
    }

    /**
    * @dev places a vote for a candidate
    * @param _address_contestant address of the contestant
    * @param _election_name name of the election to which the contestant was registered
    */
    function place_vote(address _address_contestant, string calldata _election_name) external{
       
        require(name_of_election_to_voter[_election_name][msg.sender].if_voted==0,"Already voted in this election");
        
        name_of_election_to_voter[_election_name][msg.sender].if_voted = 1;
        name_of_election_to_contestants[_election_name][_address_contestant].number_of_votes += 1;
        emit Voted(_address_contestant, msg.sender, contestants[_address_contestant].number_of_votes);
        
    }


}
