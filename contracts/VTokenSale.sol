pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IMint.sol";
import "./interfaces/IOwnable.sol";


contract VTokenSale is Ownable {
  using SafeMath for uint256;

  address payable public beneficiary;
  address public token;
  address public vToken;
  IUniswapV2Router02 public Router;

  event Buy(address indexed user, uint256 amount);

  /**
  * @dev constructor
  *
  * @param _token         token address
  * @param _vToken        vToken address
  * @param _beneficiary   Address for receive ETH
  * @param _router        Uniswap v2 router
  */
  constructor(
    address _token,
    address _vToken,
    address payable _beneficiary,
    address _router
    )
    public
  {
    token = _token;
    vToken = _vToken;
    beneficiary = _beneficiary;
    Router = IUniswapV2Router02(_router);
  }

  /**
  * @dev buy tokens for msg.sender
  *
  */
  function buy() public payable {
    buyFor(msg.sender);
  }

  /**
  * @dev buy tokens for address
  *
  */
  function buyFor(address _to) public payable {
    // not allow buy 0
    require(msg.value > 0, "Zerro input");
    // calculate amount of morebtc to send
    uint256 sendAmount = getSalePrice(msg.value);
    // transfer ETH from user to receiver
    beneficiary.transfer(msg.value);
    // transfer mbtc to user
    IMint(_vToken).mint(_to, sendAmount);
    // event
    emit Buy(_to, sendAmount);
  }

  /**
  * @dev return sale price from token
  */
  function getSalePrice(uint256 _amount) public view returns(uint256) {
    address[] memory path = new address[](2);
    path[0] = Router.WETH();
    path[1] = token;
    uint256[] memory res = Router.getAmountsOut(_amount, path);
    return res[1];
  }

  /**
   * @dev fallback function
   */
  receive() external payable  {
    buy();
  }
}
