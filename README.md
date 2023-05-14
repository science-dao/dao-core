# DeSci DAO Stack   
This is a modular stack for architecting DeSci DAOs and a base layer of DeSci DAOs, researchers, investors.

This libary contains the core smart contracts for the DeSci DAO stack. Everything is deployed on the FEVM.

![My First Board (1)](https://github.com/science-dao/gateway/assets/44027725/6cb12189-fa78-4306-90c0-725607964719)

DeSciDAO members contribute research papers to the DAO, which are encrypted and uploaded to Filecoin via the gateway. A token is attached to each upload, and other parties can buy access to the research from the DAO. Then upon successful payment they get a token, which they must present to the gateway to assert that they have the rights to get the research. The DAO then unlocks it.

The smart contracts also contain options for funding research via the DAO. Anyone can contribute in any supported token. Investors can later on vote on the research and decide if it was successful.

- Anyone can query the base layer and build frontends on top of it.
- i.e. the investor SBTs will prove how much and into what someone invested --> a DeSci AngelList FE can be built for it
- i.e. FE software tool that enables DAO members to collaborate on science, vote etc.

### Smart contract on the FEVM:
Membertoken: 0x2DD2A78435eb4958Dc79eD9Ac5DdFe84bee67924  
Access token: 0xF0120Af77C9dfe8906Ee834316A3543B6eC4CD65  
Investor token: 0x38DD1bd522cde8Bc9F483d62c5ba1e033F145e4A  

Governance: 0x49A652AF944FF7A8cFA4F9deEf30e4B3f2d67c04  
Deal Client: 0x4AF367023a959C9e06e7fa49cDacFd2576Caa068  
Utils: 0x426d370B4AE21275c1975529Cc856b59004c5294  
Storage: 0x8c6beE0A6b6968AeA6D9fbb9E0cCD84FC8aEA2e1   
