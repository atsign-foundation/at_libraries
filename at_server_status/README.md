<img src="https://atsign.dev/assets/img/@developersmall.png?sanitize=true">

### Now for a little internet optimism

# AtServerStatus
The at_server_status library provides an easy means to check on the status
of the @root server as well as the @server for a particular @sign.

## The @server configuration lifecycle
The lifecycle of an @server as it gets created and paired is as follows:

1. The first step is to provision an @sign from a registrar site.
    - The @sign is reserved by the registrar so nobody else can provision it.
    - @root does not yet have an entry for the @sign, rootStatus returns:
    - ```AtStatus.rootStatus = RootStatus.notFound```
    - An @server has not been deployed for the @sign, serverStatus returns:
    - ```AtStatus.serverStatus = ServerStatus.unavailable```
    - The overall status from the status() method returns:
    - ```AtStatus.status() = AtSignStatus.notFound```
    - Or, if you prefer an HttpStatus code, use the httpStatus() method:
    - ```AtStatus.httpStatus() = 404```
    
1. The next step in the process is when "Activate" is selected for an @sign 
on the registrar site.
    - An @server gets deployed for the @sign which returns when it is ready.
    - ```AtStatus.serverStatus = ServerStatus.teapot```
    - An entry in @root is created with the location of the @server which returns:
    - ```AtStatus.rootStatus = RootStatus.found```
    - A shared secret gets created and stored on the @server.
    - The shared secret QR Code is displayed on the registrar site which is 
    used to pair the @server with a mobile device when all is ready.

1. The next step in the process is when an @compliant application is used to 
 "pair" with the @server for the first time. 
    - Typically, the application will detect that the @server has not been paired
    and will prompt you to scan the QR Code to set this up.
    - The application presents the option to scan the QR Code which will then 
    be used to pair the device to the @server.
    - If you are unable to scan the QR Code (for example if you are using only 
    the mobile device), then there is an option to copy the QR Code to the device 
    and then upload it to the application.
    - The application will then create a public/private keypair to pair to the
    @server which is stored on your device in the secure enclave which provides 
    best in class security for this all important information. You need to guard
    this well as it is the key (pun intended) to protecting your information.
    - At this time, the information stored in the device keychain is only '
    accessible to the application that created it. Another means and another 
    library (the at_pairing library is used for that purpose).

1. The final step in the process is to save a backup of this information.
    - In case you   

## Configuring additional applications to work with your @server

There are three methods that you can use to retrieve status information:

1. Get an AtStatus object for some @sign
    - ```AtStatus atStatus = await atStatusImpl.get(atSign);```
    - The AtStatus object includes both @root status and the @server status
1. The status() method returns an enumerated AtSignStatus value of the overall 
status of an @sign.
    - ```AtSignStatus atSignStatus = atStatus.status();```
1. The httpStatus() method returns an integer matching HTTPStatus values 
representing the overall status of an @sign.
    - ```int httpStatus = atStatus.httpStatus();```

## List of enumerated values
1. AtSignStatus enumerated values are:
    - ```enum AtSignStatus { notFound, teapot, activated, unavailable, error }```
1. RootStatus enumerated values are:
    - ```enum RootStatus { found, notFound, stopped, unavailable, error }```
1. ServerStatus enumerated values are:
    - ```enum ServerStatus { ready, teapot, activated, stopped, unavailable, error }```
1. Const values from HttpStatus are:
```
static const int notFound = 404
// Not Found(404) @server has no root location, is not running and is not activated

static const int serviceUnavailable = 503
// Service Unavailable(503) @server has root location, is not running and is not activated

int 418
// I'm a teapot(418) @server has root location, is running and but not activated

static const int ok = 200
// OK (200) @server has root location, is running and is activated

static const int internalServerError = 500
// Internal Server Error(500) at_find_api internal error

static const int badGateway = 502
// Bad Gateway(502) @root server is down

static const int methodNotAllowed = 405
// Method Not Allowed(405) only GET and HEAD are allowed
```


