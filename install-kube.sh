#! /bin/bash
#######################################################################################################################################
# Programa .....: install-kube.sh
# Versão .......: 1.0
# Descrição ....: Executa o processo de instalação do Kubernetes (01 Control Plane / 02 Workers)
# Data Criação .: 07/02/2023
# Atualização ..:
#######################################################################################################################################
set +x
clear
functionBanner()
{
    clear
    echo   "+--------------------------------------------------------------------------------------------+"
    echo   "|                                                                                            |"
    printf "|$(tput bold) %-90s $(tput sgr0)|\n" "$@"
    echo   "|                                                                                            |"
    echo   "+--------------------------------------------------------------------------------------------+"
}

echo "    _    ____ __  __ _____                            _  _____ ____  "
echo "   / \  / ___|  \/  | ____|  ___  _ __ __ _          | |/ ( _ ) ___| "
echo "  / _ \| |   | |\/| |  _|   / _ \| \'__/ _\` | _____  | ' // _ \___ \ "
echo " / ___ \ |___| |  | | |___ | (_) | | | (_| | |_____| | . \ (_) |__) |"
echo "/_/   \_\____|_|  |_|_____(_)___/|_|  \__, |         |_|\_\___/____/ "
echo "                                      |___/                          "
echo "                                             Kubernetes - Single Node"

#echo "  ____              ____  ____  _               _  _____ ____   "
#echo " |  _ \ _   _ _ __ |___ \| __ )(_)____         | |/ ( _ ) ___|  "
#echo " | |_) | | | | '_ \  __) |  _ \| |_  /  _____  | ' // _ \___ \  "
#echo " |  _ <| |_| | | | |/ __/| |_) | |/ /  |_____| | . \ (_) |__) | "
#echo " |_| \_\\__,_ |_| |_|_____|____/|_/___|         |_|\_\___/____/  "
#echo ""
#echo "                                        Kubernetes - Single Node"
sleep 5

# Teste de conectividade do Server Ansible com as VMs
hosts=(brspappcp01 brspappwk01 brspappwk02)
functionBanner "Testando conectividade com todos os Servidores..."
for host in "${hosts[@]}"; do
  ping -c 3 "$host" &> /dev/null
  if [ $? -eq 0 ]; then
    echo "$host está alcançavel."
  else
    echo "$host não está alcançavel."
    echo "Um ou mais Servidores não foram alcançados, verifique as configurações de /etc/hosts ou outras configurações"
    exit 1
  fi
done
sleep 3

functionBanner "Instalando HELM/KUBECTL no ANSIBLE"
/usr/bin/which kubectl &> /dev/null
if [ $? = 1 ]; then # Não está instalado
  cd /var/tmp || exit
  curl -LO https://dl.k8s.io/release/v1.25.5/bin/linux/amd64/kubectl &> /dev/null
  if [ -f "/var/tmp/kubectl" ]; then
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  fi
fi
/usr/bin/which helm &> /dev/null
if [ $? = 1 ]; then
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash &> /dev/null
fi
/usr/bin/which ansible &> /dev/null
if [ $? = 1 ]; then
  yes | apt install ansible -y &> /dev/null
fi
sleep 3

functionBanner "Ajustando HAPROXY/ANSIBLE"
#scp -i /root/.ssh/ansible_automacao /storage/automacao/configs/hosts root@brspappha01:/etc/hosts
cp -Rap /storage/automacao/configs/hosts /etc/hosts
sleep 3

functionBanner "Copiando scripts essenciais pré instalação ..."
/usr/bin/ansible-playbook -i /storage/automacao/ansible-files/kban-inventory-file /storage/automacao/ansible-files/01-kban-copy-scripts.yaml
sleep 3

functionBanner "Instalando o Chrony nos Servidores ..."
/usr/bin/ansible-playbook -i /storage/automacao/ansible-files/kban-inventory-file /storage/automacao/ansible-files/02-kban-install-chrony.yaml
sleep 3

functionBanner "Copiando hosts para os Servidores ..."
/usr/bin/ansible-playbook -i /storage/automacao/ansible-files/kban-inventory-file /storage/automacao/ansible-files/03-kban-copy-hosts.yaml
sleep 3

functionBanner "Instalando módulos Kernel e ContainerD ..."
/usr/bin/ansible-playbook -i /storage/automacao/ansible-files/kban-inventory-file /storage/automacao/ansible-files/04-kban-install-containerd-modkernel.yaml
sleep 3

functionBanner "Instalando kubeadm, kubectl e kubelet ..."
/usr/bin/ansible-playbook -i /storage/automacao/ansible-files/kban-inventory-file /storage/automacao/ansible-files/05-kban-install-kube-ctl-adm-let.yaml
sleep 3

functionBanner "Inicializando o Cluster Kubernetes ..."
/usr/bin/ansible-playbook -i /storage/automacao/ansible-files/kban-inventory-file /storage/automacao/ansible-files/06-kban-start-k8s.yaml

