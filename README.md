# Projeto de Instalação Automática de um Cluster Kubernetes

VirtualBox (Pode-se utilizar outros virtualizadores, porém, achei mais simples com esse);
-	Necessário adicionar uma nova rede no VirtualBox.
  
    ![image](https://github.com/cleston74/automacao/assets/42645665/ad125c37-db16-4ae0-b382-7fda07b3e032) ![image](https://github.com/cleston74/automacao/assets/42645665/42bc5090-bc96-46cc-aa82-f0f823dcb51a)

IP fixo em todos os servidores, conforme diagrama abaixo;

  ![image](https://github.com/cleston74/automacao/assets/42645665/1096bf80-7dcf-41b0-b59f-b0a52d70d627)

*** O IP 192.168.0.X é a sua rede 

Descrição dos Servidores:
Servidor: BRSPAPPFW01
Sistema Operacional: FreeBSD
CPU: 1 vCPU
Memória: 1 GB
HD: 10GB
IP1: 192.168.99.254
IP2: 192.168.0.10 [Configuração DHCP de sua rede]
Papel: Este servidor tem a característica de prover papel de Firewall, Gateway e DNS do Laboratório.
Placa de rede 1: configurada como DHCP com saída para internet
Placa de rede 2: configurada com IP fixo no barramento 192.168.99.X

Servidor: BRSPAPPAN01
Sistema Operacional: Ubuntu Server 22.04
CPU: 1 vCPU
Memória: 1GB
HD: 10 GB
IP: 192.168.99.199
Papel: Este servidor será usado para realizar toda configuração e ajustes nos Servidores para a correta instalação do Kubernetes.

Servidor: BRSPAPPCP01
Sistema Operacional: Ubuntu Server 22.04
CPU: 4 vCPU
Memória: 4 GB
HD: 60 GB
IP: 192.168.99.200
Papel: Servidor de Control Plane

Servidor: BRSPAPPWK01
Sistema Operacional: Ubuntu Server 22.04
CPU: 4 vCPU
Memória: 3 GB
HD: 60 GB
IP: 192.168.99.205
Papel: Servidor worker-node

Servidor: BRSPAPPWK02
Sistema Operacional: Ubuntu Server 22.04
CPU: 4 vCPU
Memória: 3 GB
HD: 60 GB
IP: 192.168.99.206
Papel: Servidor worker-node

Acesso SSH configurado com chave;
->	Para gerar sua chave SSH, execute o comando abaixo em seu Servidor ansible (BRSPAPPAN01)
      ssh-keygen -t rsa -b 2048
      *** Salve com o nome de “ansible_automacao” no diretório /root/.ssh

o	Para copiar sua chave SSH para os demais servidores, execute o comando abaixo:
	ssh-copy-id -i /root/.ssh/ansible_automacao.pub root@brspappXXXX
*** Altere XXXX para o nome correto do Servidor

o	Executar um primeiro acesso da máquina Ansible (BRSPAPPAN01) ao Control Plane (BRSPAPPCP01) e a cada Worker Node (BRSPAPPWK01 e BRSPAPPWK02).
	ssh -i /root/.ssh/ansible_automacao root@brspappXXXX
*** Altere XXXX para o nome correto do Servidor

	Defina o hostname de cada Servidor com o comando abaixo:
	hostnamectl set-hostname brspappXXXX
*** Altere XXXX para o nome correto do Servidor (vide diagrama)

	Defina o IP para cada Servidor editando o arquivo 00-installer-config.yaml (o nome pode variar de acordo com a versão do sistema operacional) que está no diretório /etc/netplan
	vim /etc/netplan/00-installer-config.yaml
Ajustar de acordo com arquivo abaixo:

# This is the network config written by 'subiquity'
network:
  ethernets:
    enp0s3:
      addresses:
      - 192.168.99.200/24
      nameservers:
        addresses:
        - 192.168.99.254
        search:
        - acme.org
      routes:
      - to: default
        via: 192.168.99.254
  version: 2

	netplan try
 
Tecle [ENTER] se não ocorrer nenhum erro.

	Desabilite o swap editando o arquivo fstab
	vim /etc/fstab
 
*** Reiniciar para que todas as alterações tenham efeito.

	Executar um teste de conectividade para certificar que todas as máquinas tenham saída para internet, um simples “ping” já é o suficiente;
 

	Esse laboratório utiliza Linux Ubuntu Server versão 22.04, onde o usuário root não vem habilitado por padrão, logo, será necessário habilitar em todos os Servidores.
o	sudo su -
o	passwd
	Defina a nova senha do root

	Garantir que os Sistemas Operacionais estejam atualizados.
o	apt update && apt -y upgrade && apt autoremove && apt autoclean

Instalação.
	De seu Servidor Ansible (BRSPAPPAN01), executar os comandos abaixo:
o	mkdir -p /storage/
o	cd /storage/
o	git clone https://github.com/cleston74/automacao.git
o	Copiar o conteúdo do arquivo /storage/automacao/configs/hosts para o /etc/hosts
o	cd /storage/automacao
o	chmod +x install-kube.sh
o	time ./install-kube.sh

*** O tempo de instalação pode variar de acordo com sua internet e performance de seu laboratório.


