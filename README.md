### Steps :
#### Download the release :
    wget https://github.com/CryptoNodeID/side/releases/download/0.6.0/v0.6.0.zip && unzip v0.6.0.zip -d side
#### run setup command : 
    cd side && chmod ug+x *.sh && ./setup.sh
#### follow the instruction and then run below command to start the node :
    ./start_sided.sh
#### Claim testnet faucet, fund address in the node and wait until node syncing done then run :
    ./create_validator.sh
