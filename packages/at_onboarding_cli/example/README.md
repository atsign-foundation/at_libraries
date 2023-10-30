List of steps to run the examples for checking apkam enrollment

1. Onboard an atsign which has privilege to approve/deny enrollments
   dart example/onboard.dart <atsign> <path_store_keys_file>
   e.g. dart example/onboard.dart @alice🛠 /home/alice/.atsign/@alice🛠_wavikey.atKeys
2. Authenticate using the onboarded atsign
   dart example/apkam_authenticate.dart <atsign> <path_of_keys_file_from_#1>
   e.g. dart example/apkam_authenticate.dart @alice🛠 /home/alice/.atsign/@alice🛠_wavikey.atKeys
3. Run client to approve enrollments
   dart example/enroll_app_listen.dart <atsign> <path_of_keys_file_from_#1>
   e.g dart example/enroll_app_listen.dart @alice🛠 /home/alice/.atsign/@alice🛠_wavikey.atKeys
4. Get OTP for enrollment
    - 4.1 Pkam through ssl client
      pkam:enrollmentId:<enrollmentId>:<pkamSignature>
      enrollmentId - get from the .atKeys file
      pkamChallenge - generate using the below commnd
      at_tools/packages/at_pkam>
      dart bin/main.dart -p <keys_file_path> <from_response>
      e.g dart bin/main.dart -p /home/alice/.atsign/@alice🛠_wavikey.atKeys -r _70138292-07b5-4e47-8c94-e02e38220775@alice🛠:883ea0aa-c526-400a-926e-48cae9281de9
    - 4.2 Once authenticated run otp:get
5. Request enrollment
    - 5.1 Submit enrollment from new client
      dart example/apkam_enroll.dart <atsign> <path_to_store_keys_file> <otp>
      e.g. dart example/apkam_enroll.dart @alice🛠 /home/alice/.atsign/@alice🛠_buzzkey.atKeys DY4UT4
    - 5.2 Approve the enrollment from the client from #3
    - 5.3 Enrollment should be successful and keys file stored in the path specified
6. Authenticate using the enrolled keys file
    - 6.1 dart example/onboard.dart <atsign> <path_of_keys_file_from_#5.1>
       
