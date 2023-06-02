Quick deployment: 


|   Script   |                                                  Deploymenmt                                                      |
|------------|-------------------------------------------------------------------------------------------------------------------|
|Podman      |```curl https://raw.githubusercontent.com/FluffyContainers/deployment/master/src/podman.sh 2>/dev/null \| bash```  |
|OhMyPosh    |```curl https://raw.githubusercontent.com/FluffyContainers/deployment/master/src/posh.sh 2>/dev/null \| bash```    |
|SSHD *beta* |```curl https://raw.githubusercontent.com/FluffyContainers/deployment/master/src/sshd.sh 2>/dev/null \| bash```    |
|VXLAN.      |```curl https://raw.githubusercontent.com/FluffyContainers/deployment/master/src/vxlan.sh 2>/dev/null \| bash```   |
|System base |```curl https://raw.githubusercontent.com/FluffyContainers/deployment/master/src/system.sh 2>/dev/null \| bash```  |




Fedora Server
--
Error: "Leaked file identifier......"

Solution: 
```
echo "export LVM_SUPPRESS_FD_WARNINGS=1" >> /etc/environment
echo "export LVM_SUPPRESS_FD_WARNINGS=1" >> /etc/profile
```
