### Prerequisite :
#### Ensure 'tar' and 'unzip' already installed
    apt-get update -y && apt-get install tar unzip -y
### Steps :
#### Download the release :
    wget https://github.com/CryptoNodeID/side/releases/download/0.7.0/v0.7.0.zip && unzip v0.7.0.zip -d side
#### run setup command : 
    cd side && chmod ug+x *.sh && ./setup.sh
#### follow the instruction and then run below command to start the node :
    ./start_side.sh
#### Claim testnet faucet, fund address in the node and wait until node syncing done then run :
    ./create_validator.sh
