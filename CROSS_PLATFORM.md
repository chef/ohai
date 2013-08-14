### Terms

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

### Collecting Data

Run the get_output.rb command to collect data.

