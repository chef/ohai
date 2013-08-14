## Terms

##### Command

The command being executed.  Example:

    ls -l

Here, "ls" is the command.

##### Parameters

The parameters provided to the command.  Example:

    python -c "import sys; print sys.version"

Here, '-c "import sys; print sys.version"' are the parameters.

##### Platform

The platform is a human readable name for the operating system plus version.

For example, I am currently using a computer running OS X 10.8.4.  I might set the platform to osx-10.8.

##### Arch

The architecture is a human readable name for the processor architecture of the computer.

For example, I am currently using a computer with an Intel Core i7 processor.  I might set the arch to x64.

##### Env

The environment is a human readable list of strings, describing the current state of the system.

For example, if I made sure to install python and ruby before executing a command, I might set the env to ["python", "ruby"].

In general, you should only add a string to env if it affects the execution of the command.

## Collecting Data

Run the get_output.rb command to collect data.  Both "parameters" and "env" are comma separated lists of strings.  If any of the parameters begins with the "-" character, that parameter needs to be adjacent to its flag, as in the example:

    ruby get_output.rb -c python -p'-c "import sys; print sys.version"' -f "osx-10.8.4" -a x64 -e python

One thing to note: -p is a comma separated list of strings.  Each string will be treated as a complete set of parameters and run individually.  For example

    ruby get_output.rb -c ls -p',-l' -f "osx-10.8" -a x64 -e

Would cause get_output.rb to collect the output of both "ls" and "ls -l".

## Adding data to the library

To add data to the library, copy the output of the get_output.rb command to the file named <command>.output in the ohai/spec/data/plugins directory.  For example, if I collected data using the command

    ruby get_output.rb -c ls -p',-l' -f "osx-10.8" -a x64 -e

I would copy the output and paste it to the end of the ls.output file in ohai/spec/data/plugins.  If there is no ls.output file, create one.