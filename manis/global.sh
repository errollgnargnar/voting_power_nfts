#!/bin/bash

resim reset

echo ""
echo -e "\e[7m Storing Accnt 1 credentials into cache"
account1_creds=($(resim new-account | awk -F": " '{print $2,$4,$6}'))
export XRD_ACCNT1=${account1_creds[0]}
export XRD_ACCNT1_pub=${account1_creds[1]}
export XRD_ACCNT1_priv=${account1_creds[2]}
resim show $XRD_ACCNT1

package_address=$(resim publish . | awk -F": " '{print $2}')
echo ""
echo -e "\e[7m****** ECHOING Package ADDRESS *******"
echo $package_address


echo ""
echo -e "\e[7m****** Initializing Component - VotingMachine new_machine"
component_address=$(resim call-function $package_address VotingMachine new_machine | awk -F"Component: " '{print $2}')

echo ""
echo -e "\e[7m****** ECHOING Component ADDRESS *******"
resim show $component_address 

echo ""
echo -e "\e[7m****** making new user  *******"
resim call-method $component_address become_user

echo ""
echo -e "\e[7m Storing NFT User Address"
user_1_nft_resource_address=$(resim show $XRD_ACCNT1 | grep 'User Badge' | awk -F"address: " '{print $2}' | awk -F", " '{print $1}')
resim show $user_1_nft_resource_address

echo ""
echo -e "\e[7m Showing NFT Data before Deposit"
resim call-method $component_address view_amount_deposited 1,$user_1_nft_resource_address

# resim run stake_xrd.rtm
echo ""
echo -e "\e[7m****** Calling RTM staking xrd  *******"
sed -i "s/{account_address}/$(echo $XRD_ACCNT1)/g" ./manis/stake_xrd.rtm
sed -i "s/{user_nft_resource_address}/$(echo $user_1_nft_resource_address)/g" ./manis/stake_xrd.rtm
sed -i "s/{component_address}/$(echo $component_address)/g" ./manis/stake_xrd.rtm
resim run ./manis/stake_xrd.rtm

# reset stake_xrd.rtm for new run
sed -i "s/$(echo $XRD_ACCNT1)/{account_address}/g" ./manis/stake_xrd.rtm
sed -i "s/$(echo $user_1_nft_resource_address)/{user_nft_resource_address}/g" ./manis/stake_xrd.rtm
sed -i "s/$(echo $component_address)/{component_address}/g" ./manis/stake_xrd.rtm

echo ""
echo -e "\e[7m Showing NFT Data after Deposit"
resim call-method $component_address view_amount_deposited 1,$user_1_nft_resource_address

echo ""
echo -e "\e[7m Viewing Voting Power"
resim call-method $component_address view_voting_power 1,$user_1_nft_resource_address

##### make a new account, add a deposit of 20 xrd then view voting power which should be 66%
account2_creds=($(resim new-account | awk -F": " '{print $2,$4,$6}'))
export XRD_ACCNT2=${account2_creds[0]}
export XRD_ACCNT2_pub=${account2_creds[1]}
export XRD_ACCNT2_priv=${account2_creds[2]}
resim show $XRD_ACCNT2

resim set-default-account $XRD_ACCNT2 $XRD_ACCNT2_priv

echo ""
echo -e "\e[7m****** making new user  *******"
resim call-method $component_address become_user

echo ""
echo -e "\e[7m Storing NFT User Address"
user_2_nft_resource_address=$(resim show $XRD_ACCNT2 | grep 'User Badge' | awk -F"address: " '{print $2}' | awk -F", " '{print $1}')
resim show $user_2_nft_resource_address

# resim run stake_xrd.rtm
echo ""
echo -e "\e[7m****** Calling RTM staking xrd  *******"
sed -i "s/{account_address}/$(echo $XRD_ACCNT2)/g" ./manis/stake_xrd.rtm
sed -i "s/{user_nft_resource_address}/$(echo $user_2_nft_resource_address)/g" ./manis/stake_xrd.rtm
sed -i "s/{component_address}/$(echo $component_address)/g" ./manis/stake_xrd.rtm
resim run ./manis/stake_xrd.rtm

# reset stake_xrd.rtm for new run
sed -i "s/$(echo $XRD_ACCNT2)/{account_address}/g" ./manis/stake_xrd.rtm
sed -i "s/$(echo $user_2_nft_resource_address)/{user_nft_resource_address}/g" ./manis/stake_xrd.rtm
sed -i "s/$(echo $component_address)/{component_address}/g" ./manis/stake_xrd.rtm

echo ""
echo -e "\e[7m Showing NFT Data after Deposit"
resim call-method $component_address view_amount_deposited 1,$user_2_nft_resource_address

echo ""
echo -e "\e[7m Viewing Voting Power"
resim call-method $component_address view_voting_power 1,$user_2_nft_resource_address

echo ""
echo -e "\e[7m Calling Method: { make_poll } to buy Red Gumball"
resim call-method $component_address make_poll "Buy a Red Gumball" "I vote that we buy a Red Gumball"

echo ""
echo -e "\e[7m Checking to see if Panic! with Duplicate Poll entry on title 'Buy a Red Gumball'"
resim call-method $component_address make_poll "Buy a Red Gumball" "I vote that we buy a Red Gumball"


echo ""
echo -e "\e[7m Calling Method: { make_poll } to buy Blue Gumball"
resim call-method $component_address make_poll "Buy a Blue Gumball" "I vote that we buy a Blue Gumball"


echo ""
echo -e "\e[7m Calling Method: { view_polls }"
resim call-method $component_address view_polls