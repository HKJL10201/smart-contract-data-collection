pragma solidity >=0.4.21 <0.7.0;

contract Election {
    // CONSTANTS
    uint constant public numOfCandidates = 3;

    // Candidate info
    struct CandidateInfo {
        string name;
        string bio;
        string photo;
    }
    CandidateInfo[] private candidateInfo;

    // Candidate
    struct Candidate {
        uint id;
        string name;
        string bio;
        string photo;
        uint voteCount;
    }

    // Read/Write Candidates
    mapping(uint => Candidate) public candidates;

    // Store addresses of the accounts who has voted already.
    mapping(address => bool) public voters;

    // Store number of Candidates
    uint public candidatesCount;

    address payable public owner;
    string public electionName;
    bool public started;
    bool public ended;
    uint public nrVoters;

    // Create candidate profiles
    function populateCandidateInfo() private {
        candidateInfo.push(CandidateInfo("Luna Lovegood", "Luna is one of a kind, and it’s not just her uniqueness itself that makes her special, but how she is true to herself and is honest about the things she likes. She isn’t trying to put on a show. She never comes across as fake or needy for attention; she simply is as unique as she seems. Luna has that unbelievably rare quality of actually not giving a damn what anyone else thinks of her. She’s so comfortable being different. She’s fearless. One of Luna’s most striking characteristics is the kindness she shows toward others, a pure kindness unmarred by superiority or judgmentalism. She certainly thinks outside the box, and while she’s very well-read, she’s open to original thoughts and ideas that aren’t found in textbooks. Altogether, Luna’s uniqueness, honesty, courage, kindness, creative thinking, intuitive understanding of people and mythology, and wisdom beyond her years help make her a great candidate for the position of Headmaster of Hogwarts School of Witchcraft and Wizardry.", "https://fsa.zobj.net/crop.php?r=HhN4F6Az_oMTkpo8U-A3ltjkFbFnn0uJBnN9R0AOWJmxgn4pn7Fw9Wxb_zq6ULH1l2IUx_yNsZ5jaF4lmvL8VrH7HSGQWVRDf3L92aGkBY40JPpxr12XuQoDI23d_YBpVSpfj9CChBbbozHl"));
        candidateInfo.push(CandidateInfo("Hermione Granger", "Hermione shines by being immovably on the side of equality and justice. She’d rather make a fool out of herself and stand for a cause, than do nothing at all and stare in the face of blatant cruelty. She isn't a born genius but she is hard working, someone who earns the title of being the Brightest Witch of her Age. She is a fierce leader and a voice of reason, her thirst for knowledge and curiosity making her a driving force, the woman who has the reigns, the heroine beside the hero. Hermione is Gryffindor for her bravery, Ravenclaw for her brains, and also a Hufflepuff for her kindness and genuine concern about the people around her. As a headmaster she wouldn't be just the Brain of Hogwarts, but also the Heart, and that is probably her most important asset.", "https://i.pinimg.com/originals/19/01/8e/19018e8e978f94fa501fdb2caa435b92.jpg"));
        candidateInfo.push(CandidateInfo("Ginevra Weasley", "Ginny Weasley is effortlessly awesome. She is fiery and fierce.Her curses are Hogwarts-renowned for their power, and her abilities are so impressive that she was even invited to join Horace Slughorn’s elite Slug  back in the day. She also became a professional quidditch player for the Holyhead Harpies, and after she retired from the team, she became the senior quidditch correspondent for the Daily Prophet. Ginny’s got it all together and we know you know she’s great. Her inner-confidence leaves her with nothing to prove,and so she uses her status to seek out and befriend genuine people, and stick up for the little weirdos. An incredible judge of character, Ginny sees the special spark in people that others often miss. Like most Weasley’s, Ginny runs pretty hot and cold. She thinks with her heart. She gets caught up in the moment. She takes risks.But she also does the things the rest us wish we had the guts to do. Ginny really is a force to be reckoned with. Her belief manifests itself in power, her enduring spirit is an inspiration and that would make her a beloved headmaster for all.", "https://i.pinimg.com/originals/fb/39/df/fb39df9345b0663fc3df6773b90006b5.jpg"));
    }

    constructor() public {
        owner = msg.sender;
        started = false;
        ended = false;
        nrVoters = 0;
    }

    modifier ownerOnly() {
        require(msg.sender == owner, "owner only action");
        _;
    }

    function addCandidate(CandidateInfo memory _info) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _info.name, _info.bio, _info.photo, 0);
    }

    function beginElection(string memory _name) public ownerOnly {
        require(started == false, "election already started");
        started = true;
        electionName = _name;
        populateCandidateInfo();
        for(uint i = 0; i < numOfCandidates; i++) {
            addCandidate(candidateInfo[i]);
        }
    }

    function endElection() public ownerOnly {
        require(started == true, "election not started");
        require(ended == false, "election already ended");
        ended = true;
    }

    function destroyContract() public ownerOnly {
        selfdestruct(owner);
    }

    function getCandidateName(uint id) public view returns(string memory) {
        require(id<=numOfCandidates, "index out of bounds");
        return candidates[id].name;
    }

    function getCandidateBio(uint id) public view returns(string memory) {
        require(id<=numOfCandidates, "index out of bounds");
        return candidates[id].bio;
    }

    function getCandidatePhoto(uint id) public view returns(string memory) {
        require(id<=numOfCandidates, "index out of bounds");
        return candidates[id].photo;
    }

    function getCandidateVotes(uint id) public view returns(uint) {
        require(id<=numOfCandidates, "index out of bounds");
        return candidates[id].voteCount;
    }

    function vote(uint _id, address _voter) public payable {
        require(ended == false, "election already ended");
        require(!voters[_voter]);
        require(_id > 0 && _id <= candidatesCount);
        nrVoters++;
        voters[_voter] = true;
        candidates[_id].voteCount++;
    }
}
