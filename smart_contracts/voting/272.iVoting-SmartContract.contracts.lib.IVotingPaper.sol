pragma solidity ^0.5.0;


interface IVotingPaper{
		

		function mint(uint256, address, address) external returns (uint256);

		function transferFrom(address, address, uint256) external;

		function safeTransferFrom(address, address, uint256) external;

		function safeTransferFrom(address, address, uint256, bytes calldata) external;

		function vote(address, uint256, uint256, uint256) external returns(bool);

		function getVotingPaperStructMetadata(uint256) external view returns(uint256, address, address, uint256);

		function destroy() external;

}