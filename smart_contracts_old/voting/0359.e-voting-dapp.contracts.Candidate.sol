// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

contract Candidate {

    /* Structs */

    struct CandidateDetails {
        uint256 id;
        string name;
        string nic;
        string party;
    }


    /* Storage */

    /** @dev Number of candidates added. */
    address[] private candidateAddresses;

    /** Mapping of address to candidate details */
    mapping (address => CandidateDetails) public candidates;


    /* Public Functions */

    /**
     * @notice Add a candidate.
     *
     * @dev Adds a new candidate to the system.
     *      - Checks whether candidate is already added or not.
     *      - Adds a candidate to the `candidates` mapping.
     *      - Adds candidate's address to `candidateAddresses` address array.
     *
     * @param _name - candidate's name
     * @param _nic - candidate's nic
     * @param _party - candidate's party
     */
    function addCandidate(
        string memory _name,
        string memory _nic,
        string memory _party
    ) public {
        require (
            candidates[msg.sender].id == uint256(0),
            "Candidate must not already exist."
        );

        uint256 id = candidateAddresses.length + uint(100);
        candidates[msg.sender] = CandidateDetails(
            id,
            _name,
            _nic,
            _party
        );

        candidateAddresses.push(msg.sender);
    }

    /**
     * @notice Get candidate details.
     *
     * @dev Get candidate details by `_address`
     *      - candidate for `_address` must be available.
     *
     * @param _address - address of a candidate.
     */
    function getCandidate(address _address)
        public
        view
        returns (
            uint256 id_,
            string memory name_,
            string memory nic_,
            string memory party_
        )
    {
        require (
            candidates[_address].id != uint256(0),
            "Candidate not present."
        );

        CandidateDetails memory candidate = candidates[_address];
        return (
            candidate.id,
            candidate.name,
            candidate.nic,
            candidate.party
        );
    }

    /**
     * Get total candidate count.
     *
     * @notice Returns total candidate count.
     */
    function getCandidateCount() public view returns (uint256 count_) {
        count_ = candidateAddresses.length;
    }
}
