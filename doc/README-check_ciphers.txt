This is a very small script that checks the installed cipher suite on 
this device against a remote web-server. If a Match is found it will 
report a success, if failed a failure will be registered. At the end of 
the Check, a logfile will be created separating supported ciphers with 
non supported ciphers by the remote web-server.

Note - if executed from the TIM, the compatible ciphers of the openssl 
library used by the TIM will be checked against the openssl library (or 
similar) of the provided remote server address.
