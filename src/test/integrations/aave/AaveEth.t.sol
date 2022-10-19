// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Errors} from "../../../utils/Errors.sol";
import {ATokenOracle} from "oracle/aave/ATokenOracle.sol";
import {IERC20} from "../../../interface/tokens/IERC20.sol";
import {IAccount} from "../../../interface/core/IAccount.sol";
import {IntegrationTestBase} from "../utils/IntegrationTestBase.sol";
import {AaveEthController} from "controller/aave/AaveEthController.sol";
import {ILendingPoolAddressProvider} from "./interface/ILendingPoolAddressProvider.sol";

contract AaveEthIntegrationTest is IntegrationTestBase {
    address account;
    address user = cheats.addr(1);

    ILendingPoolAddressProvider addressProvider =
        ILendingPoolAddressProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);

    address lendingPool;
    address aWeth = 0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;
    address aaveWethGateway = 0xcc9a0B7c43DC2a5F023Bb9b738E45B0Ef6B06E04;

    ATokenOracle aTokenOracle;
    AaveEthController aaveEthController;

    function setupAaveController() internal {
        aTokenOracle = new ATokenOracle(oracle);
        oracle.setOracle(aWeth, aTokenOracle);
        controller.toggleTokenAllowance(aWeth);

        aaveEthController = new AaveEthController(aWeth);
        controller.updateController(aaveWethGateway, aaveEthController);
    }

    function setUp() public {
        lendingPool = addressProvider.getLendingPool();
        setupContracts();
        setupOracles();
        setupAaveController();
        setupWethController();
        account = openAccount(user);
    }

    function testDepositEth(uint64 amt) public {
        // Setup
        cheats.assume(amt > 1e8 gwei);
        deposit(user, account, address(0), amt);

        // Encode call data
        bytes memory data = abi.encodeWithSignature(
            "depositETH(address,address,uint16)",
            lendingPool,
            account,
            0
        );

        // Test
        cheats.prank(user);
        accountManager.exec(account, aaveWethGateway, amt, data);

        // Assert
        assertGt(IERC20(aWeth).balanceOf(account), 0);
        assertEq(IAccount(account).assets(0), aWeth);
    }

    function testWithdrawEth(uint64 amt) public {
        // Setup
        testDepositEth(amt);

        // Encode call data
        bytes memory data = abi.encodeWithSignature(
            "withdrawETH(address,uint256,address)",
            lendingPool,
            type(uint256).max,
            account
        );

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, aWeth, aaveWethGateway, type(uint256).max);
        accountManager.exec(account, aaveWethGateway, 0, data);

        // Assert
        assertEq(IERC20(aWeth).balanceOf(account), 0);
        assertGt(account.balance, 0);
        assertEq(IAccount(account).getAssets().length, 0);
    }
}