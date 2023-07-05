// If pkam auth mode is keysFile then pkam private key will be generated during onboarding and saved in the keys file.
// For subsequent authentication, pkam private key will be read from the keys file supplied by the user.
// If pkam auth mode is sim or any other secure element, then private key is not accessible directly. Only the data will be passed to the sim/secure element, pkam signature can be retrieved and verified.pkam private key will not be a part of keys file in this case.
// If auth mode is apkam, each app/client will have its own key pair for pkam authentication.
enum PkamAuthMode { keysFile, sim, apkam }
