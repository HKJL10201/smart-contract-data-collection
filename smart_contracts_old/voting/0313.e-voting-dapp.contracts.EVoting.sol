// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract evoting {
    /**
     * Voting structure that helps to create a map and contain all the voter
     * thar are register
     */
    struct Voter {
        address id; // address of the user
        string fname; // First Name
        string lname; // Last name
        string email; // Email Address
        uint256 dob; // Date of Birth as integer to store the date time according to JS date time
        string mobile; // Mobile Number
        string uidai; // Aadhar Number
        string role; // Role i.e user or admin
        bool verified; // Verified flag that help to verifiy the voter details
        bool voted; // Voted flag to verify that the user give his vote or not
        uint256 vote; // Index of the voter list the user give vote
    }

    struct VoterMap {
        address[] keys;
        mapping(address => Voter) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    VoterMap private voterMap;

    // function voterMapSize() private view returns (uint256) {
    //     return voterMap.keys.length;
    // }

    /**
     * voterMapSet function adds a user information
     * @param  key {address} is the storage parameter
     * @param  val {Voter} This is the memory parameter containing the info of users
     */
    function voterMapSet(address key, Voter memory val) private {
        // If the key is present then add the values of the voter corresponding to that key
        // Else create a new entry
        if (voterMap.inserted[key]) {
            voterMap.values[key] = val;
        } else {
            voterMap.inserted[key] = true;
            voterMap.values[key] = val;
            voterMap.indexOf[key] = voterMap.keys.length;
            voterMap.keys.push(key);
        }
    }

    /**
     * voterMapRemove function deletes the info of a user
     * @param  key {address} is the address of the user to be deleted
     */
    function voterMapRemove(address key) private {
        // If the key is not inserted then return
        if (!voterMap.inserted[key]) {
            return;
        }
        // If key is present then delete the key and also the values corresponding to that key
        delete voterMap.inserted[key];
        delete voterMap.values[key];

        uint256 index = voterMap.indexOf[key]; // Take the index of the key to be deleted
        uint256 lastIndex = voterMap.keys.length - 1; // Take the index of the last element in the key array
        address lastKey = voterMap.keys[lastIndex]; // Take the address key of the last index

        voterMap.indexOf[lastKey] = index; // Change the last key's index with the index of the key to be deleted
        delete voterMap.indexOf[key]; // Delete the corresponding key index from the indexOf map

        // Replace the lastKey in the key array with the key to be deleted
        // Pop the last key from the key array
        voterMap.keys[index] = lastKey;
        voterMap.keys.pop();
    }

    // voters mapping that map address to Voter structure mentioned above
    // mapping(address => Voter) public voters;

    // Address of the admin i.e the user address that deploy the contract
    address admin;

    /**
     * Team structure that helps to create an array contains all the teams
     */
    struct Team {
        string representative; // Name of the representative who stand in behalf to to team
        string description; // Description of the team
        string teamName; // Team name
        uint256 voteCount; // Number of vote
    }

    // Teams array contains all the teams
    Team[] public teams;
    // Event of for adding voter
    event AddVoter(Voter _voter);

    //"Soumen", "Khara", "soumen@gmail.com", 931113000000,"8945612397","12345678900"
    constructor(
        string memory fname,
        string memory lname,
        string memory email,
        uint256 dob,
        string memory mobile,
        string memory uidai
    ) {
        admin = msg.sender;
        Voter memory voter = Voter(
            admin,
            fname,
            lname,
            email,
            dob,
            mobile,
            uidai,
            "admin",
            true,
            false,
            0
        );
        voterMapSet(admin, voter);
    }

    // Event for adding a team
    event AddTeam(Team _team);

    /**
     * addTeam function adds a team information
     * @param representative {string} is the memory parameter containing the representative name
     * @param description {string} is the memory parameter containing the info of team
     * @param teamName {string} is the memory parameter having the name of the team
     */
    function addTeam(
        string memory representative,
        string memory description,
        string memory teamName
    ) public {
        require(msg.sender == admin, "Only admin can add new teams");
        teams.push(
            Team({
                representative: representative,
                description: description,
                teamName: teamName,
                voteCount: 0
            })
        );
        emit AddTeam(teams[teams.length - 1]);
    }

    // Event for registering a voter
    event Register(Voter _voter);

    /**
     * register function registers a normal user
     * @param fname {string} is the memory parameter containing the first name
     * @param lname {string} is the memory parameter containing the last name
     * @param email {string} is the memory parameter having the email id
     * @param dob {uint256} is the memory parameter having the date of birth of the user
     * @param mobile {string} is the memory parameter having the mobile number
     * @param uidai {string} is the memory parameter having the aadhaar number
     */
    function register(
        string memory fname,
        string memory lname,
        string memory email,
        uint256 dob,
        string memory mobile,
        string memory uidai
    ) public {
        address sender = msg.sender;
        // TODO: check that a user is already exist or not
        Voter memory voter = Voter(
            sender,
            fname,
            lname,
            email,
            dob,
            mobile,
            uidai,
            "user",
            false,
            false,
            0
        );
        voterMapSet(sender, voter);
        emit Register(voter);
    }

    /**
     * getTeams function returns teams that are participating
     * @return {Team[]} returns a array containing the info of teams
     */
    function getTeams() public view returns (Team[] memory) {
        return teams;
    }

    /**
     * getVoter function returns info about the user
     * @return {Voter} returns a array containing the info of a user
     */
    function getVoter() public view returns (Voter memory) {
        return voterMap.values[msg.sender];
    }

    // Event for voted
    event Vote(Voter _voter);

    /**
     * vote function handles the voting of a user
     * @param to {uint256} contains the team the user is voitng
     */
    function vote(uint256 to) public {
        Voter storage voter = voterMap.values[msg.sender];

        require(voter.verified, "You are not eligible to give vote.");
        require(!voter.voted, "You are already voted.");

        voter.voted = true;
        voter.vote = to;
        teams[to].voteCount += 1;
        emit Vote(voter);
    }

    /**
     * getUnverifiedVoter function returns the users who are unverified
     * @return {Voter[]} returns an array of the user who are unverified
     */
    function getUnverifiedVoter() public view returns (Voter[] memory) {
        // TODO: Create a pagination type data return
        // INFO: Resolve null value from the voters
        uint256 counter = 0;

        for (uint256 i = 0; i < voterMap.keys.length; i++) {
            Voter memory item = voterMap.values[voterMap.keys[i]];
            if (!item.verified) counter++;
        }

        Voter[] memory voters = new Voter[](counter);
        uint256 j = 0;
        for (uint256 i = 0; i < voterMap.keys.length; i++) {
            Voter memory item = voterMap.values[voterMap.keys[i]];
            if (!item.verified) {
                voters[j] = item;
                j++;
            }
        }
        return voters;
    }

    event VerifyVoter(string _message);

    function verifyVoter(address _address) public {
        require(msg.sender == admin, "Only admin can verify voter");
        Voter storage voter = voterMap.values[_address];
        voter.verified = true;
        emit VerifyVoter("Voter update success");
    }

    function getWinnerIndex() private view returns (uint256 _winner) {
        uint256 maxVote = 0;
        for (uint256 i = 0; i < teams.length; i++) {
            if (teams[i].voteCount > maxVote) {
                maxVote = teams[i].voteCount;
                _winner = i;
            }
        }
    }

    function getWinner() public view returns (Team memory _winner) {
        require(teams.length != 0, "There is no teams added yet");
        _winner = teams[getWinnerIndex()];
    }
}
