#!/bin/bash

# suppres fd leaks messsages 
echo "export LVM_SUPPRESS_FD_WARNINGS=1" >> /etc/environment
echo "export LVM_SUPPRESS_FD_WARNINGS=1" >> /etc/profile
