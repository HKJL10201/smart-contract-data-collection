pragma solidity ^0.5.0;

import "./lib/IVotingPaper.sol";
import "./lib/ERC721Enumerable.sol";
import "./lib/ERC721Mintable.sol";
import "./lib/ERC721Metadata.sol";
import "./lib/AdvancedMinterRole.sol";
import "./lib/TransfererRole.sol";
import "./lib/VoterRole.sol";


contract VotingPaper is IVotingPaper, AdvancedMinterRole, ERC721Mintable, ERC721Enumerable, ERC721Metadata('IVoting', 'IVOT'), TransfererRole, VoterRole{

	struct VotingPaperStruct{ 
		uint256 surveyId;
		address owner;		// Chi è il proprietario del token
		address delegate;	// Chi può votare
		uint256 selection;		// Quale è la risposta. Viene inizializzata a 0 e poi incrementata per selezionare la risposta
	}

	mapping(uint256 => VotingPaperStruct) public votingPaperList;

	uint256 public nextId = 1;

	event Voted(address _who, uint256 _tokenId, uint256 _selection);


	function mint(uint256 _surveyId, address _owner, address _delegate) external onlyMinter returns (uint256){
		return _mint(_surveyId, _owner, _delegate);

	}

	function _mint(uint256 _surveyId, address _owner, address _delegate) internal returns (uint256){
		while (_exists(nextId)){
			nextId = nextId + 1;
		}

		VotingPaperStruct memory token = VotingPaperStruct({
	 		surveyId: _surveyId,
	 		owner: _owner,
	 		delegate: _delegate,
	 		selection: 0
			});

	 	votingPaperList[nextId] = token;
	 	super._mint(_owner, nextId);
	 	nextId = nextId + 1;
	 	return nextId-1;
	}

	function transferFrom(address _from, address _to, uint256 _tokenId) public onlyTransferer {
		require(ownerOf(_tokenId) == _from, "This user isn't the owner of the token and can't delegate!");
		require(votingPaperList[_tokenId].delegate == _from, "This user can't delegate.");
		require(_exists(_tokenId), "Voting paper doesn't exist.");
		require(votingPaperList[_tokenId].delegate != _to, "User is already delegate.");
		votingPaperList[_tokenId].delegate = _to;
		_transferFrom(_from, _to, _tokenId);
	}

	function safeTransferFrom(address _from, address _to, uint256 _tokenId) public onlyTransferer{
		safeTransferFrom(_from, _to, _tokenId, "");
	}

	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public onlyTransferer{
		require(ownerOf(_tokenId) == _from, "This user isn't the owner of the token and can't delegate!");
		require(votingPaperList[_tokenId].delegate == _from, "This user can't delegate.");
		require(_exists(_tokenId), "Voting paper doesn't exist.");
		require(votingPaperList[_tokenId].delegate != _to, "User is already delegate.");
		votingPaperList[_tokenId].delegate = _to;
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function vote(address _from, uint256 _surveyId, uint256 _tokenId, uint256 _selection) external onlyVoter returns(bool){
    	require(_selection != 0, "Can't use 0 as a selection!");
    	require(ownerOf(_tokenId) == _from, "This user isn't the owner of the token and can't vote!");
    	require(votingPaperList[_tokenId].delegate == _from, "This user can't vote.");
    	require(votingPaperList[_tokenId].selection == 0, "Already voted.");
    	votingPaperList[_tokenId].selection = _selection;
    	emit Voted(_from, _tokenId, _selection);
    	return true;
    }


    function getVotingPaperStructMetadata(uint256 _tokenId) public view returns(uint256, address, address, uint256){
    	return (votingPaperList[_tokenId].surveyId, votingPaperList[_tokenId].owner, votingPaperList[_tokenId].delegate, votingPaperList[_tokenId].selection);
    }


    function destroy()
	public
	onlyMaster{
		selfdestruct(msg.sender);
	}
}
