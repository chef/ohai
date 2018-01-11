# Ohai Release Notes:

## 8.26

### EC2 detection on C5/M5

Ohai now provides EC2 metadata configuration information on the new C5/M5 instance types running on Amazon's new hypervisor.

### LsPci Plugin

The new LsPci plugin provides a `node[:pci]` hash with information about the PCI bus based on `lspci`. Only runs on Linux.
