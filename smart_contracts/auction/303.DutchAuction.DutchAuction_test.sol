//pragma solidity ^0.4.24;
pragma solidity >=0.4.0 <0.6.0;
//pragma solidity ^0.5.2;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "./DutchAuction.sol";

contract DutchAuction_test {
    DutchAuction sample;
    uint[4] vars;
    
    function() external payable { }
    
    function beforeAll() public {
        vars[0] = 10e4;
        vars[1] = 10;
        vars[2] = 100;
        vars[3] = 3000;
        sample = new DutchAuction(address(this), vars[0], vars[1], vars[2], vars[3]);
        Assert.equal(uint(1), uint(1), "Error in beforeAll function");
    }
    
    function checkConstructor() public {
        Assert.equal(sample.author(), address(this), "Address is incorrect");
        Assert.equal(sample.startPrice(), vars[0], "");
        Assert.equal(sample.decEach(), vars[1], "");
        Assert.equal(sample.decStep(), vars[2], "");
        Assert.equal(sample.minPrice(), vars[3], "");
        Assert.equal(sample.winnerAddress(), address(this), "");
        Assert.notEqual(sample.startPrice() * sample.decEach() * sample.decStep() * sample.minPrice(), 0, "");
        Assert.greaterThan(sample.startPrice(), sample.minPrice(), "");
        
        /*assert(sample.author() == address(this));
        assert(sample.startPrice() == vars[0]);
        assert(sample.decEach() == vars[1]);
        assert(sample.decStep() == vars[2]);
        assert(sample.minPrice() == vars[3]);
        assert(sample.winnerAddress() == address(this));
        assert(sample.startPrice() * sample.decEach() * sample.decStep() * sample.minPrice() != 0);
        assert(sample.startPrice() >= sample.minPrice());*/
    }
    
    function checkClose() public {
        Assert.equal(address(this), sample.author(), "Error");
    }
}
