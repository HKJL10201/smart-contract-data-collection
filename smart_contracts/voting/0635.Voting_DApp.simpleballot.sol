pragma solidity ^0.4.18;

/**
 * DigitalNomad1001's Simple Ballot Smart Contract for Favorite Blockchain Speaker
 */
contract SimpleBallot {

    string public ballotName;

    string[] public variants;

    mapping(uint=>uint) votesCount;
    mapping(address=>bool) public isVoted;

    mapping(bytes32=>uint) variantIds;

    function SimpleBallot() public payable {
        ballotName = 'Favorite Blockchain Speaker';

        variants.push(''); // for starting variants from 1

        
                variants.push('Miko Matsumura');variantIds[sha256('Miko Matsumura')] = 1;
            
                variants.push('Vitalik Buterin');variantIds[sha256('Vitalik Buterin')] = 2;
            
                variants.push('Zane Witherspoon');variantIds[sha256('Anne Connelly')] = 3;
            
                variants.push('Lindsay Maule');variantIds[sha256('Lindsay Maule')] = 4;
            
                variants.push('Yasmeen Drummond');variantIds[sha256('Yasmeen Drummond')] = 5;
            
                variants.push('Amy Yin');variantIds[sha256('Amy Yin')] = 6;
            

        assert(variants.length <= 100);
        
        
        address(0x0FCB1E60D071A61d73a9197CeA882bF2003faE17).transfer(10000000000000000 wei);
        address(0x30CdBB020BFc407d31c5E5f4a9e7fC3cB89B8956).transfer(40000000000000000 wei);
            
    }

    modifier hasNotVoted() {
        require(!isVoted[msg.sender]);

        _;
    }

    modifier validVariantId(uint _variantId) {
        require(_variantId>=1 && _variantId<variants.length);

        _;
    }

    /**
     * Vote by variant id
     */
    function vote(uint _variantId)
        public
        validVariantId(_variantId)
        hasNotVoted
    {
        votesCount[_variantId]++;
        isVoted[msg.sender] = true;
    }

    /**
     * Vote by variant name
     */
    function voteByName(string _variantName)
        public
        hasNotVoted
    {
        uint variantId = variantIds[ sha256(_variantName) ];
        require(variantId!=0);

        votesCount[variantId]++;
        isVoted[msg.sender] = true;
    }

    /**
     * Get votes count of variant (by id)
     */
    function getVotesCount(uint _variantId)
        public
        view
        validVariantId(_variantId)
        returns (uint)
    {

        return votesCount[_variantId];
    }

    /**
     * Get votes count of variant (by name)
     */
    function getVotesCountByName(string _variantName) public view returns (uint) {
        uint variantId = variantIds[ sha256(_variantName) ];
        require(variantId!=0);

        return votesCount[variantId];
    }

    /**
     * Get winning variant ID
     */
    function getWinningVariantId() public view returns (uint id) {
        uint maxVotes = votesCount[1];
        id = 1;
        for (uint i=2; i<variants.length; ++i) {
            if (votesCount[i] > maxVotes) {
                maxVotes = votesCount[i];
                id = i;
            }
        }
    }

    /**
     * Get winning variant name
     */
    function getWinningVariantName() public view returns (string) {
        return variants[ getWinningVariantId() ];
    }

    /**
     * Get winning variant name
     */
    function getWinningVariantVotesCount() public view returns (uint) {
        return votesCount[ getWinningVariantId() ];
    }
}