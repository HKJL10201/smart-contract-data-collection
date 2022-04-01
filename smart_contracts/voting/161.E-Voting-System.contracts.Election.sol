// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Election {
    // Model a Candidate
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
        string image;
    }

    string private admin = "Admin";
    string private password = "0000";


    // Store accounts that have voted
    mapping(uint256 => bool) public voters;
    // Store Candidates
    // Fetch Candidate
    mapping(uint256 => Candidate) public candidates;
    // Store Candidates Count
    uint256 public candidatesCount;

    // voted event
    event votedEvent(uint256 indexed _candidateId);

    constructor() {
        addCandidate("McDonalds", "https://lassencofair.files.wordpress.com/2016/07/mcdonalds-logo.png");
        addCandidate("KFC", "https://image.similarpng.com/very-thumbnail/2020/06/kfc-logo-free-download-PNG.png");
        addCandidate("Burger King", "https://logowik.com/content/uploads/images/burger-king-new-20218389.jpg");
    }

    function addCandidate(string memory _name, string memory _image) public {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0, _image);
    }

    function isAdmin(string memory _admin, string memory _password) public view{
        require(stringsEquals(_admin,admin) && stringsEquals(_password,password));
    }

    function stringsEquals(string memory s1, string memory s2) private pure returns (bool) {
    bytes memory b1 = bytes(s1);
    bytes memory b2 = bytes(s2);
    uint256 l1 = b1.length;
    if (l1 != b2.length) return false;
    for (uint256 i=0; i<l1; i++) {
        if (b1[i] != b2[i]) return false;
    }
    return true;
}

    function deleteCandidate(uint256 _id) public {
        require(candidates[_id].voteCount == 0);
        delete candidates[_id];
    }

    function vote(uint256 _candidateId, uint256 _voterId) public {
        // require that they haven't voted before
        require(!voters[_voterId]);

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // record that voter has voted
        voters[_voterId] = true;

        // update candidate vote Count
        candidates[_candidateId].voteCount++;

        // trigger voted event
        emit votedEvent(_candidateId);
    }

    function getCandidates() public view returns (Candidate[] memory) {
        Candidate[] memory ret = new Candidate[](candidatesCount);
        for (uint256 i = 0; i < candidatesCount; i++) {
            ret[i] = candidates[i+1];
        }
        return ret;
    }

    function getCandidatesCount() public view returns (uint256) {
        uint256 ret = candidatesCount;
        return ret;
    }
}
