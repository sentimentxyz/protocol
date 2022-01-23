pragma solidity ^0.8.0;

import "@ds-test/src/test.sol";

import "./mocks/token.sol";
import "./mocks/oracle.sol";
import "./Cheatcode.sol";

import "../LERC20.sol";
import "../DefaultRateModel.sol";
import "../interface/IERC20.sol";
import "../AccountManager.sol";
import "../RiskEngine.sol";
import "../UserRegistry.sol";
import "../AccountFactory.sol";

contract LendingFlowTest is DSTest {

    address public creator;
    address public user1;

    ICheatCode cheatCode = ICheatCode(HEVM_ADDRESS);

    LERC20 public ltoken;
    Token public token;

    DefaultRateModel public rateModel;
    
    AccountManager public accountManager;
    RiskEngine public riskEngine;
    UserRegistry public userRegistry;
    AccountFactory public factory;


    function setUp() public {
        user1 = cheatCode.addr(2);
        cheatCode.startPrank(user1, user1);
        token = new Standard_Token(100, "sentiment", 1, "STM");
        cheatCode.stopPrank();

        creator = cheatCode.addr(1);
        cheatCode.startPrank(creator, creator);
        
        riskEngine = setUpRiskEngine();
        factory = new AccountFactory(address(0));
        userRegistry = new UserRegistry();
        accountManager = new AccountManager(address(riskEngine), address(factory), address(userRegistry));
        
        rateModel = new DefaultRateModel();        
        ltoken = new LERC20("sentiment", "STM", 1, address(token), address(rateModel), address(accountManager), 1);

        cheatCode.stopPrank();
    }

    function setUpRiskEngine() public returns (RiskEngine engine) {
        Oracle oracle = new Oracle();
        engine = new RiskEngine(address(oracle));
    }

    function testLtokenCreation() view public {
        string memory name = "sentiment";
        require(keccak256(abi.encodePacked((ltoken.name()))) == keccak256(abi.encodePacked((name))));
        require(token.balanceOf(user1) == 100);
        require(ltoken.underlyingAddr() == address(token));
    }

    function testDeposit() public {
        address user2 = cheatCode.addr(5);
        cheatCode.startPrank(user1, user1);
        ltoken.deposit(10);
        require(token.balanceOf(user1) == 90);
        require(token.balanceOf(address(ltoken)) == 10);
    }
}