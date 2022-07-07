// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {Errors} from "../../../utils/Errors.sol";
import {ATokenOracle} from "oracle/aave/ATokenOracle.sol";
import {IERC20} from "../../../interface/tokens/IERC20.sol";
import {IAccount} from "../../../interface/core/IAccount.sol";
import {IntegrationTestBase} from "../utils/IntegrationTestBase.sol";
import {AaveV2Controller} from "controller/aave/AaveV2Controller.sol";
import {IProtocolDataProvider}
    from "controller/aave/IProtocolDataProvider.sol";

contract AaveV2IntegrationTest is IntegrationTestBase {
    address account;
    address user = cheats.addr(1);

    address lendingPool = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    address aaveDataProvider = 0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d;
    address aWeth = 0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;
    address aDai = 0x028171bCA77440897B824Ca71D1c56caC55b68A3;

    ATokenOracle aTokenOracle;
    AaveV2Controller aaveController;

    function setupAaveController() internal {
        aTokenOracle = new ATokenOracle(oracle);
        oracle.setOracle(aWeth, aTokenOracle);

        aaveController = new AaveV2Controller(
            controller,
            IProtocolDataProvider(aaveDataProvider)
        );
        controller.updateController(lendingPool, aaveController);
        controller.toggleTokenAllowance(aWeth);
    }

    function setUp() public {
        setupContracts();
        setupOracles();
        setupAaveController();
        setupWethController();
        account = openAccount(user);
    }

    function testDepositWeth(uint64 amt) public {
        cheats.assume(amt > 1e8 gwei);
        // Setup
        deposit(user, account, address(0), amt);
        wrapEth(account, amt, user);
        uint value = IERC20(WETH).balanceOf(account);

        // Encode call data
        bytes memory data = abi.encodeWithSignature(
            "deposit(address,uint256,address,uint16)",
            WETH,
            value,
            account,
            0
        );

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, WETH, lendingPool, value);
        accountManager.exec(account, lendingPool, 0, data);
        cheats.stopPrank();

        // Assert
        assertGt(IERC20(aWeth).balanceOf(account), 0);
        assertEq(IAccount(account).assets(0), aWeth);
    }

    function testWithdrawWeth(uint64 amt) public {
        // Setup
        testDepositWeth(amt);

        // Encode call data
        bytes memory data = abi.encodeWithSignature(
            "withdraw(address,uint256,address)",
            WETH,
            type(uint256).max,
            account
        );

        // Test
        cheats.startPrank(user);
        accountManager.exec(account, lendingPool, 0, data);
        cheats.stopPrank();

        // Assert
        assertEq(IERC20(aWeth).balanceOf(account), 0);
        assertGt(IERC20(WETH).balanceOf(account), 0);
        assertEq(IAccount(account).assets(0), WETH);
    }

    function testDepositDaiError(uint64 amt) public {
        // Encode call data
        bytes memory data = abi.encodeWithSignature(
            "deposit(address,uint256,address,uint16)",
            aDai,
            amt,
            account,
            0
        );

        // Test
        cheats.startPrank(user);
        cheats.expectRevert(Errors.FunctionCallRestricted.selector);
        accountManager.exec(account, lendingPool, 0, data);
        cheats.stopPrank();
    }
}