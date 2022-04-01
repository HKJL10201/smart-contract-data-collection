pragma solidity >=0.4.22 <0.9.0;
contract votev {
	struct Candidate{
        //id of candidate
        address id;
        //name of candidate
        string name;
        //votecount of candidate
        uint voteCount;
    }
    
    event eventVote(
        address indexed _candidateid
        );
    
        mapping (address => Candidate) public candidates;
        /*address[] public candidates =  [0x1c3FD0f55dd0baF26bEB7f853E0Ec7001610A69b, 
                                        0xDCdf59888230ef23CB87a1771BD6DeA088e69F25,
                                        0x98F6EAbCb33519f2cb353c801D0b3E0574BC36b7];

          */
	    mapping (address => bool) public voter;
	
	uint public candidatecount;
        
    constructor() payable public{
        addCandidate("Modi(BJP)" ,0x1c3FD0f55dd0baF26bEB7f853E0Ec7001610A69b);
        addCandidate("Rahul(Congress)",0xDCdf59888230ef23CB87a1771BD6DeA088e69F25);
        addCandidate("Mamta(TMC)",0x98F6EAbCb33519f2cb353c801D0b3E0574BC36b7);
        addCandidate("Yogi(BJP-UP)" ,0x998270Eb69b062191AE77355F06E6E863690Dded);
        addCandidate("Priyanka(Congress-UP)",0x5dBa1dD702584285C612E9DE840616431282E497);
        addCandidate("Akhilesh(SP-UP)",0xf67B2b782AD4DF39Cf8428D003F10eA847Be882d);
        addCandidate("Mayawati(BSP-UP)",0x3CE1A3AE4ef1f641F8C2A36F749451EB639a52A0);
        addCandidate("Om Birla(BJP-Raj)" ,0x92edd8212464C7C6c4256fefe0d6df79089B94B3);
        addCandidate("Sachin(Congress-Raj)",0x96C9ACf2C703b776591A0084e389b42b0F61bA98);
        addCandidate("Manjeet(AAP-Raj)",0xD1084e8F78c9d8799A2eC7bbC8B48A138BFC21c7);
        addCandidate("Deve Gowda(JD-Raj)",0xd35f180cC5C7B43e097A0936C723D584bCDe3ee7);
    }
    
    function addCandidate(string memory _name,address  _add  ) private
    {candidatecount++;
        
        candidates[_add] = Candidate(_add, _name, address(_add).balance/1e18);
    }
    
    	function sendBJP () public payable 
    	{
    	
    	require(!voter[msg.sender]);
        address payable  ada= address(0x1c3FD0f55dd0baF26bEB7f853E0Ec7001610A69b);
        //payable(ada);
        (bool sent, bytes memory data) = ada.call.value( 1 ether)("");
        voter[msg.sender] = true;
        require(sent, "Failed to send Ether");
        candidates[ada].voteCount=address(ada).balance/1e18;
        emit eventVote( ada );
    	}
    
    function sendCONG () public payable 
    	{
    	require(!voter[msg.sender]);
        address payable  adq=address(0xDCdf59888230ef23CB87a1771BD6DeA088e69F25);
        //payable(adq);
        (bool sent, bytes memory data) = adq.call.value( 1 ether)("");
        voter[msg.sender] = true;
        require(sent, "Failed to send Ether");
        candidates[adq].voteCount=address(adq).balance/1e18;
        emit eventVote( adq );
    	}
    function sendMAM () public payable 
    	{
    	require(!voter[msg.sender]);
        address payable adq=address(0x98F6EAbCb33519f2cb353c801D0b3E0574BC36b7);
        //payable(adq);
        (bool sent, bytes memory data) = adq.call.value( 1 ether)("");
        voter[msg.sender] = true;
        require(sent, "Failed to send Ether");
        candidates[adq].voteCount=address(adq).balance/1e18;
        emit eventVote( adq );
    	}
    function sendUPBJP () public payable 
        {
        require(!voter[msg.sender]);
        address payable adq=address(0x998270Eb69b062191AE77355F06E6E863690Dded);
        //payable(adq);
        (bool sent, bytes memory data) = adq.call.value( 1 ether)("");
        voter[msg.sender] = true;
        require(sent, "Failed to send Ether");
        candidates[adq].voteCount=address(adq).balance/1e18;
        emit eventVote( adq );
        }
    function sendUPCONG () public payable 
        {
        require(!voter[msg.sender]);
        address payable adq=address(0x5dBa1dD702584285C612E9DE840616431282E497);
        //payable(adq);
        (bool sent, bytes memory data) = adq.call.value( 1 ether)("");
        voter[msg.sender] = true;
        require(sent, "Failed to send Ether");
        candidates[adq].voteCount=address(adq).balance/1e18;
        emit eventVote( adq );
        }
     function sendUPSP() public payable 
        {
        require(!voter[msg.sender]);
        address payable adq=address(0xf67B2b782AD4DF39Cf8428D003F10eA847Be882d);
        //payable(adq);
        (bool sent, bytes memory data) = adq.call.value( 1 ether)("");
        voter[msg.sender] = true;
        require(sent, "Failed to send Ether");
        candidates[adq].voteCount=address(adq).balance/1e18;
        emit eventVote( adq );
        }
     function sendUPBSP() public payable 
        {
        require(!voter[msg.sender]);
        address payable adq=address(0x3CE1A3AE4ef1f641F8C2A36F749451EB639a52A0);
        //payable(adq);
        (bool sent, bytes memory data) = adq.call.value( 1 ether)("");
        voter[msg.sender] = true;
        require(sent, "Failed to send Ether");
        candidates[adq].voteCount=address(adq).balance/1e18;
        emit eventVote( adq );
        }
    function sendRAJBJP() public payable 
        {
        require(!voter[msg.sender]);
        address payable adq=address(0x92edd8212464C7C6c4256fefe0d6df79089B94B3);
        //payable(adq);
        (bool sent, bytes memory data) = adq.call.value( 1 ether)("");
        voter[msg.sender] = true;
        require(sent, "Failed to send Ether");
        candidates[adq].voteCount=address(adq).balance/1e18;
        emit eventVote( adq );
        }
    function sendRAJCong() public payable 
        {
        require(!voter[msg.sender]);
        address payable adq=address(0x96C9ACf2C703b776591A0084e389b42b0F61bA98);
        //payable(adq);
        (bool sent, bytes memory data) = adq.call.value( 1 ether)("");
        voter[msg.sender] = true;
        require(sent, "Failed to send Ether");
        candidates[adq].voteCount=address(adq).balance/1e18;
        emit eventVote( adq );
        }
    function sendRAJJD() public payable 
        {
        require(!voter[msg.sender]);
        address payable adq=address(0xd35f180cC5C7B43e097A0936C723D584bCDe3ee7);
        //payable(adq);
        (bool sent, bytes memory data) = adq.call.value( 1 ether)("");
        voter[msg.sender] = true;
        require(sent, "Failed to send Ether");
        candidates[adq].voteCount=address(adq).balance/1e18;
        emit eventVote( adq );
        }
    function sendRAJAap() public payable 
        {
        require(!voter[msg.sender]);
        address payable adq=address(0xD1084e8F78c9d8799A2eC7bbC8B48A138BFC21c7);
        //payable(adq);
        (bool sent, bytes memory data) = adq.call.value( 1 ether)("");
        voter[msg.sender] = true;
        require(sent, "Failed to send Ether");
        candidates[adq].voteCount=address(adq).balance/1e18;
        emit eventVote( adq );
        }
}

