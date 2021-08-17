# PhoneCat
Query and print phone information from SimpleMDM.
Currently only supports printing in CSV format.

## Usage

Compile PhoneCat and print usage:

```
swift run PhoneCat -h
```

You must fetch your API token from SimpleMDM to use PhoneCat.  For example, the following prints all device groups on SimpleMDM:

```
swift run PhoneCat groups --token=12345
```

