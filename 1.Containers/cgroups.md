Cet exercice montre l’utilisation des cgroups pour limiter la mémoire allouée à un processus.

## Prérequis

Nous allons commencer par lancer une VM basé sur la distribution Alpine Linux, grace à Vagrant de HashiCorp et VirtualBox.
  * VirtualBox peut être téléchargé depuis [https://www.virtualbox.org/wiki/Downloads](https://www.virtualbox.org/wiki/Downloads)
  * Vagrant peut être téléchargé depuis [https://www.vagrantup.com/downloads.html](https://www.vagrantup.com/downloads.html)

Une fois VirtualBox et Vagrant téléchargés et installés, il vous suffira de créer un répertoire et de lancer les commandes suivantes depuis celui-ci. Cela vous permettra d'avoir accès à un shell sur une machine virtuelle Alpine tournant sur l'hyperviseur VirtualBox:

```
$ vagrant plugin install vagrant-alpine
$ vagrant init generic/alpine36
$ vagrant up
$ vagrant ssh
```

> Il y a bien sur différentes façons de lancer une VM basée sur Ubuntu, Vagrant/Virtualbox en est une parmi d'autres. N'hésitez pas à utiliser une autre méthode si vous le souhaitez

## Liste des cgroups présents

La commande suivante liste les cgroups que nous pouvons utiliser afin d’imposer des contraintes d’utilisation de resources à un processus.

```
$ ls /sys/fs/cgroup
blkio       cpuacct     devices     hugetlb     net_cls     openrc      pids
cpu         cpuset      freezer     memory      net_prio    perf_event
```

Dans l’exemple suivante nous allons nous focaliser sur le cgroups memory afin d’imposer une limite maximale de RAM.

## Création d’un cgroups mémoire

```
$ sudo mkdir /sys/fs/cgroup/memory/my_group
```

> /sys/fs/cgroups/memory est un speudo filesystem. La création du répertoire my_group créé automatiquement les sous répertoires suivante

```
$ ls /sys/fs/cgroup/memory/my_group
cgroup.clone_children               memory.limit_in_bytes
cgroup.event_control                memory.max_usage_in_bytes
cgroup.procs                        memory.move_charge_at_immigrate
memory.failcnt                      memory.oom_control
memory.force_empty                  memory.pressure_level
memory.kmem.failcnt                 memory.soft_limit_in_bytes
memory.kmem.limit_in_bytes          memory.stat
memory.kmem.max_usage_in_bytes      memory.swappiness
memory.kmem.tcp.failcnt             memory.usage_in_bytes
memory.kmem.tcp.limit_in_bytes      memory.use_hierarchy
memory.kmem.tcp.max_usage_in_bytes  notify_on_release
memory.kmem.tcp.usage_in_bytes      tasks
memory.kmem.usage_in_bytes
```

## Limite d’utilisation de la RAM

Afin d’imposer une limite d’utilisation de la RAM, nous settons le champ memory.limit_in_bytes à 20M

```
$ sudo su -
# echo -n 20M > /sys/fs/cgroup/memory/my_group/memory.limit_in_bytes
```

Vérifions que la limite a bien été settée:

```
$ cat /sys/fs/cgroup/memory/my_group/memory.limit_in_bytes
20971520
```

## Création d’un processus de test

Le processus suivant va consommer de plus en plus de RAM avec le temps

```
A="A"; while true; do A="$A$A$A"; sleep 3; done &
[1] 151
```

## Ajout du processus dans my_group
 
Nous ajoutons le PID du processus précédent (151 dans cet exemple) dans le group my_group afin que ce dernier soit contraint par la limite max de RAM. Note: comme nous avons lancé le processus en background, nous récupérons son PID avec la variable $!.

```
# echo -n $! > /sys/fs/cgroup/memory/my_group/tasks
```

## Suivi de l’utilisation de la RAM

La commande suivante permet de suivre l’évolution de l’utilisation de la RAM.

```
$ watch tail /sys/fs/cgroup/memory/my_group/memory.usage_in_bytes
Every 2s: tail /sys/fs/cgroup/memory/my_group/memory.usage_in_bytes 2017-06-18 05:32:25
20971520
```

Au bout de quelques secondes, le niveau d’utilisation de la RAM n’augmente plus, le processus étant contraint par la limite imposée dans le cgroups my_group.

> il est nécessaire de faire un CTRL-C dans le terminal afin de sortir du processus watch lancé ci-dessus.
