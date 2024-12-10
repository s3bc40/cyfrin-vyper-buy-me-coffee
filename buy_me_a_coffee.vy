# Get funds from users
# Withdraw funds
# Set a minimum funding value in USD

# pragma version 0.4.0
# @license: MIT
# @author: s3bc40

interface AggregatorV3Interface:
    def decimals() -> uint256: view
    def description() -> String[1000]: view
    def version() -> uint256: view
    def latestAnswer() -> int256: view
    def latestRoundData() -> (int256,int256,int256,uint256,uint256): view

minimum_usd: uint256
price_feed: AggregatorV3Interface # 0x694AA1769357215DE4FAC081bf1f309aDC325306 sepolia
owner: public(address)
funders: public(DynArray[address, 1000])

@deploy
def __init__(price_feed_address: address):
    self.minimum_usd = as_wei_value(5, "ether")
    self.price_feed = AggregatorV3Interface(price_feed_address)
    self.owner = msg.sender

@external
@payable
def fund():
    """
    Allows users to send $ to this contract.
    """
    usd_value_of_eth: uint256 = self._get_eth_to_usd_rate(msg.value)
    # assert msg.value >= as_wei_value(1, "ether"), "You must spend more ETH!"
    assert usd_value_of_eth >= self.minimum_usd, "You must spend more ETH!"
    self.funders.append(msg.sender)
    

@external
def withdraw():
    assert msg.sender == self.owner, "Only owner can withdraw"
    send(self.owner, self.balance)
    self.funders = []

# @external
# @view
# def get_price() -> int256:
#     price_feed: AggregatorV3Interface = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306)
#     return staticcall price_feed.latestAnswer()

@external
@view
def get_eth_to_usd_rate(eth_amount: uint256) -> uint256:
    return self._get_eth_to_usd_rate(eth_amount)

@internal
@view
def _get_eth_to_usd_rate(eth_amount: uint256) -> uint256:
    price: int256 = staticcall self.price_feed.latestAnswer() # 10**8
    eth_price: uint256 = convert(price, uint256) * (10 ** 10) # 10**8 * 10**10 -> 10**18 
    eth_amount_in_usd: uint256 = (eth_amount * eth_price) // (1 * (10 ** 18)) # $ = ($/ETH * ETH_AMOUNT) / ETH
    return eth_amount_in_usd