Library to authenticate and onboard @signs. Library implementation is present in /lib. Example on how to invoke the library present in /example.

Use cases for at_cli_onboarding:
    1) Authentication
    2) Onboarding

Authentication: Proving that one actually owns the atsign. One needs to authenticate himself before performing operations on that atsign. Operations include reading, writing, deleting or updating data in the atsign's keystore and sending notifications from that atsign.
    Steps to authenticate: 
        1) Import at_cli_onboarding.
        2) Set preferences using AtOnboardingPreference. Either of secret key or path to .atKeysFile need to be provided to authenticate.
        3) Instantiate AtOnboardingServiceImpl using the required atsign and a valid instance of AtOnboardingPreference.
        4) Call the authenticate method on AtOnboardingService.
        5) Use getAtLookup/getAtClient to get authenticated instances of AtLookup and AtClient respectively which can be used to perform more complex operations on the atsign.

Onboarding: Performing initial one-time authentication using cram secret encoded in the qr_code. This process activates the atsign making it ready to use.
    Steps to onboard:
        1) Import at_cli_onboarding.
        2) Set preferences using AtOnboardingPreference. Either of cram_secret or path to qr_code containing cram_secret need to be provided to activate the atsign.
        3) Setting the download path is mandatory in AtOnboardingPreference in order to save the .atKeysFile.
        4) Instantiate AtOnboardingServiceImpl using the required atsign and a valid instance of AtOnboardingPreference.
        5) Call the onboard on AtOnboardingServiceImpl.
        6) Use getAtLookup/getAtClient to get authenticated instances of AtLookup and AtClient respectively which can be used to perform more complex operations on the atsign.

Setting valid values to AtOnboardingPreference:
    1) isLocalStorageRequired needs to be set to true as AtClient now needs a local secondary in order to run.
    2) As a result of Step 1, one also need to provide commitLogPath and hiveStoragePath.
    3) One must set the namespace variable to match the name of their app.