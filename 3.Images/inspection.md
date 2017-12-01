# Inspection d'images

Dans ce lab, nous allons aller un peu plus en détail dans la composition des images. Vous réaliserez ce lab sur l'installation local que vous avez réalisé au début du cours.

La commande inspect est disponible sur l’ensemble des primitives Docker (container, image, volume, …) et permet d’avoir une vue détaillée d’un élément à partir de son nom ou de son ID. Nous allons voir cela sur l’image alpine.

Nous téléchargeons dans un premier temps l’image alpine avec la commande pull.

```
$ docker image pull alpine
```

Nous pouvons ensuite l’inspecter avec la commande inspect.

```
$ docker image inspect alpine
```

Cette commande renvoie de nombreuses information sur:

* les layers qui composent l’image
* le driver utilisé pour le stockage de ces layers
* l’architecture / os sur laquelle cette l’image a été créée
* des metadata de l’image
* ...

Souvent, nous n’aurons besoin que d’un sous ensemble de l’information renvoyée par la commande inspect, parfois même d’un seul champ. Pour cela, nous pouvons utiliser les Go templates qui permettent d’extraire des informations précises de la structure json.

Par exemple, la commande suivante permet de récupérer la liste des layers de l’image. Celle ci est disponible sous la clé Layers de RootFS.

```
$ docker inspect --format "{{ json .RootFS.Layers }}" alpine | python -m json.tool
```

Il n’y en a qu’une seule dans une image alpine.

```
[
    "sha256:60ab55d3379d47c1ba6b6225d59d10e1f52096ee9d5c816e42c635ccc57a5a2b"
]
```

La commande suivante permet de récupérer l’architecture pour laquelle l’image a été créée.

```
$ docker inspect --format "{{ .Architecture }}" alpine
amd64
```

Je vous encourage à jouer avec les Go templates en repérant des informations dans le résultat renvoyé par la commande inspect et en essayant de les retrouver avec ce formalisme.

## Exploration du filesystem

Avant de regarder plus en détails comment les images sont sauvegardées sur le disque, nous supprimons les containers et images que nous avons crées précédemment.

```
$ docker container stop $(docker container ls -aq)
$ docker container rm $(docker container ls -aq)
$ docker image rm $(docker image ls -q)
```

Note: sur des systèmes Linux, le répertoire d’installation par défaut est /var/lib/docker.

**Attention**

Si vous utilisez Docker for Mac ou Docker for Windows, la plateforme Docker est installée dans une machine virtuelle tournant sur un hyperviseur léger (xhyve pour macOS, Hyper-V pour Windows). Il vous faudra utiliser la commande suivante pour accéder à un shell dans cette machine virtuelle.

```
docker run -it --privileged --pid=host debian nsenter -t 1 -m -u -n -i sh 
```

Dans les grandes lignes, cette commande permet de lancer un shell dans un container basé sur debian, et faire en sorte d'utiliser les namespaces de la machine hôte (la machine virtuelle) sur laquelle tourne le daemon Docker.

Nous reviendrons en détails sur cette commande dans une prochaine leçon.

Une fois que vous avez lancé ce container, vous pourrez alors utiliser les commande Docker comme vous les utilisiez depuis votre machine hôte (masOS ou Windows) mais vous pourrez en plus naviguer dans le filesystem où les images sont stockées.


## Driver de stockage


Dans le cas de Docker for Mac, le driver de storage est overlay2, le sous-répertoire /var/lib/docker/overlay2 est utilisé pour le stockage des layers des images et containers. En fonction de votre système, il est possible qu'un autre driver soit utilisé (par exemple aufs), dans ce cas, vous devrez utiliser ce driver au lieu de overlay2 dans les commandes qui suivent.

Vérifions le contenu du répertoire /var/lib/docker/overlay2 

```
$ ls /var/lib/docker/overlay2
```

Comme il n’y a pas d’image, ni de container, ce répertoire est vide. Nous allons commencé par télécharger une image nginx. Cette commande montre que l’image nginx est composée de 3 layers.

```
$ docker image pull nginx
Using default tag: latest
latest: Pulling from library/nginx
ff3d52d8f55f: Pull complete
226f4ec56ba3: Pull complete
53d7dd52b97d: Pull complete
Digest: sha256:41ad9967ea448d7c2b203c699b429abe1ed5af331cd92533900c6d77490e0268
Status: Downloaded newer image for nginx:latest
```

Regardons à nouveau dans le répertoire /var/lib/docker/overlay2

```
$ ls /var/lib/docker/overlay2
```

Il y a maintenant 3 sous-répertoires présents, chacun correspondant à une layer de l’image.

```
36866d46b60a78f86ed54d4e1cc6cf0e532f0b46b59df3087f60084bd3f3149b
82fc9bf5367b3004770741e6ab64936310389b6a2af87e290b70d4b82cb44dbf
847e49993567ce182b60271c5fc66d179d14ba8a0f48ef0c4edcca3bb48a5f01
backingFsBlockDev
l
```

Lorsqu’elles sont mergées ensemble, ces layers constituent le filesystem de l’image.

Lançons un container basé sur nginx que nous appelons www.

```
$ docker container run -d --name www nginx
```

Deux nouveaux répertoires ont été crées dans /var/lib/docker/overlay2. Ils correspondent à la layer read-write créée avec le container www.

```
36866d46b60a78f86ed54d4e1cc6cf0e532f0b46b59df3087f60084bd3f3149b
82fc9bf5367b3004770741e6ab64936310389b6a2af87e290b70d4b82cb44dbf
847e49993567ce182b60271c5fc66d179d14ba8a0f48ef0c4edcca3bb48a5f01
backingFsBlockDev
**ca8cf66f56c1dd80d84943cebc339895d8917ae83d3f5e3e9d9aea0bfb75bc61**
**ca8cf66f56c1dd80d84943cebc339895d8917ae83d3f5e3e9d9aea0bfb75bc61-init**
l
```

La commande suivante crée le fichier MYFILE dans le container www. Nous utilions pour cela exec qui permet de lancer un processus dans un container existant.

```
$ docker container exec www touch MYFILE
```

Le fichier crée est visible dans la layer du container comme le montre la commande suivante.

```
$ find /var/lib/docker/overlay2 -name MYFILE
/var/lib/docker/overlay2/ca8cf66f56c1dd80d84943cebc339895d8917ae83d3f5e3e9d9aea0bfb75bc61/diff/MYFILE
/var/lib/docker/overlay2/ca8cf66f56c1dd80d84943cebc339895d8917ae83d3f5e3e9d9aea0bfb75bc61/merged/MYFILE
```

Si nous arrêtons le container www, la layer propre au container, et donc les changements effectués dans le container, sont toujours présent.

```
$ docker container stop www
$ find /var/lib/docker/overlay2 -name MYFILE
/var/lib/docker/overlay2/ca8cf66f56c1dd80d84943cebc339895d8917ae83d3f5e3e9d9aea0bfb75bc61/diff/MYFILE
```

Par contre, si l’on supprime le container, la layer du container est supprimée en même temps et avec elle les modifications effectuées.

```
$ docker container rm www
$ ls /var/lib/docker/overlay2
36866d46b60a78f86ed54d4e1cc6cf0e532f0b46b59df3087f60084bd3f3149b
82fc9bf5367b3004770741e6ab64936310389b6a2af87e290b70d4b82cb44dbf
847e49993567ce182b60271c5fc66d179d14ba8a0f48ef0c4edcca3bb48a5f01
backingFsBlockDev
l
```

