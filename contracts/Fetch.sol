// pragma solidity ^0.6.2;
//
// import "./interfaces/IUniswapV2Router02.sol";
// import "./interfaces/IWETH.sol";
// import "./interfaces/ISale.sol";
// import "./interfaces/IStake.sol";
//
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
//
//
// contract Fetch is Ownable {
//
//   using SafeERC20 for IERC20;
//   using SafeMath for uint256;
//
//   address public WETH;
//
//   address public dexRouter;
//
//   address public token;
//
//   address public sale;
//
//   uint256 public percentToDex = 40;
//
//   uint256 public percentToSale = 45;
//
//   uint256 public percentToPlatform = 10;
//
//   uint256 public percentToLD = 5;
//
//   address public platformAddress;
//
//   address public stake;
//
//   /**
//   * @dev constructor
//   *
//   * @param _WETH                  address of Wrapped Ethereum token
//   * @param _dexRouter             address of UNI v2 DEX
//   * @param _token                 address of OHM token
//   * @param _sale                  sale
//   * @param _platformAddress       address for fee
//   * @param _stake                 OHM stake
//   */
//   constructor(
//     address _WETH,
//     address _dexRouter,
//     address _token,
//     address _sale,
//     address _platformAddress,
//     address _stake
//     )
//     public
//   {
//     WETH = _WETH;
//     dexRouter = _dexRouter;
//     token = _token;
//     sale = _sale;
//     platformAddress = _platformAddress;
//     stake = _stake;
//   }
//
//   function convert() external payable {
//     _convertFor(msg.sender);
//   }
//
//   function convertFor(address receiver) external payable {
//     _convertFor(receiver);
//   }
//
//   /**
//   * @dev spit ETH input with DEX and Sale
//   */
//   function _convertFor(address receiver) internal {
//     require(msg.value > 0, "zerro eth");
//     // swap ETH
//     swapETHInput(msg.value);
//     // stake remains for user
//     uint256 tokenReceived = IERC20(token).balanceOf(address(this));
//     require(tokenReceived > 0, "not swapped");
//     IERC20(token).approve(stake, tokenReceived);
//     IStake(stake).stakeFor(tokenReceived, receiver);
//   }
//
//
//  /**
//  * @dev swap ETH to token via DEX and Sale
//  */
//  function swapETHInput(uint256 input) internal {
//   (uint256 ethToDex,
//    uint256 ethToSale,
//    uint256 ethToPlatform,
//    uint256 ethToLD) = calculateToSplit(input);
//
//   // get some tokens from DEX
//   if(ethToDex > 0)
//     swapETHViaDEX(dexRouter, token, ethToDex);
//
//   // get tokens from sale
//   if(ethToSale > 0)
//     swapETHViaSale(ethToSale);
//
//   // put some tokens and eth to LD
//   if(ethToLD > 0)
//     addLiquidity(ethToLD);
//
//   // transfer to platfrom
//   if(ethToPlatform > 0)
//     payable(platformAddress).transfer(ethToPlatform);
//  }
//
//  // helper for swap ETH to token
//  function swapETHViaDEX(address routerDEX, address toToken, uint256 amount) internal {
//    // SWAP split % of ETH input to token
//    address[] memory path = new address[](2);
//    path[0] = WETH;
//    path[1] = toToken;
//
//    IUniswapV2Router02(routerDEX).swapExactETHForTokens{value:amount}(
//      1,
//      path,
//      address(this),
//      block.timestamp + 1800
//    );
//  }
//
//  // helper for get OHM from Sale via deposit
//  function swapETHViaSale(uint256 amount) internal {
//     ISale(sale).buy.value(amount)();
//  }
//
//  // add LD
//  function addLiquidity(uint256 ethAmount) private {
//       require(address(this).balance >= ethAmount, "Not enough eth");
//       uint256 tokenAmount = getTokenPrice(ethAmount);
//
//       // approve token transfer to cover all possible scenarios
//       IERC20(token).approve(dexRouter, tokenAmount);
//       require(IERC20(token).balanceOf(address(this)) >= tokenAmount, "Not enough token");
//       // add the liquidity
//       IUniswapV2Router02(dexRouter).addLiquidityETH{value: ethAmount}(
//           token,
//           tokenAmount,
//           0, // slippage is unavoidable
//           0, // slippage is unavoidable
//           sale,
//           block.timestamp + 15 minutes
//       );
//   }
//
//   // get token price
//   function getTokenPrice(uint256 _ethAmount) public view returns(uint256) {
//       address[] memory path = new address[](2);
//       path[0] = WETH;
//       path[1] = token;
//       uint256[] memory res = IUniswapV2Router02(dexRouter).getAmountsOut(_ethAmount, path);
//       return res[1];
//   }
//
//  /**
//  * @dev return eth amount for dex, sale and platform
//  */
//  function calculateToSplitETH(uint256 ethInput)
//    private
//    view
//    returns (
//      uint256 ethToDex,
//      uint256 ethToSale,
//      uint256 ethToPlatform,
//      uint256 ethToLD
//    )
//  {
//    ethToDex = ethInput.div(100).mul(percentToDex);
//    ethToSale = ethInput.div(100).mul(percentToSale);
//    ethToPlatform = ethInput.div(100).mul(percentToPlatform);
//    ethToLD = ethInput.div(100).mul(percentToLD);
//  }
//
//  /**
//  * @dev return split % amount of input
//  */
//  function calculateToSplit(uint256 ethInput)
//    public
//    view
//    returns(uint256 ethToDex, uint256 ethToSale, uint256 ethToPlatform, uint256 ethToLD)
//  {
//    (ethToDex,
//     ethToSale,
//     ethToPlatform,
//     ethToLD) = calculateToSplitETH(ethInput);
//  }
//
//  /**
//  * @dev allow owner update split %
//  */
//  function updateSplitPercent(
//    uint256 _percentToDex,
//    uint256 _percentToSale,
//    uint256 _percentToPlatform,
//    uint256 _percentToLD
//  )
//    external
//    onlyOwner
//  {
//    uint256 total = _percentToDex + _percentToSale + _percentToPlatform + percentToLD;
//    require(total == 100, "Wrong total");
//
//    percentToDex = _percentToDex;
//    percentToSale = _percentToSale;
//    percentToPlatform = _percentToPlatform;
//    percentToLD = _percentToLD;
//  }
//
//  /**
//  * @dev allow owner update platform address
//  */
//  function updatePlatformAddress(address _platformAddress)
//    external
//    onlyOwner
//  {
//    platformAddress = _platformAddress;
//  }
//
//  /**
//  * @dev allow owner withdraw eth for case if some eth stuck or was sent accidentally
//  */
//  function withdraw()
//    external
//    onlyOwner
//  {
//    payable(owner()).transfer(address(this).balance);
//  }
//
//  fallback() external payable {}
// }
