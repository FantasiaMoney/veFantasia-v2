pragma solidity ^0.6.2;

import "./interfaces/IBurn.sol";
import "./interfaces/IMint.sol";

contract VTokenToToken {
  address public tokenMinter;
  address public vToken;

  constructor(address _tokenMinter, address _vToken) public {
    tokenMinter = _tokenMinter;
    vToken = _vToken;
  }

  function convert(address _to, uint256 _amount) external {
    IBurn(vToken).burnFrom(_to, _amount);
    IMint(tokenMinter).mint(_to, _amount);
  }
}
