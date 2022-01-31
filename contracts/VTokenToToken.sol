pragma solidity ^0.6.2;

import "./interfaces/IBurn.sol";
import "./interfaces/IMint.sol";

contract VTokenToToken {
  using SafeERC20 for IERC20

  address public token;
  address public vToken;

  constructor(address _token, address _vToken) public {
    token = _token;
    vToken = _vToken;
  }

  function convert(address _to, uint256 _amount) external {
    IBurn(vToken).burn(_amount);
    IMint(token).mint(_to, _amount);
  }
}