functionBanner "Copiando arquivo config do Cluster para o Ansible ..."
mkdir -p /root/.kube/ &> /dev/null
/usr/bin/scp -i /root/.ssh/ansible_automacao root@brspappcp01:/etc/kubernetes/admin.conf /root/.kube/config &> /dev/null
if [ $? -eq 1 ]; then
  echo "Não foi possível copiar o arquivo /etc/kubernetes/admin.conf."
  echo "Sem ele, não será possível acesso ao Cluster tão pouco a conclusão da instalação."
else
  functionBanner "Exportando KUBECONFIG..."
  export KUBECONFIG=~/.kube/config
  sleep 3

  functionBanner "Teste de conectividade com o Cluster Kubernetes ..."
  /usr/local/bin/kubectl get nodes
  sleep 3
  if [ $? -eq 1 ]; then
    echo "Não foi possível testar a conectividade com o Cluster"
    exit 1
  else
    functionBanner "Alterando Labels dos Workers Nodes ..."
    /usr/local/bin/kubectl label node brspappwk01 node-role.kubernetes.io/worker-node= &> /dev/null
    /usr/local/bin/kubectl label node brspappwk02 node-role.kubernetes.io/worker-node= &> /dev/null
    /usr/local/bin/kubectl get nodes
    sleep 3

    functionBanner "Instalando o Ingress Controller no Cluster Kubernetes ..."
    /usr/local/bin/kubectl apply -f /storage/automacao/kubernetes-files/nginx-ingress.baremetal.yaml

    functionBanner "Instalando o Longhorn no Cluster Kubernetes ..."
    /usr/local/bin/helm repo add longhorn https://charts.longhorn.io &> /dev/null
    /usr/local/bin/helm repo update &> /dev/null
    /usr/local/bin/helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace --values /storage/automacao/kubernetes-files/longhorn-values.yaml

    functionBanner "Instalando o Dashboard no Cluster Kubernetes ..."
    /usr/local/bin/kubectl apply -f /storage/automacao/kubernetes-files/kubernetes-dashboard.yaml

    functionBanner "Aguardando a inicialização de todos os pods ..."
    found=false
    if [ ! -f /var/tmp/total.log ];
    then
      echo "1" > /var/tmp/total.log
    else
      echo "1" > /var/tmp/total.log
    fi
    while [ "$found" = false ]
    do
      while read line
      do
        num=$(echo $line | awk '{print $1}')
        if [ "$num" -gt 40 ]; then
          functionBanner "Cluster KUBERNETES pronto pra uso!!!"
          found=true
          break
        fi
        clear
        echo ""
        echo " Total de PODs prontos: $line de 40 "
        echo ""
      done < /var/tmp/total.log
      if [ "$found" = false ]; then
        /usr/local/bin/kubectl get po -A | egrep "Running|Completed" | wc -l > /var/tmp/total.log
        /usr/local/bin/kubectl get po -A -o wide | egrep -v "Running|Completed"
        sleep 5
      fi
    done

    ###
    # Join New ControlPlane
    functionBanner "Gerando o arquivo de ingresso para novos ControlPlanes ..."
    /usr/bin/ansible-playbook -i /storage/automacao/ansible-files/kban-inventory-file /storage/automacao/ansible-files/08-kban-gen-join-cplanes.yaml
    sleep 3

    functionBanner "Para acesso ao Cluster a partir do outro computador (Linux), siga os passos abaixo:"        \
                   "mkdir -p \$HOME/.kube"                                                                      \
                   "scp -i ~/.ssh/ansible_automacao root@brspappcp01:/etc/kubernetes/admin.conf ~/.kube/config" \
                   "sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config"                                         \
                   ""                                                                                           \
                   "Instale o kubectl seguindo a documentacao oficial do Kubernetes"                            \
                   "https://kubernetes.io/docs/tasks/tools/"                                                    \
                   ""                                                                                           \
                   "Acesso para a interface do Longhorn"                                                        \
                   "http://longhorn.acme.org:30000/"                                                            \
                   ""                                                                                           \
                   "Para mais detalhes do Longhorn, visite a documentacao."                                     \
                   "https://longhorn.io/docs/"                                                                  \
                   ""                                                                                           \
                   "Acesse o Dashboard do Kubernetes"                                                           \
                   "http://dashboard.acme.org:30001/"                                                           \
                   ""                                                                                           \
                   "Para gerar o token de acesso ao Dashboard, siga os passos abaixo:"                          \
                   "kubectl -n kubernetes-dashboard create token sysadmin"                                      \
                   ""                                                                                           \
                   "Para testar seu Cluster, execute o comando abaixo a partir do Servidor Ansible"             \
                   "Sera criado um Volume dinamicamente no Longhorn e um deploy do mongodb"                     \
                   "kubectl apply -f /storage/automacao/exemplos/example-deploy-svc-pvc-ns_mongo-mongo.yaml"    \
                   ""                                                                                           \
                   "Para verificar se o deploy ocorreu com sucesso"                                             \
                   "kubectl get all -n mongo -o wide"                                                           \

  fi
fi