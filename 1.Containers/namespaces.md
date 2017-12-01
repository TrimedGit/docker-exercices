Nous allons illustrer ici la création de namespace avec l'utilitaire unshare.

Avant de commencer:
* si vous êtes sur Linux, vous pouvez commencer à suivre les instructions directement.
* si vous n'êtes pas sur Linux mais sur macOS ou Windows, vous pouvez lancer une machine virtuelle grace à Vagrant de HashiCorp et VirtualBox.
  * VirtualBox peut être téléchargé depuis [https://www.virtualbox.org/wiki/Downloads](https://www.virtualbox.org/wiki/Downloads)
  * Vagrant peut être téléchargé depuis [https://www.vagrantup.com/downloads.html](https://www.vagrantup.com/downloads.html)

Une fois VirtualBox et Vagrant téléchargés et installés, il vous suffira de créer un répertoire et de lancer les commandes suivantes depuis celui-ci. Cela vous permettra d'avoir accès à un shell sur une machine virtuelle Ubuntu tournant sur VirtualBox:

```
$ vagrant init hashicorp/trusty64
$ vagrant up
$ vagrant ssh
```

> Il y a bien sur différentes façons de lancer une VM basée sur Ubuntu, Vagrant/Virtualbox en est une parmi d'autres. N'hésitez pas à utiliser une autre méthode si vous le souhaitez.

## Les namespaces

L’utilisation des namespaces permet de limiter la vision du système qu’à un processus. Cette mise en pratique montre des exemples d’utilisation de la commande unshare pour exécuter des processus dans des nouveaux namespaces.


### Illustration du namespace Network

La commande suivante liste les interfaces réseau locales

```
vagrant@trusty64:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 16436 qdisc noqueue state UNKNOWN
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 08:00:27:88:0c:a6 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global eth0
    inet6 fe80::a00:27ff:fe88:ca6/64 scope link
       valid_lft forever preferred_lft forever
```

Nous utilisons l’option -n de unshare pour lancer un process sh dans un nouveau namespace network.

```
vagrant@trusty64:~$ sudo unshare -n sh
```

Seul l’interface réseau local est disponible dans ce namespace.

```
# ip a
4: lo: <LOOPBACK> mtu 16436 qdisc noop state DOWN
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
```

La commande suivante permet de sortir du namespace.

```
# exit
```

### Illustration du namespace IPC (Inter-process communication)

Nous créons une file de message avec la commande suivante

```
vagrant@trusty64:~$ ipcmk -Q
Message queue id: 0
```

La commande suivante liste les files de messages existantes.

```
vagrant@trusty64:~$ ipcs -q

------ Message Queues --------
key        msqid      owner      perms      used-bytes   messages
0x3d565006 0          vagrant    644        0            0
```

Nous utilisons l’option -i de unshare pour lancer un processus sh dans un nouveau namespace IPC

```
vagrant@trusty64:~$ sudo unshare --ipc sh
```

La commande suivante liste les files de messages dans le nouveau namespace.

```
# ipcs -q

------ Message Queues --------
key        msqid      owner      perms      used-bytes   messages
```

Cette liste est vide car nous sommes dans un namespaces IPC différents de celui du process initial.

Nous sortons alors du namespace avec la commande suivante.

```
# exit
```
