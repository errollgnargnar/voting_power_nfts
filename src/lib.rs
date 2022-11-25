use scrypto::prelude::*;

// a component where you having voting power based on how much you have deposited.
// for example, 2 people - Person A deposits 60 tokens and Person B deposits 40 tokens
// The total vault contains 100 tokens
// Person A has 60% total power.
// Person B has 40$ total power.

// The component will issue an NFT with their total deposited
// When the user returns to deposit more, they will give their NFT to the component. The component will update the total of tokens deposited on the metadata of the NFT.

// There will be a function where they can check their voting power. TotalTokensDeposited / TotalTokenInVault

#[derive(NonFungibleData, Debug, Encode, Decode, Describe)]
pub struct User {
    #[scrypto(mutable)]
    pub total_deposited: Decimal,
}

blueprint! {
    struct VotingMachine {
        user_manager_badge: Vault,
        // total wallet vault
        xrd_vault: Vault,
        user_resource_address: ResourceAddress
    }

    impl VotingMachine {

        // This is a function, and can be called directly on the blueprint once deployed
        pub fn new_machine() -> ComponentAddress {

            // Create a badge for internal use which will hold mint/burn authority for the admin badge we will soon create
            let user_manager_badge = ResourceBuilder::new_fungible()
            .divisibility(DIVISIBILITY_NONE)
            .initial_supply(1);

            let user_badge = ResourceBuilder::new_non_fungible()
                .metadata("name", "User Badge")
                .mintable(rule!(require(user_manager_badge.resource_address())), LOCKED)
                .updateable_non_fungible_data(rule!(require(user_manager_badge.resource_address())), LOCKED)
                .no_initial_supply();

            Self {
                xrd_vault: Vault::new(RADIX_TOKEN),
                user_manager_badge: Vault::with_bucket(user_manager_badge),
                user_resource_address:user_badge
            }
            .instantiate()
            .globalize()
        }

        // Allow people to get access to this component by 
        // getting a member badge
        pub fn become_user(&self) -> Bucket {
            let data = User {
                total_deposited: Decimal::zero()
            };

            self.user_manager_badge.authorize(|| {
                borrow_resource_manager!(self.user_resource_address)
                    .mint_non_fungible(&NonFungibleId::random(), data)
            })
        }

        // Allow people presenting a member badge to stake XRD into
        // a vault on this component. It updates the amount that is staked on the
        // member NFT metadata.
        pub fn stake_xrd(&mut self, xrd: Bucket, user_proof: Proof) {
            let user_proof = user_proof.validate_proof(self.user_resource_address).expect("Wrong proof provided!");
            let amount = xrd.amount();

            self.xrd_vault.put(xrd);

            // Update the amount staked on the member NFT
            let non_fungible: NonFungible<User> = user_proof.non_fungible();
            let mut user_data = non_fungible.data();

            user_data.total_deposited += amount;

            self.user_manager_badge.authorize(|| {
                borrow_resource_manager!(self.user_resource_address)
                    .update_non_fungible_data(&non_fungible.id(), user_data);
            });
        }


        // view how much staked/deposited
        pub fn view_amount_deposited(&mut self, user_nft: Bucket) -> Bucket {
            let user_data: User =  borrow_resource_manager!(self.user_resource_address).get_non_fungible_data(&user_nft.non_fungible_id());

            info!("{:?}", user_data);

            user_nft
        }

        pub fn view_voting_power(&mut self, user_proof: Bucket) -> Bucket {
            // let user_proof = user_proof.validate_proof(self.user_resource_address).expect("Wrong proof provided!");

            // Update the amount staked on the member NFT
            let non_fungible: NonFungible<User> = user_proof.non_fungible();
            let user_data = non_fungible.data();

            let voting_power = user_data.total_deposited / self.xrd_vault.amount() * 100;

            info!("Total voting power is: {:?}%", voting_power);

            user_proof
        }
    }
}