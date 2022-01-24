// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@ds-test/src/test.sol";
import { ERC20PresetFixedSupply } from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";

import "./mocks/oracle.sol";
import "./Cheatcode.sol";

import "../LERC20.sol";
import "../LEther.sol";
import "../DefaultRateModel.sol";
import "../interface/IERC20.sol";
import "../AccountManager.sol";
import "../RiskEngine.sol";
import "../UserRegistry.sol";
import "../AccountFactory.sol";

contract Test is DSTest {

    address public creator;
    address public user1;

    CheatCode cheatCode = CheatCode(HEVM_ADDRESS);

    LERC20 public ltoken;
    LEther public lEther;
    ERC20PresetFixedSupply public token;

    DefaultRateModel public rateModel;
    
    AccountManager public accountManager;
    RiskEngine public riskEngine;
    UserRegistry public userRegistry;
    AccountFactory public factory;


    function setUp() public {
        user1 = cheatCode.addr(2);
        cheatCode.startPrank(user1);
        token = new ERC20PresetFixedSupply("Sentiment", "STM", 100, user1);
        cheatCode.stopPrank();

        creator = cheatCode.addr(1);
        cheatCode.startPrank(creator);
        
        riskEngine = setUpRiskEngine();
        factory = new AccountFactory(address(0));
        userRegistry = new UserRegistry();
        accountManager = new AccountManager(address(riskEngine), address(factory), address(userRegistry));
        
        rateModel = new DefaultRateModel();        
        ltoken = new LERC20("sentiment", "STM", 1, address(token), address(rateModel), address(accountManager), 1);

        lEther = new LEther("Ether", "ETH", 1, address(0), address(rateModel), address(accountManager), 1);

        cheatCode.stopPrank();
    }

    function setUpRiskEngine() public returns (RiskEngine engine) {
        Oracle oracle = new Oracle();
        engine = new RiskEngine(address(oracle));
    }
}