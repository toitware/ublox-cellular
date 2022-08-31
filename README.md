# U-blox cellular
Drivers for u-blox cellular modems.

This repository contains drivers for the following modems:
- Sara R4
- Sara R5

## Using the driver as a service
The easiest way to use the module is to install it in a separate container 
and let it provide its network implementation as a service.

You can install the service through Jaguar:

``` sh
jag container install cellular-sara_r5 src/sara_r5.toit
```

and then run the [example](examples/sara_r5.toit):

``` sh
jag run examples/sara_r5.toit
```

Remember to install the package dependencies through `jag pkg install` in the 
root and `examples/` directories.
