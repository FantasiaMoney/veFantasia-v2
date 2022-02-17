# Description

```
VToken - not transfer able token (bind with msg.sender)


VTokenSale - user can buy vToken via ETH by token/eth rate


VTokenToToken - user can convert vToken to token with time based rate


TokenToVtoken - user can convert token to vToken with rate 1 to 1


Token - standrad mintable and burnable token


Minter - allow mint for permitted addresses


LDManager - mint tokens and add LD with token/eth


WalletDistributor - owners of vtoken can claim from this wallet each 30 days


Reserve - fetch can split ETH with dex, sale and reserve. And users who deposiyed tokens
in reserve can sell (also they can eran more or lose, dependse on sale rate)
```


# if Router-Hash-test failed
```
Make sure You updated PairHash in config.js and test/contracts/dex/libraries/UniswapV2Library.sol
```
