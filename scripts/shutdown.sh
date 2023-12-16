#######################################################################################################################################
# Programa .....: shutdown.sh
# Versão .......: 1.0
# Descrição ....: Desliga o ambiente KUBERNETES
# Data Criação .: 27/02/2023
# Atualização ..:
#######################################################################################################################################
set +x
clear
functionBanner()
{
    clear
    echo   "+--------------------------------------------------------------+"
    echo   "|                                                              |"
    printf "|`tput bold` %-60s `tput sgr0`|\n" "$@"
    echo   "|                                                              |"
    echo   "+--------------------------------------------------------------+"
}

functionBanner "Desligando o ambiente KUBERNETES" " " "Desligue posteriormente o ANSIBLE/FIREWALL"
sleep 5

functionBanner "Desligando Servidor BRSPAPPCP01"
ssh -i /root/.ssh/ansible_automacao root@brspappcp01 init 0 &> /dev/null
functionBanner "Desligando Servidor BRSPAPPCP02"
ssh -i /root/.ssh/ansible_automacao root@brspappcp02 init 0 &> /dev/null
functionBanner "Desligando Servidor BRSPAPPCP03"
ssh -i /root/.ssh/ansible_automacao root@brspappcp03 init 0 &> /dev/null
functionBanner "Desligando Servidor BRSPAPPWK01"
ssh -i /root/.ssh/ansible_automacao root@brspappwk01 init 0 &> /dev/null
functionBanner "Desligando Servidor BRSPAPPWK02"
ssh -i /root/.ssh/ansible_automacao root@brspappwk02 init 0 &> /dev/null
functionBanner "Desligando Servidor BRSPAPPHA01"
ssh -i /root/.ssh/ansible_automacao root@brspappha01 init 0 &> /dev/null

