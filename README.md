1) Execute install.sh script. This will install machine-status script in /usr/local/bin directory.
2) Make sure /usr/local/bin is in your $PATH
3) It support following commands,
```sh
   $ machine-status                             -- Show current status
   $ machine-reserve < name | email | phone >   -- Reserve the machine. Arguments are optional.
   $ machine-release                            -- Release from reservation
   $ machine-report                             -- Display simple text report
```

Here is an output from machine-status command.
```console
$ machine-status

################################################################################


              ****************************************

              *    Available
              *    Thu Mar 26 11:29:08 PM UTC 2026

              ****************************************



Commands:
    $ machine-status                -- To check machine status.
    $ machine-reserve <Name|email>  -- To reserve.
    $ machine-release               -- To release
    $ machine-report                -- Simple text report

Note:
    ** If reserved, contact current owner before reserving or using it.

```
