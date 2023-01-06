// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Proxy} from "../proxy/Proxy.sol";
import {AccountManager} from "../core/AccountManager.sol";
import {ISwapRouterV3} from "controller/uniswap/ISwapRouterV3.sol";

contract CapAssetsTest is Test {

    address uniV3Router = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

    IERC20 WETH = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    IERC20 USDC = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    IERC20 USDT = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
    IERC20 WBTC = IERC20(0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f);
    IERC20 WSTETH = IERC20(0x5979D7b546E38E414F7E9822514be443A4800529);
    IERC20 DAI = IERC20(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);

    Proxy accountManagerProxy = Proxy(payable(0x62c5AA8277E49B3EAd43dC67453ec91DC6826403));
    AccountManager accountManager = AccountManager(payable(0x62c5AA8277E49B3EAd43dC67453ec91DC6826403));

    AccountManager newAccountManager;

    address user = 0x884ba7391637BfCE1D0B8C3aF6723477f6541e0e;
    address account = 0x355eA7352DD7502f6B72b217DFEA526DAC0b0F3a;

    function setUp() public {
        newAccountManager = new AccountManager();
        changePrank(0x92f473Ef0Cd07080824F5e6B0859ac49b3AEb215);
        accountManagerProxy.changeImplementation(address(newAccountManager));
        accountManager.setAssetCap(2);
    }

    function testOpenAccount() public {
        accountManager.openAccount(address(this));
    }

    function testCloseAccount() public {
        changePrank(user);
        accountManager.closeAccount(account);
    }

    function testDepositOneAsset() public {
        changePrank(user);
        deal(address(WETH), user, 2e18, true);
        WETH.approve(address(accountManager), 1e18);
        accountManager.deposit(account, address(WETH), 1e18);
    }

    function testDepositTwoAssets() public {
        testDepositOneAsset();
        deal(address(USDC), user, 2e10, true);
        USDC.approve(address(accountManager), 1e10);
        accountManager.deposit(account, address(USDC), 1e10);
    }

    function testFailDepositThreeAssets() public {
        testDepositOneAsset();
        testDepositTwoAssets();
        deal(address(USDT), user, 2e10, true);
        USDT.approve(address(accountManager), 1e10);
        accountManager.deposit(account, address(USDT), 1e10);
    }

    function testBorrowOneAsset() public {
        testDepositOneAsset();
        accountManager.borrow(account, address(WETH), 1e18);
        accountManager.borrow(account, address(WETH), 1e18);
    }

    function testBorrowTwoAssets() public {
        testBorrowOneAsset();
        accountManager.borrow(account, address(USDC), 1e6);
    }

    function testFailBorrowThreeAssets() public {
        testBorrowTwoAssets();
        accountManager.borrow(account, address(USDT), 1e6);
    }

    function testSwapWETHUSDC() public {
        testDepositOneAsset();
        bytes memory data = abi.encodeWithSignature(
            "exactInputSingle((address,address,uint24,address,uint256,uint256,uint160))",
            getExactInputParams(
                address(WETH),
                address(USDC),
                account,
                0,
                1e17
            )
        );
        accountManager.approve(account, address(WETH), uniV3Router, type(uint).max);
        accountManager.exec(account, uniV3Router, 0, data);
    }

    function testSwapWETHUSDT() public {
        testSwapWETHUSDC();
        bytes memory data = abi.encodeWithSignature(
            "exactInputSingle((address,address,uint24,address,uint256,uint256,uint160))",
            getExactInputParams(
                address(WETH),
                address(USDT),
                account,
                0,
                WETH.balanceOf(account)
            )
        );
        accountManager.exec(account, uniV3Router, 0, data);
    }

    function testFailSwapWETHUSDT() public {
        testSwapWETHUSDC();
        bytes memory data = abi.encodeWithSignature(
            "exactInputSingle((address,address,uint24,address,uint256,uint256,uint160))",
            getExactInputParams(
                address(WETH),
                address(USDT),
                account,
                0,
                1e17
            )
        );
        accountManager.exec(account, uniV3Router, 0, data);
    }

    function testCollateralStatus() public {
        assertTrue(accountManager.isCollateralAllowed(address(WETH)));
        assertTrue(accountManager.isCollateralAllowed(address(USDC)));
        assertTrue(accountManager.isCollateralAllowed(address(USDT)));
        assertTrue(accountManager.isCollateralAllowed(address(WBTC)));
        assertTrue(accountManager.isCollateralAllowed(address(DAI)));
    }

    function getExactInputParams(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 amountOut,
        uint256 amountIn
    )
        private
        pure
        returns (ISwapRouterV3.ExactInputSingleParams memory data)
    {
        data = ISwapRouterV3.ExactInputSingleParams(
            tokenIn,
            tokenOut,
            3000,
            recipient,
            amountIn,
            amountOut,
            0
        );
    }
}