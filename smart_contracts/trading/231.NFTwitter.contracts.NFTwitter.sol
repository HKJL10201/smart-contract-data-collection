// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

error TweetDoesNotExists(uint256 tweetId);
error WrongParameters();
error TweetEmpty();
error OnlyOwnerOfTweet(uint256 tweetId);
error OwnerLikingTweet(uint256 tweetId);
error TweetAlreadyLiked(uint256 tweetId);
error TweetAlreadyUnliked(uint256 tweetId);

contract NFTwitter is ERC721Enumerable , Ownable {
    struct Tweet {
        uint256 tweetId;
        uint256 parentId;
        string content;
        uint256 timestamp;
        address author;
        address owner;
        uint256 likes;
    }

    uint256 private _tweetIds;
    mapping(uint256 => Tweet) public tweets;
    mapping(uint256 => uint256[]) public tweetsReplies;
    mapping(uint256 => mapping(address => bool)) public likedTweet;

    string baseSvg = "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 350 350'><style>.base { fill: white; font-family: serif; font-size: 24px; }</style><rect width='100%' height='100%' fill='black' /><text x='50%' y='50%' class='base' dominant-baseline='middle' text-anchor='middle'>";

    uint256 public tipsOwnerPercent;
    uint256 public tipsAuthorPercent;
    uint256 public tipsPlatformPercent;

    address public royaltiesReceiver;

    event NewTweet(uint256 tweetId);
    event TweetDeleted(uint256 tweetId);
    event TweetLiked(uint256 tweetId, address liker, uint256 newNbLikes);
    event TweetUnliked(uint256 tweetId, address liker, uint256 newNbLikes);

    modifier requireTweetExists(uint256 _tokenId) {
        if(!_exists(_tokenId)) {
            revert TweetDoesNotExists(_tokenId);
        }
        _;
    }

    constructor(address _royalties) ERC721("NFTwitter", "NFTT") Ownable() {
        _tweetIds = 1;

        tipsOwnerPercent = 70;
        tipsAuthorPercent = 20;
        tipsPlatformPercent = 10;

        royaltiesReceiver = _royalties;
    }

    function updateTipsPercent(uint256 owner, uint256 author, uint256 platform) external onlyOwner {
        if(owner + author + platform != 100){
            revert WrongParameters();
        }

        tipsOwnerPercent = owner;
        tipsAuthorPercent = author;
        tipsPlatformPercent = platform;
    }

    function tweet(string memory content, uint256 parentId) external {
        if(bytes(content).length == 0){
            revert TweetEmpty();
        }

        if(parentId != 0 && !_exists(parentId)) {   //no parent -> id = 0 (tweets ids starts at 1)
            revert TweetDoesNotExists(parentId);
        }

        uint256 newTweetId = _tweetIds;
        _safeMint(msg.sender, newTweetId);

        tweets[newTweetId] = Tweet({
            tweetId: newTweetId, parentId: parentId, content: content, timestamp: block.timestamp, author: msg.sender, owner: msg.sender, likes: 0
        });

        if(parentId != 0) {
            tweetsReplies[parentId].push(newTweetId);
        }
        
        ++_tweetIds;

        emit NewTweet(newTweetId);
    }

    function deleteTweet(uint256 _tokenId) external {
        if(ownerOf(_tokenId) != msg.sender) {
            revert OnlyOwnerOfTweet(_tokenId);
        }

        _burn(_tokenId);

        uint256 parentTweetId = tweets[_tokenId].parentId;

        delete tweets[_tokenId];

        if(parentTweetId != 0) {
            uint256 lastReplyId = tweetsReplies[parentTweetId][tweetsReplies[parentTweetId].length - 1];
            tweetsReplies[parentTweetId][_tokenId] = lastReplyId;
            tweetsReplies[parentTweetId].pop();
        }

        emit TweetDeleted(_tokenId);
    }

    function likeTweet(uint256 _tokenId) external requireTweetExists(_tokenId) {
        if(ownerOf(_tokenId) == msg.sender) {
            revert OwnerLikingTweet(_tokenId);
        }

        if(likedTweet[_tokenId][msg.sender]) {
            revert TweetAlreadyLiked(_tokenId);
        }
        
        likedTweet[_tokenId][msg.sender] = true;
        tweets[_tokenId].likes++;

        emit TweetLiked(_tokenId, msg.sender, tweets[_tokenId].likes);
    }

    function unlikeTweet(uint256 _tokenId) external requireTweetExists(_tokenId) {
        if(!likedTweet[_tokenId][msg.sender]) {
            revert TweetAlreadyUnliked(_tokenId);
        }

        delete likedTweet[_tokenId][msg.sender];
        tweets[_tokenId].likes--;

        emit TweetUnliked(_tokenId, msg.sender, tweets[_tokenId].likes);
    }

    function tipTweet(uint256 _tokenId) external payable requireTweetExists(_tokenId) {
        require(msg.value > 0);
        
        Tweet memory tweetTipped = tweets[_tokenId];
        if(tweetTipped.author == tweetTipped.owner) {
            uint256 authorOwnerPercent = tipsAuthorPercent + tipsOwnerPercent;
            uint authorAmount = authorOwnerPercent * msg.value / 100;
            payable(tweetTipped.author).transfer(authorAmount);
        }
        else {
            uint authorAmount = tipsAuthorPercent * msg.value / 100;
            payable(tweetTipped.author).transfer(authorAmount);

            uint ownerAmount = tipsOwnerPercent * msg.value / 100;
            payable(tweetTipped.owner).transfer(ownerAmount);
        }

        uint platformAmount = tipsPlatformPercent * msg.value / 100;
        payable(royaltiesReceiver).transfer(platformAmount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        super._afterTokenTransfer(from, to, tokenId, batchSize);

        tweets[tokenId].owner = to;
    }

    function tokenURI(uint256 _tokenId) public view override requireTweetExists(_tokenId) returns (string memory) {
        string memory json = Base64.encode(
            bytes(
            string(
                abi.encodePacked(
                '{"name": "NFTweet #',
                Strings.toString(_tokenId),
                '", "description": "This NFT is a tweet.", "image": "',
                tweetImageURI(_tokenId),
                '", "attributes": [ { "trait_type": "Parent Tweet Id", "value": "', Strings.toString(tweets[_tokenId].parentId),'"}, { "trait_type": "Content", "value": "',
                tweets[_tokenId].content,'"} , { "trait_type": "Likes", "value": "', Strings.toString(tweets[_tokenId].likes),'"}]}'
                )
            )
            )
        );

        string memory output = string(
            abi.encodePacked('data:application/json;base64,', json)
        );
        
        return output;
    }

    function tweetImageURI(uint256 _tokenId) public view requireTweetExists(_tokenId) returns (string memory) {
        string memory svg = string(abi.encodePacked(baseSvg, tweets[_tokenId].content, '</text></svg>'));
        
        return string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(svg))));
    }

    function getTweets() public view returns (Tweet[] memory tweetsList, bool[] memory likedBySender) {
        uint count = 0;
        for(uint i = 1; i < _tweetIds; i++){
            if(_exists(i))
                count++;
        }
        tweetsList = new Tweet[](count);
        likedBySender = new bool[](count);

        uint indice = 0;
        for(uint i = 1; i < _tweetIds; i++) {
            if(_exists(i)) {
                tweetsList[indice] = tweets[i];
                likedBySender[indice] = likedTweet[i][msg.sender];
                indice++;
            }
        }
        return (tweetsList, likedBySender);
    }
}