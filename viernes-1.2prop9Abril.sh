#!/bin/bash 

#===============================================================
#Developed by Carlos Sanchez WYMX
#Propuesta de la aplicacion: 15 de Enero del 2025
#Inicio de desarrollo: 26 de Enero del 2025
#Liberacion de version personal: 6 de Febrero del 2025
#Pruebas iniciadas para KAIZEN 01 de Marzo del 2025
#Version inicial operando desde el 06 de Febrero
#Version para KAIZEN liberada en CLUSTER 4 el 06 de Marzo del 2025
#Migracion a carpeta MFG el 27 de Marzo del 2025 para KAIZEN de Sebastian Romero | Guia para Principiantes
#Revision y aprobacion el 30 de Marzo del 2025 en TE Room 
#===============================================================
#GNW Soft
#===============================================================

# Colores para formato
RED='\e[31m'
GREEN='\e[32m'
BLUE='\e[34m'
CYAN='\e[36m'
YELLOW='\e[33m'
LIGHT_PURPLE='\e[38;5;141m'
DARK_BLUE='\e[38;5;18m'
RESET='\e[0m'

# Definir la ruta base
dir_base="/opt/test_tools/teton2/nitro-bmc-cli/"


#Funcion para registrar uso de viernes
registrar_uso() {
    local opcion="$1"
    local sn="$2"
    local ip="$3"
    local archivo_log="/home/MW23090133/gnw/viernesLogs/viernes_uso.csv"
    #local archivo_log="/home/carlos/viernes.csv"

    # Si el archivo no existe, creamos la cabecera
    if [[ ! -f "$archivo_log" ]]; then
        echo "Fecha,Hora,Usuario,Opcion,SN,IP" > "$archivo_log"
    fi

    # Obtener fecha, hora y usuario
    local fecha=$(date +"%Y-%m-%d")
    local hora=$(date +"%H:%M:%S")
    local usuario=$(logname)

    # Registrar datos en el CSV
    echo "$fecha,$hora,$usuario,$opcion,$sn,$ip" >> "$archivo_log"
}


# Función para obtener IP de K2V4 a partir del SN
get_k2v4_ip_from_sn() {
    local sn=$1
    export k2v4_ip=$(getip --extend "$sn" | grep "k2v4_ip" | awk '{print $2}' | sed 's/\x1B\[[0-9;]*m//g' | tr -d '[:space:]\r\n')
}
 
# Función para obtener IP de eth0 del BMC a partir del SN
get_bmc_ip() {
    local sn=$1
    output=$(getip -s "$sn")
    export bmc_ip=$(echo "$output" | awk 'NR==3 {print $5}')   # Columna de BMC
}

#Funcion para realizar debug de funcion para obtener BMC IP debido al error de comunicacion
get_bmc_ip_debug() {
    local sn=$1
    output=$(getip -s "$sn")
    export bmc_ip=$(echo "$output" | awk 'NR==3 {print $5}' | tr -d '[:space:]\r\n')
    #export bmc_ip=$(echo "$bmc_ip" | sed 's/[^0-9.]//g')
}

#Funcion de debug 2 para limpiar codigo de formato ANSI
get_bmc_ip_debug2() {
    local sn=$1
    output=$(getip -s "$sn")

    # Extraer la IP eliminando posibles códigos de color
    export bmc_ip=$(echo "$output" | awk 'NR==3 {print $5}' | sed 's/\x1B\[[0-9;]*m//g' | tr -d '[:space:]\r\n')
}


# Función para obtener IP de eth0 a partir del SN
get_eth0_ip() {
    local sn=$1
    output=$(getip -s "$sn")
    export eth0_ip=$(echo "$output" | awk 'NR==3 {print $7}')  # Columna de ETH0
}

#Funcion de debug de la eth0 IP
get_eth0_ip_debug() {
    local sn=$1
    output=$(getip -s "$sn")
    eth0_ip=$(echo "$output" | awk 'NR==3 {print $7}' | sed 's/\x1b\[[0-9;]*m//g' | tr -d '[:space:]\r\n')
    export eth0_ip
}

#Funcion para obtener IP de los SW data
get_sw_ip() {
    local mac=$1
    output=$(getip -m "$mac")
    export sw_ip=$(echo "$output" | awk '{print $3}' | sed 's/\x1b\[[0-9;]*m//g')
}

# Validar si la ruta existe y acceder a ella
cd "$dir_base" || { echo -e "${RED}Error: No se pudo acceder a $dir_base${RESET}"; exit 1; }

while true; do
    clear
    echo -e "\e[34m __      ___                           "
    echo -e " \ \    / (_)                           "
    echo -e "  \ \  / / _  ___ _ __ _ __   ___  ___ \e[31m"
    echo -e "   \ \/ / | |/ _ \ '__| '_ \ / _ \/ __|"
    echo -e "    \  /  | |  __/ |  | | | |  __/\__ \\"
    echo -e "     \/   |_|\___|_|  |_| |_|\___||___/"
    echo -e "\e[0m"
    echo -e "${CYAN}=============================================${RESET}"
    echo -e "${YELLOW}  MLA/L11 Tool 5to Turno - DEV Carlos Sanchez   ${RESET}"
    echo -e "${LIGHT_PURPLE}================ L11 Tools =================${RESET}"
    echo -e "${GREEN}1) Activar K2V4${RESET}"
    echo -e "${GREEN}2) SW Autoconfig (Lengueta Naranja)${RESET}"
    echo -e "${GREEN}3) Rack Information${RESET}"
    echo -e "${GREEN}4) PCIe Verification${RESET}"
    echo -e "${LIGHT_PURPLE}================ MLA Tools =================${RESET}"
    echo -e "${GREEN}5) Ejecutar UART Tool${RESET}"
    echo -e "${GREEN}6) Verificacion de Proxy Cards${RESET}"
    echo -e "${GREEN}7) Verificacion de K2V5 card type${RESET}"
    echo -e "${GREEN}8) Prueba de Cable Detect ALL Rack${RESET}"
    echo -e "${GREEN}9) Limpiar eventos (SEL Clear)${RESET}"
    echo -e "${GREEN}10) Mostrar Sensor List${RESET}"
    echo -e "${GREEN}11) Sel Clear + VPD${RESET}"
    echo -e "${GREEN}12) Imprimir FRU${RESET}"
    echo -e "${GREEN}13) Verificar BMC Network${RESET}"
    echo -e "${GREEN}14) Clear DHCP + VPD${RESET}"
    echo -e "${GREEN}15) Check IPV4 (getip extend)${RESET}"
    echo -e "${LIGHT_PURPLE}================ Power Status ==============${RESET}"
    echo -e "${GREEN}16) BMC Reboot${RESET}"
    echo -e "${GREEN}17) Sol Activate${RESET}"
    echo -e "${LIGHT_PURPLE}============= Debug Test Failures ==========${RESET}"
    echo -e "${GREEN}18) Issue SDR SMCX_POV9_VIN (EN DESARROLLO)${RESET}"
    echo -e "${LIGHT_PURPLE}================ Others ===================${RESET}"
    echo -e "${GREEN}19) Opnion/Sugerencias de Tools${GREEN}"
    echo -e "${GREEN}20) Node Information | Buscar unidad${GREEN}"
    echo -e "${RED}21) Salir${RESET}"
    echo -e "${CYAN}===========================================${RESET}"
    echo -e "${GREEN}    Last Update: April 10th, 2025${RESET}"
    echo -e "${GREEN}    Operating Since: February 06th, 2025${RESET}"
    echo -e "${CYAN}===========================================${RESET}"
    read -rp "Seleccione una opción: " opcion

    case $opcion in
        1)
        # Activación de K2V4 con validación de IP, manejo de errores y autenticación
            read -rp "Ingrese el SN de la unidad: " SN
            get_k2v4_ip_from_sn "$SN"
            
            if [[ -z "$k2v4_ip" ]]; then
                echo -e "${RED}Error: No se pudo obtener la IP del K2V4. Verifique el SN.${RESET}"
                continue
            fi
            
            read -sp "Ingrese la contraseña para continuar: " password
            echo ""
            if [[ "$password" != "genios" ]]; then
                echo -e "${RED}Error: Contraseña incorrecta. Operación cancelada.${RESET}"
                continue
            fi

            # Registrar uso de la opción 1 en el log
            registrar_uso "1 (Activación de K2V4)" "$SN" "$k2v4_ip"
            
            echo -e "${BLUE}Activando Firmware...${RESET}"
            coap -O65001,0 -Y -m PUT -c '{ actionType = "CardFirmwareEnable", cardFirmwareEnableAction = { targetDevice = "recovery", skipManagedCards = true}}' coaps+tcp://$k2v4_ip/api-v1/host-action/0/action/1 || {
                echo -e "${RED}Error: Falló la activación del firmware.${RESET}"
                continue
            }
            
            echo -e "${BLUE}Verificando si todo salió bien...${RESET}"
            coap -O65001,0 -Y coaps+tcp://$k2v4_ip//api-v1/host-action/0/action/1 || {
                echo -e "${RED}Error: Falló la verificación del firmware.${RESET}"
            }
            ;;
        2)
        #SW autoconfig - Funciona correctamente.
            read -rp "Ingrese el SN del rack : " SN_RACK
            echo -e "${BLUE}Obteniendo informacion del rack ...${RESET}"
            #Generar salida de 
            output_sfc=$(bash /home/MW23090133/gnw/tools/toolsgnw/dbconsult.sh --GetDynamicData --usn="$SN_RACK" --value=DYN_POSITION_FIONA --name=USN)
            
            sw_mac1=$(echo "$output_sfc" | grep "Table19" -A 6 | awk -F '<|>' '/ETH0MAC/ {print $3}')
            sw_mac2=$(echo "$output_sfc" | grep "Table39" -A 6 | awk -F '<|>' '/ETH0MAC/ {print $3}')
            sw_sn1=$(echo "$output_sfc" | grep "Table19" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            sw_sn2=$(echo "$output_sfc" | grep "Table39" -A 6 | awk -F '<|>' '/CSN/ {print $3}')

            # Verificar si se obtuvieron las MACs correctamente
            if [[ -z "$sw_mac1" || -z "$sw_mac2" ]]; then
                echo -e "${RED}Error: No se pudieron obtener las MACs de los switches.${RESET}"
                read -rp "Presione cualquier tecla para volver al menú principal... " -n1 -s
                continue
            fi

            # Obtener las IPs de los switches
            get_sw_ip "$sw_mac1"
            sw_ip1="$sw_ip"

            get_sw_ip "$sw_mac2"
            sw_ip2="$sw_ip"

            # Verificar si se obtuvieron las IPs correctamente
            if [[ -z "$sw_ip1" || -z "$sw_ip2" ]]; then
                echo -e "${RED}Error: No se pudieron obtener las IPs de los switches.${RESET}"
                echo -e "${BLUE}NOTA: Asegure IPs primero en ambos SW o reconfigure con cable CONSOLE.${RESET}"
                read -rp "Presione cualquier tecla para volver al menú principal... " -n1 -s
            continue
            fi
            
            # Mostrar el submenú de selección de switch
            echo -e "${BLUE}Se detectaron los siguientes switchs:${RESET}"
            echo -e "1) Switch 1 - MAC: $sw_mac1 - SN: $sw_sn1 - IP: $sw_ip1"
            echo -e "2) Switch 2 - MAC: $sw_mac2 - SN: $sw_sn2 - IP: $sw_ip2"
            read -rp "Seleccione el switch a configurar (1 o 2): " sw_option

            # Asignar la IP correspondiente según la selección
            case $sw_option in
                1) SW_IP="$sw_ip1" ;;
                2) SW_IP="$sw_ip2" ;;
                *)
                    echo -e "${RED}Opción inválida. Regresando al menú principal.${RESET}"
                    read -rp "Presione cualquier tecla para continuar... " -n1 -s
                    continue
                    ;;
            esac

            # Validación de conexión al switch seleccionado
            echo -e "${BLUE}Verificando conectividad con el switch en la IP: $SW_IP...${RESET}"
            if ! ping -c 3 "$SW_IP" > /dev/null; then
                echo -e "${RED}El switch no responde. Verifique la conexión.${RESET}"
                echo -e "${BLUE}NOTA: Asegure IPs primero en ambos SW o reconfigure con cable CONSOLE.${RESET}"
                read -rp "Presione cualquier tecla para volver al menú principal... " -n1 -s
                continue
            fi

            # Configuración del switch seleccionado
            echo -e "${BLUE}Configurando SW en la IP: $SW_IP...${RESET}"
            ssh root@"$SW_IP" <<EOF
                cd /bin
                integrator_mode -m "1-2:4x10G;3-12:2x100G;13-20:Copper_4x100G;21-24:40G;25-32:Copper_4x100G"
EOF
            echo -e "${GREEN}Configuración aplicada exitosamente.${RESET}"

            #Registrar uso en csv
            registrar_uso "2 (SW Autoconfig)" "$SN_RACK" "$SW_IP"
            ;;
        3)
        #Rack information, codigo pendiente desarollar en Wiwynn
            read -rp "Ingrese el SN del rack: " SN_RACK
            echo -e "${BLUE}Obteniendo Rack Information...${RESET}"
            echo -e "${BLUE}Espere un momento por favor !!...${RESET}"
            output_sfc=$(bash /home/MW23090133/gnw/tools/toolsgnw/dbconsult.sh --GetDynamicData --usn="$SN_RACK" --value=DYN_POSITION_FIONA --name=USN)
            
            snbot_hn=$(echo "$output_sfc" | grep "Table20" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            snbot_jb7=$(echo "$output_sfc" | grep "Table11" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            snbot_jb6=$(echo "$output_sfc" | grep "Table12" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            snbot_jb5=$(echo "$output_sfc" | grep "Table13" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            snbot_jb4=$(echo "$output_sfc" | grep "Table14" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            snbot_jb3=$(echo "$output_sfc" | grep "Table15" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            snbot_jb2=$(echo "$output_sfc" | grep "Table16" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            snbot_jb1=$(echo "$output_sfc" | grep "Table17" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            snbot_jb0=$(echo "$output_sfc" | grep "Table18" -A 6 | awk -F '<|>' '/CSN/ {print $3}')

            #IPs de las unidades BOT
            get_bmc_ip_debug2 "$snbot_hn"
            bmc_bothn=$bmc_ip
            get_bmc_ip_debug2 "$snbot_jb7"
            bmcbot_jb7=$bmc_ip
            get_bmc_ip_debug2 "$snbot_jb6"
            bmcbot_jb6=$bmc_ip
            get_bmc_ip_debug2 "$snbot_jb5"
            bmcbot_jb5=$bmc_ip
            get_bmc_ip_debug2 "$snbot_jb4"
            bmcbot_jb4=$bmc_ip
            get_bmc_ip_debug2 "$snbot_jb3"
            bmcbot_jb3=$bmc_ip
            get_bmc_ip_debug2 "$snbot_jb2"
            bmcbot_jb2=$bmc_ip
            get_bmc_ip_debug2 "$snbot_jb1"
            bmcbot_jb1=$bmc_ip
            get_bmc_ip_debug2 "$snbot_jb0"
            bmcbot_jb0=$bmc_ip


            sntop_hn=$(echo "$output_sfc" | grep "Table40" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            sntop_jb7=$(echo "$output_sfc" | grep "Table38" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            sntop_jb6=$(echo "$output_sfc" | grep "Table37" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            sntop_jb5=$(echo "$output_sfc" | grep "Table36" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            sntop_jb4=$(echo "$output_sfc" | grep "Table35" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            sntop_jb3=$(echo "$output_sfc" | grep "Table34" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            sntop_jb2=$(echo "$output_sfc" | grep "Table33" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            sntop_jb1=$(echo "$output_sfc" | grep "Table32" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            sntop_jb0=$(echo "$output_sfc" | grep "Table31" -A 6 | awk -F '<|>' '/CSN/ {print $3}')


            # Obtener las IPs de las unidades TOP
            get_bmc_ip_debug2 "$sntop_hn"
            bmc_tophn=$bmc_ip
            get_bmc_ip_debug2 "$sntop_jb7"
            bmctop_jb7=$bmc_ip
            get_bmc_ip_debug2 "$sntop_jb6"
            bmctop_jb6=$bmc_ip
            get_bmc_ip_debug2 "$sntop_jb5"
            bmctop_jb5=$bmc_ip
            get_bmc_ip_debug2 "$sntop_jb4"
            bmctop_jb4=$bmc_ip
            get_bmc_ip_debug2 "$sntop_jb3"
            bmctop_jb3=$bmc_ip
            get_bmc_ip_debug2 "$sntop_jb2"
            bmctop_jb2=$bmc_ip
            get_bmc_ip_debug2 "$sntop_jb1"
            bmctop_jb1=$bmc_ip
            get_bmc_ip_debug2 "$sntop_jb0"
            bmctop_jb0=$bmc_ip

            #Obtener la eth0 de las dos HN
            get_eth0_ip_debug "$sntop_hn"
            eth0_tophn=$eth0_ip
            get_eth0_ip_debug "$snbot_hn"
            eth0_bothn=$eth0_ip

            #Obtener datos de los SW
            sw_mac1=$(echo "$output_sfc" | grep "Table19" -A 6 | awk -F '<|>' '/ETH0MAC/ {print $3}')
            sw_mac2=$(echo "$output_sfc" | grep "Table39" -A 6 | awk -F '<|>' '/ETH0MAC/ {print $3}')
            sw_sn1=$(echo "$output_sfc" | grep "Table19" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            sw_sn2=$(echo "$output_sfc" | grep "Table39" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            
            # Obtener las IPs de los switches
            get_sw_ip "$sw_mac1"
            sw_ip1="$sw_ip"
            get_sw_ip "$sw_mac2"
            sw_ip2="$sw_ip"

            #Informacion de las PSC
            sn_pscbot=$(echo "$output_sfc" | grep "Table9" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            sn_psctop=$(echo "$output_sfc" | grep "Table29" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            mac_pscbot=$(echo "$output_sfc" | awk '/<Table diffgr:id="Table8"/,/<\/Table>/ { if ($0 ~ /<ETH1MAC>/) { gsub(/.*<ETH1MAC>|<\/ETH1MAC>.*/, ""); print } }')
            mac_psctop=$(echo "$output_sfc" | awk '/<Table diffgr:id="Table28"/,/<\/Table>/ { if ($0 ~ /<ETH1MAC>/) { gsub(/.*<ETH1MAC>|<\/ETH1MAC>.*/, ""); print } }')

            #Informacion del CONSOLE
            sn_console=$(echo "$output_sfc" | grep "Table21" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            mac_console=$(echo "$output_sfc" | awk '/<Table diffgr:id="Table21"/,/<\/Table>/ { if ($0 ~ /<ETH0MAC>/) { gsub(/.*<ETH0MAC>|<\/ETH0MAC>.*/, ""); print } }')

            # Obtener las IPs de los PSC
            get_sw_ip "$mac_psctop"
            psctop_ip="$sw_ip"
            get_sw_ip "$mac_pscbot"
            pscbot_ip="$sw_ip"

            # Obtener las IPs del Console
            get_sw_ip "$mac_console"
            console_ip="$sw_ip"

            # Info de kit TOP
            echo -e "${YELLOW}-------------------------------------${RESET}"
            echo -e "${CYAN}Informacion del KIT TOP${RESET}"
            echo -e "${YELLOW}-------------------------------------${RESET}"
            echo -e "${BLUE}HN TOP - ${GREEN}$sntop_hn${RESET}"
            echo -e "${BLUE}JBOG 0 - ${GREEN}$sntop_jb0${RESET}"
            echo -e "${BLUE}JBOG 1 - ${GREEN}$sntop_jb1${RESET}"
            echo -e "${BLUE}JBOG 2 - ${GREEN}$sntop_jb2${RESET}"
            echo -e "${BLUE}JBOG 3 - ${GREEN}$sntop_jb3${RESET}"
            echo -e "${BLUE}JBOG 4 - ${GREEN}$sntop_jb4${RESET}"
            echo -e "${BLUE}JBOG 5 - ${GREEN}$sntop_jb5${RESET}"
            echo -e "${BLUE}JBOG 6 - ${GREEN}$sntop_jb6${RESET}"
            echo -e "${BLUE}JBOG 7 - ${GREEN}$sntop_jb7${RESET}"
            echo -e "${YELLOW}-------------------------------------${RESET}"

            # Info de kit BOT
            echo -e "${YELLOW}-------------------------------------${RESET}"
            echo -e "${CYAN}Informacion del KIT BOT${RESET}"
            echo -e "${YELLOW}-------------------------------------${RESET}"
            echo -e "${BLUE}HN BOT - ${GREEN}$snbot_hn${RESET}"
            echo -e "${BLUE}JBOG 0 - ${GREEN}$snbot_jb0${RESET}"
            echo -e "${BLUE}JBOG 1 - ${GREEN}$snbot_jb1${RESET}"
            echo -e "${BLUE}JBOG 2 - ${GREEN}$snbot_jb2${RESET}"
            echo -e "${BLUE}JBOG 3 - ${GREEN}$snbot_jb3${RESET}"
            echo -e "${BLUE}JBOG 4 - ${GREEN}$snbot_jb4${RESET}"
            echo -e "${BLUE}JBOG 5 - ${GREEN}$snbot_jb5${RESET}"
            echo -e "${BLUE}JBOG 6 - ${GREEN}$snbot_jb6${RESET}"
            echo -e "${BLUE}JBOG 7 - ${GREEN}$snbot_jb7${RESET}"
            echo -e "${YELLOW}-------------------------------------${RESET}"

            # Info de los SW DATA
            echo -e "${YELLOW}-------------------------------------${RESET}"
            echo -e "${CYAN}Informacion de los SW DATA${RESET}"
            echo -e "${YELLOW}-------------------------------------${RESET}"
            echo -e "${BLUE}SW DATA 1 - ${GREEN}$sw_sn1${RESET}"
            echo -e "${BLUE}SW DATA 2 - ${GREEN}$sw_sn2${RESET}"
            echo -e "${BLUE}SW DATA 1 IP - ${GREEN}$sw_ip1${RESET}"
            echo -e "${BLUE}SW DATA 2 IP - ${GREEN}$sw_ip2${RESET}"
            echo -e "${YELLOW}-------------------------------------${RESET}"

            # Info del CONSOLE
            echo -e "${YELLOW}-------------------------------------${RESET}"
            echo -e "${CYAN}Informacion del CONSOLE${RESET}"
            echo -e "${YELLOW}-------------------------------------${RESET}"
            echo -e "${BLUE}CONSOLE - ${GREEN}$sn_console${RESET}"
            echo -e "${BLUE}CONSOLE MAC - ${GREEN}$mac_console${RESET}"
            echo -e "${BLUE}CONSOLE IP - ${GREEN}$console_ip${RESET}"
            echo -e "${YELLOW}-------------------------------------${RESET}"

            # Info de las PSC
            echo -e "${YELLOW}-------------------------------------${RESET}"
            echo -e "${CYAN}Informacion de las PSC${RESET}"
            echo -e "${YELLOW}-------------------------------------${RESET}"
            echo -e "${BLUE}PSC TOP - ${GREEN}$sn_psctop${RESET}"
            echo -e "${BLUE}PSC BOT - ${GREEN}$sn_pscbot${RESET}"
            echo -e "${BLUE}MAC PSC TOP - ${GREEN}$mac_psctop${RESET}"
            echo -e "${BLUE}MAC PSC BOT - ${GREEN}$mac_pscbot${RESET}"
            echo -e "${BLUE}IP PSC TOP - ${GREEN}$psctop_ip${RESET}"
            echo -e "${BLUE}IP PSC BOT - ${GREEN}$pscbot_ip${RESET}"
            echo -e "${YELLOW}-------------------------------------${RESET}"



            #Pingeo de las unidades
            echo "-------------------------------------"
            for i in hn jb0 jb1 jb2 jb3 jb4 jb5 jb6 jb7; do
                if [ "$i" == "hn" ]; then
                    echo "BMC IP de TOP HN: $bmc_tophn"
                else
                    eval "echo \"BMC IP de TOP JBOG$i: \$bmctop_$i\""
                fi
            done
            echo "-------------------------------------"
            for i in hn jb0 jb1 jb2 jb3 jb4 jb5 jb6 jb7; do
                if [ "$i" == "hn" ]; then
                    echo "BMC IP de BOT HN: $bmc_bothn"
                else
                    eval "echo \"BMC IP de BOT JBOG$i: \$bmcbot_$i\""
                fi
            done

            echo "-------------------------------------"
            
            echo -e "\n${BLUE}Ping a la ETH0 de la HN TOP (SN: $sntop_hn) - IP eth0: $eth0_tophn${RESET}"
            ping -c 4 "$eth0_tophn" | while read -r line; do
                if echo "$line" | grep -q "time="; then
                    echo -e "${GREEN}$line${RESET}"
                else
                    echo -e "${RED}$line${RESET}"
                fi
            done

            echo -e "\n${BLUE}Ping a la ETH0 de la HN BOT (SN: $snbot_hn) - IP eth0: $eth0_bothn${RESET}"
            ping -c 4 "$eth0_bothn" | while read -r line; do
                if echo "$line" | grep -q "time="; then
                    echo -e "${GREEN}$line${RESET}"
                else
                    echo -e "${RED}$line${RESET}"
                fi
            done

          # Realizar ping a las unidades y mostrar el SN y IP
            echo "-------------------------------------"
            echo -e "${YELLOW}Pinging a las unidades TOP y BOT...${RESET}"

            for i in hn jb0 jb1 jb2 jb3 jb4 jb5 jb6 jb7; do
                if [ "$i" == "hn" ]; then
                    echo -e "\n${BLUE}Pinging TOP HN (SN: $sntop_hn) - IP: $bmc_tophn${RESET}"
                    ping -c 4 "$bmc_tophn" | while read -r line; do
                        if echo "$line" | grep -q "time="; then
                            echo -e "${GREEN}$line${RESET}"
                        else
                            echo -e "${RED}$line${RESET}"
                        fi
                    done
                else
                    # Acceder directamente a las variables de forma explícita
                    sn="sntop_${i}"
                    ip="bmctop_${i}"

                    echo -e "\n${BLUE}Pinging TOP JBOG$i (SN: ${!sn}) - IP: ${!ip}${RESET}"
                    ping -c 4 "${!ip}" | while read -r line; do
                        if echo "$line" | grep -q "time="; then
                            echo -e "${GREEN}$line${RESET}"
                        else
                            echo -e "${RED}$line${RESET}"
                        fi
                    done
                fi
            done

            for i in hn jb0 jb1 jb2 jb3 jb4 jb5 jb6 jb7; do
                if [ "$i" == "hn" ]; then
                    echo -e "\n${BLUE}Pinging BOT HN (SN: $snbot_hn) - IP: $bmc_bothn${RESET}"
                    ping -c 4 "$bmc_bothn" | while read -r line; do
                        if echo "$line" | grep -q "time="; then
                            echo -e "${GREEN}$line${RESET}"
                        else
                            echo -e "${RED}$line${RESET}"
                        fi
                    done
                else
                    # Acceder directamente a las variables de forma explícita
                    sn="snbot_${i}"
                    ip="bmcbot_${i}"

                    echo -e "\n${BLUE}Pinging BOT JBOG$i (SN: ${!sn}) - IP: ${!ip}${RESET}"
                    ping -c 4 "${!ip}" | while read -r line; do
                        if echo "$line" | grep -q "time="; then
                            echo -e "${GREEN}$line${RESET}"
                        else
                            echo -e "${RED}$line${RESET}"
                        fi
                    done
                fi
            done


            # Pingar a los switches
            echo -e "${YELLOW}Pinging a los switches...${RESET}"

            echo -e "\n${BLUE}Pinging Switch 1 (SN: $sw_sn1) - IP: $sw_ip1${RESET}"
            ping -c 4 "$sw_ip1" | while read -r line; do
                if echo "$line" | grep -q "time="; then
                    echo -e "${GREEN}$line${RESET}"
                else
                    echo -e "${RED}$line${RESET}"
                fi
            done

            echo -e "\n${BLUE}Pinging Switch 2 (SN: $sw_sn2) - IP: $sw_ip2${RESET}"
            ping -c 4 "$sw_ip2" | while read -r line; do
                if echo "$line" | grep -q "time="; then
                    echo -e "${GREEN}$line${RESET}"
                else
                    echo -e "${RED}$line${RESET}"
                fi
            done

             # Pingar a las PSC
            echo -e "${YELLOW}Pinging a las PSCs...${RESET}"

            echo -e "\n${BLUE}Pinging PSC TOP (SN: $sn_psctop) - IP: $psctop_ip${RESET}"
            ping -c 4 "$psctop_ip" | while read -r line; do
                if echo "$line" | grep -q "time="; then
                    echo -e "${GREEN}$line${RESET}"
                else
                    echo -e "${RED}$line${RESET}"
                fi
            done

            echo -e "\n${BLUE}Pinging PSC BOT (SN: $sn_pscbot) - IP: $pscbot_ip${RESET}"
            ping -c 4 "$pscbot_ip" | while read -r line; do
                if echo "$line" | grep -q "time="; then
                    echo -e "${GREEN}$line${RESET}"
                else
                    echo -e "${RED}$line${RESET}"
                fi
            done

            echo -e "\n${BLUE}Ping al CONSOLE (SN: $sn_console) - IP: $console_ip${RESET}"
            ping -c 4 "$console_ip" | while read -r line; do
                if echo "$line" | grep -q "time="; then
                    echo -e "${GREEN}$line${RESET}"
                else
                    echo -e "${RED}$line${RESET}"
                fi
            done

            #Registrar uso en csv
            registrar_uso "3 (Rack Information)" "$SN_RACK" "N/A"
            ;;
        4)
        #Verificacion de Puerto PCIE - Funciona correctamente
            read -rp "Ingrese el SN de la HN: " SN
            # Llamamos a la función para obtener la IP de eth0 usando el SN
            get_eth0_ip_debug "$SN"
            echo -e "${BLUE}Verificando conectividad ETH0 con la IP $eth0_ip...${RESET}"
            # Validación de ping
            if ! ping -c 3 "$eth0_ip" > /dev/null; then
                echo -e "${RED}La IP de eth0 no responde. Asegure la IP Eth primero.${RESET}"
                read -rp "Presione cualquier tecla para volver al menú principal... " -n1 -s
                continue
            fi

             # Registrar uso de la opción 4 en el log
            registrar_uso "4 (Verificación de Puerto PCIE)" "$SN" "$eth0_ip"

            # Conexión SSH
            echo -e "${BLUE}Abriendo conexión SSH con la IP de Ether...${RESET}"
            sshpass -p 'password' ssh -o StrictHostKeyChecking=no root@"$eth0_ip" <<EOF
                cd /opt/mfg/TE
                bash TT2_PCIE_DEVICES_CHECK.sh
EOF
            ;;
        5)
        #Abrir UART de la unidad - Funciona correctamente
            read -rp "Ingrese el SN de la HN: " SN
            # Obtener la IP de la K2V4 usando la función
            get_bmc_ip_debug2 "$SN"

            # Verificar si la IP de la BMC se obtuvo correctamente
            if [ -z "$bmc_ip" ]; then
                echo -e "${RED}Error: No se pudo obtener la IP de la BMC para el SN $SN.${RESET}"
                exit 1
            fi

            # Registrar uso de la opción 5 en el log
            registrar_uso "5 (Abrir UART de la unidad)" "$SN" "$bmc_ip"

            echo -e "${BLUE}Ejecutando UART Tool...${RESET}"
            bash nitro-bmc -i "$bmc_ip" sol activate -u admin -p admin -d 2
            ;;
        6)
        #Verificar proxy cards - Funciona correctamente
            read -rp "Ingrese el SN de la HN: " SN
            # Obtener la IP de la K2V4 usando la función
            get_k2v4_ip_from_sn "$SN"

            # Verificar si se obtuvo la K2V4 IP
            if [ -z "$k2v4_ip" ]; then
            echo -e "${RED}No se pudo obtener la IP de la K2V4. Asegúrese de que el SN sea correcto.${RESET}"
            read -rp "Presione cualquier tecla para volver al menú principal... " -n1 -s
            continue
            fi

            # Registrar uso de la opción 6 en el log
            registrar_uso "6 (Verificar proxy cards)" "$SN" "$k2v4_ip"

            echo -e "${BLUE}Verificando K2V5...${RESET}"
            # Ejecutar comando para verificar K2V5 usando la K2V4 IP obtenida
            cd /home/MW23090133/gnw/tools/toolscript
            bash proxycards_k2.sh "$k2v4_ip"

            echo -e "${BLUE}Verificando GPUs...${RESET}"
            # Ejecutar comando para verificar GPUs
            cd /home/MW23090133/gnw/tools/toolscript
            bash proxycards_mx.sh "$k2v4_ip"
            ;;
        7)
        #Verifica los tipos de tarjetas k2v5
            read -rp "Ingrese el SN de la HN: " SN
            echo -e "${BLUE}Verificando K2V5 card type...${RESET}"
            get_k2v4_ip_from_sn "$SN"

        # Verificar si se obtuvo la K2V4 IP
            if [ -z "$k2v4_ip" ]; then
                echo -e "${RED}No se pudo obtener la IP de la K2V4. Asegúrese de que el SN sea correcto.${RESET}"
                read -rp "Presione cualquier tecla para volver al menú principal... " -n1 -s
                continue
            fi

        #Registrar uso de la opción 7 en el log
            registrar_uso "7 (Verificar tipos de tarjetas K2V5)" "$SN" "$k2v4_ip"

            coap -O65001,0 -Y coaps+tcp://$k2v4_ip/api-v1/host/proxy/cards

        #Mensaje de guía para el usuario
            echo "En caso de que no sean 43 cards, compruebe el ensamble de todos los GPIO y haga DHCP clear +  VPD"
            echo "  • “all-in-one” is mean K2V4 card.
                    • ”cordite” is mean K2XN card.
                    • “bmc” is mean BMC + SMC
                    • “cbm” is mean primary mode K2V5 cards.
                    • “stock” is mean recovery mode K2V5 cards. 
                    • “pacific” are mean GPU(MX2) cards."


            ;;
        8)
        #Ejecuta la prueba de cable detect
            read -rp "Ingrese el SN del rack: " SN_RACK
            echo -e "${BLUE}Obteniendo Rack Information...${RESET}"
            echo -e "${BLUE}Espere un momento por favor !!...${RESET}"
            output_sfc=$(bash /home/MW23090133/gnw/tools/toolsgnw/dbconsult.sh --GetDynamicData --usn="$SN_RACK" --value=DYN_POSITION_FIONA --name=USN)

            snbot_hn=$(echo "$output_sfc" | grep "Table20" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            snbot_jb7=$(echo "$output_sfc" | grep "Table11" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            snbot_jb6=$(echo "$output_sfc" | grep "Table12" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            snbot_jb5=$(echo "$output_sfc" | grep "Table13" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            snbot_jb4=$(echo "$output_sfc" | grep "Table14" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            snbot_jb3=$(echo "$output_sfc" | grep "Table15" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            snbot_jb2=$(echo "$output_sfc" | grep "Table16" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            snbot_jb1=$(echo "$output_sfc" | grep "Table17" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            snbot_jb0=$(echo "$output_sfc" | grep "Table18" -A 6 | awk -F '<|>' '/CSN/ {print $3}')

            #IPs de las unidades BOT
            get_bmc_ip_debug2 "$snbot_hn"
            bmc_bothn=$bmc_ip
            get_bmc_ip_debug2 "$snbot_jb7"
            bmcbot_jb7=$bmc_ip
            get_bmc_ip_debug2 "$snbot_jb6"
            bmcbot_jb6=$bmc_ip
            get_bmc_ip_debug2 "$snbot_jb5"
            bmcbot_jb5=$bmc_ip
            get_bmc_ip_debug2 "$snbot_jb4"
            bmcbot_jb4=$bmc_ip
            get_bmc_ip_debug2 "$snbot_jb3"
            bmcbot_jb3=$bmc_ip
            get_bmc_ip_debug2 "$snbot_jb2"
            bmcbot_jb2=$bmc_ip
            get_bmc_ip_debug2 "$snbot_jb1"
            bmcbot_jb1=$bmc_ip
            get_bmc_ip_debug2 "$snbot_jb0"
            bmcbot_jb0=$bmc_ip


            sntop_hn=$(echo "$output_sfc" | grep "Table40" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            sntop_jb7=$(echo "$output_sfc" | grep "Table38" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            sntop_jb6=$(echo "$output_sfc" | grep "Table37" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            sntop_jb5=$(echo "$output_sfc" | grep "Table36" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            sntop_jb4=$(echo "$output_sfc" | grep "Table35" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            sntop_jb3=$(echo "$output_sfc" | grep "Table34" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            sntop_jb2=$(echo "$output_sfc" | grep "Table33" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            sntop_jb1=$(echo "$output_sfc" | grep "Table32" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            sntop_jb0=$(echo "$output_sfc" | grep "Table31" -A 6 | awk -F '<|>' '/CSN/ {print $3}')


            # Obtener las IPs de las unidades TOP
            get_bmc_ip_debug2 "$sntop_hn"
            bmc_tophn=$bmc_ip
            get_bmc_ip_debug2 "$sntop_jb7"
            bmctop_jb7=$bmc_ip
            get_bmc_ip_debug2 "$sntop_jb6"
            bmctop_jb6=$bmc_ip
            get_bmc_ip_debug2 "$sntop_jb5"
            bmctop_jb5=$bmc_ip
            get_bmc_ip_debug2 "$sntop_jb4"
            bmctop_jb4=$bmc_ip
            get_bmc_ip_debug2 "$sntop_jb3"
            bmctop_jb3=$bmc_ip
            get_bmc_ip_debug2 "$sntop_jb2"
            bmctop_jb2=$bmc_ip
            get_bmc_ip_debug2 "$sntop_jb1"
            bmctop_jb1=$bmc_ip
            get_bmc_ip_debug2 "$sntop_jb0"
            bmctop_jb0=$bmc_ip

            # Registrar uso de la opción 8
            registrar_uso "8 (Prueba de cable detect)" "$SN_RACK" "$bmc_bothn $bmc_tophn"

            # Ejecutar prueba para BOT
            echo -e "$GREEN}===========================================================${RESET}"
            echo -e "${BLUE}         PRUEBA DE CABLE DETECT PARA KIT BOT${RESET}"
            echo -e "$GREEN}===========================================================${RESET}"
            /opt/test_tools/teton2/teton2_slot_monitor_external_cable_detect_jake_edited-1.sh "$bmcbot_jb0" "$bmc_bothn"
            /opt/test_tools/teton2/teton2_slot_monitor_external_cable_detect_jake_edited-1.sh "$bmcbot_jb1" "$bmc_bothn"
            /opt/test_tools/teton2/teton2_slot_monitor_external_cable_detect_jake_edited-1.sh "$bmcbot_jb2" "$bmc_bothn"
            /opt/test_tools/teton2/teton2_slot_monitor_external_cable_detect_jake_edited-1.sh "$bmcbot_jb3" "$bmc_bothn"
            /opt/test_tools/teton2/teton2_slot_monitor_external_cable_detect_jake_edited-1.sh "$bmcbot_jb4" "$bmc_bothn"
            /opt/test_tools/teton2/teton2_slot_monitor_external_cable_detect_jake_edited-1.sh "$bmcbot_jb5" "$bmc_bothn"
            /opt/test_tools/teton2/teton2_slot_monitor_external_cable_detect_jake_edited-1.sh "$bmcbot_jb6" "$bmc_bothn"
            /opt/test_tools/teton2/teton2_slot_monitor_external_cable_detect_jake_edited-1.sh "$bmcbot_jb7" "$bmc_bothn"

            # Ejecutar prueba para TOP
            echo -e "$GREEN}===========================================================${RESET}"
            echo -e "${BLUE}        PRUEBA DE CABLE DETECT PARA KIT TOP${RESET}"
            echo -e "$GREEN}===========================================================${RESET}"
            /opt/test_tools/teton2/teton2_slot_monitor_external_cable_detect_jake_edited-1.sh "$bmctop_jb0" "$bmc_tophn"
            /opt/test_tools/teton2/teton2_slot_monitor_external_cable_detect_jake_edited-1.sh "$bmctop_jb1" "$bmc_tophn"
            /opt/test_tools/teton2/teton2_slot_monitor_external_cable_detect_jake_edited-1.sh "$bmctop_jb2" "$bmc_tophn"
            /opt/test_tools/teton2/teton2_slot_monitor_external_cable_detect_jake_edited-1.sh "$bmctop_jb3" "$bmc_tophn"
            /opt/test_tools/teton2/teton2_slot_monitor_external_cable_detect_jake_edited-1.sh "$bmctop_jb4" "$bmc_tophn"
            /opt/test_tools/teton2/teton2_slot_monitor_external_cable_detect_jake_edited-1.sh "$bmctop_jb5" "$bmc_tophn"
            /opt/test_tools/teton2/teton2_slot_monitor_external_cable_detect_jake_edited-1.sh "$bmctop_jb6" "$bmc_tophn"
            /opt/test_tools/teton2/teton2_slot_monitor_external_cable_detect_jake_edited-1.sh "$bmctop_jb7" "$bmc_tophn"
            ;;
        9)
        #Mostrar y limpiar eventos SEL - Funciona correctamente.
            read -rp "Ingrese el SN de la unidad: " SN
            # Llamamos a la función para obtener la IP de la BMC usando el SN
            get_bmc_ip_debug2 "$SN"

            # Verificar si la IP de la BMC se obtuvo correctamente
            if [ -z "$bmc_ip" ]; then
                echo -e "${RED}Error: No se pudo obtener la IP de la BMC para el SN $SN.${RESET}"
                exit 1
            fi

            # Registrar el uso del script utilizando la función registrar_uso
            registrar_uso "9 (Mostrar y limpiar eventos SEL)" "$SN" "$bmc_ip"


            echo -e "${BLUE}Eventos encontrados en la unidad...${RESET}"
            ./nitro-bmc -i "$bmc_ip" sel list
            echo -e "${BLUE}Limpiando eventos...${RESET}"
            ./nitro-bmc -i "$bmc_ip" sel clear
            echo -e "${BLUE}Proceso terminado correctamente...${RESET}"
            ;;
        10)
        #Mostrar sensor list - Funciona correctamente
            read -rp "Ingrese el SN de la unidad: " SN
            # Llamamos a la función para obtener la IP de la BMC usando el SN
            get_bmc_ip_debug2 "$SN"

            # Verificar si la IP de la BMC se obtuvo correctamente
            if [ -z "$bmc_ip" ]; then
                echo -e "${RED}Error: No se pudo obtener la IP de la BMC para el SN $SN.${RESET}"
                exit 1
            fi

            # Registrar el uso del script utilizando la función registrar_uso
            registrar_uso "10 (Mostrar sensor list)" "$SN" "$bmc_ip"

            echo -e "${BLUE}Mostrando lista de sensores...${RESET}"
            ./nitro-bmc --bmc-ip "$bmc_ip" sensors list
            ;;
        11)
        #Sel clear + VPD - Funciona correctamente
            read -rp "Ingrese el SN de la unidad HN: " SN
            # Llamamos a la función para obtener la IP de la BMC usando el SN
            get_bmc_ip_debug2 "$SN"

            # Verificar si la IP de la BMC se obtuvo correctamente
            if [ -z "$bmc_ip" ]; then
                echo -e "${RED}Error: No se pudo obtener la IP de la BMC para el SN $SN.${RESET}"
                exit 1
            fi

            # Registrar el uso del script utilizando la función registrar_uso
            registrar_uso "11 (Sel Clear + VPD)" "$SN" "$bmc_ip"

            echo -e "${BLUE}Ejecutando Sel Clear + VPD en $bmc_ip...${RESET}"
            ./nitro-bmc -i "$bmc_ip" sel clear
            ./nitro-bmc -i "$bmc_ip" power off
            ./nitro-bmc -i "$bmc_ip" power virtualpowerdrain
            ;;
        12)
        #Imprimir FRU de la unidad - Funciona correctamente.
            read -rp "Ingrese el SN de la unidad: " SN
            # Llamamos a la función para obtener la IP de la BMC usando el SN
            get_bmc_ip_debug2 "$SN"

            # Verificar si la IP de la BMC se obtuvo correctamente
            if [ -z "$bmc_ip" ]; then
                echo -e "${RED}Error: No se pudo obtener la IP de la BMC para el SN $SN.${RESET}"
                exit 1
            fi

            # Registrar el uso del script utilizando la función registrar_uso
            registrar_uso "12 (Imprimir FRU completo)" "$SN" "$bmc_ip"

            echo -e "${BLUE}Imprimiendo FRU en $bmc_ip...${RESET}"
            ./nitro-bmc --bmc-ip "$bmc_ip" fru print
            ;;
        13)
        #Mostrar BMC network - Funciona correctamente
            read -rp "Ingrese el SN de la unidad: " SN
            # Llamamos a la función para obtener la IP de la BMC usando el SN
            get_bmc_ip_debug2 "$SN"

            # Verificar si la IP de la BMC se obtuvo correctamente
            if [ -z "$bmc_ip" ]; then
                echo -e "${RED}Error: No se pudo obtener la IP de la BMC para el SN $SN.${RESET}"
                exit 1
            fi

            # Registrar el uso del script utilizando la función registrar_uso
            registrar_uso "13 (Mostrar BMC network)" "$SN" "$bmc_ip"

            echo -e "${BLUE}Verificando BMC Network en $bmc_ip...${RESET}"
            ./nitro-bmc -i "$bmc_ip" bmc network
            ;;
        14)
        #Limpia el DHCP y ejecuta un VPD
            read -rp "Ingrese el SN de la HN: " SN
            # Llamamos a la función para obtener la IP de la BMC usando el SN
            get_k2v4_ip_from_sn "$SN"

            # Verificar si la IP de K2V4 se obtuvo correctamente
            if [ -z "$k2v4_ip" ]; then
                echo -e "${RED}Error: No se pudo obtener la IP de la K2V4 para el SN $SN.${RESET}"
                exit 1
            fi

            echo -e "${BLUE}Limpiando registros en el DHCP...${RESET}"
            ./dhcp-lease-clear.sh "$k2v4_ip"

            echo -e "${BLUE}Realizando VPD...${RESET}"
            get_bmc_ip_debug2 "$SN"

            # Verificar si la IP de la BMC se obtuvo correctamente
            if [ "$bmc_ip" == "None" ] || [ -z "$bmc_ip" ]; then
                echo -e "${RED}Error: No se pudo obtener la IP de la BMC para el SN $SN.${RESET}"
                exit 1
            fi

            # Registrar el uso de la opción
            registrar_uso "16 (Limpiar DHCP y ejecutar VPD)" "$SN" "$bmc_ip"

            ./nitro-bmc -i $bmc_ip power off 
            ./nitro-bmc -i $bmc_ip power virtualpowerdrain 
            ;;
        15)
        #Getip extend
            read -rp "Ingrese el SN de la unidad: " SN
            # Llamamos a la función para obtener la IP de la BMC usando el SN
            echo -e "${BLUE}Verificando IPV4 en el KIT...${RESET}"
            getip --extend "$SN"

            # Registrar el uso de la opción 17
            registrar_uso "17 (Verificar IPv4)" "$SN" "NA"
            ;;
        16)
        # Ejecutar un BMC reboot con validación de IP y confirmación del usuario
            read -rp "Ingrese el SN de la unidad: " SN
            get_bmc_ip_debug2 "$SN"

            # Verificar si se obtuvo una IP válida
            if [[ -z "$bmc_ip" || ! "$bmc_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                echo -e "${RED}Error: No se pudo obtener una IP válida para el SN ingresado.${RESET}"
                continue
            fi

            # Confirmación antes de reiniciar
            read -rp "¿Está seguro de reiniciar el KIT SN: $SN? (Y/N): " confirmacion
            case $confirmacion in
                [Yy])
                    registrar_uso "14 (BMC reboot | Confirmado |)" "$SN" "$bmc_ip"
                    echo -e "${BLUE}Reiniciando BMC en $bmc_ip...${RESET}"
                    ./nitro-bmc -i "$bmc_ip" bmc reboot
                    ;;
                [Nn])
                    registrar_uso "14 (BMC reboot | CANCELADO |)" "$SN" "$bmc_ip"
                    echo -e "${YELLOW}Operación cancelada.${RESET}"
                    ;;
                *)
                    echo -e "${RED}Opción no válida. Operación cancelada.${RESET}"
            esac
            ;;
        17)
        #Ejecuta una sesion SOL para ver estado de arranque - Funciona correctamente
            read -rp "Ingrese el SN de la HN: " SN
            # Llamamos a la función para obtener la IP de la BMC usando el SN
            get_bmc_ip_debug2 "$SN"

            # Verificar si la IP de la BMC se obtuvo correctamente
            if [ -z "$bmc_ip" ]; then
                echo -e "${RED}Error: No se pudo obtener la IP de la BMC para el SN $SN.${RESET}"
                exit 1
            fi

            # Registrar el uso del script utilizando la función registrar_uso
            registrar_uso "15 (Sol Activate)" "$SN" "$bmc_ip"

            echo -e "${BLUE}Activando Sol...${RESET}"
            ./nitro-bmc -i "$bmc_ip" sol deactivate -u admin -p admin -d 0
            ./nitro-bmc -i "$bmc_ip" sol activate -u admin -p admin -d 0
            ;;
        18)
        #Ejecuta una verificacion de SDR sensors para identificar fallas de SMC3_P0V9_VIN
            echo -e "${BLUE}La herramienta aun se encuentra en fase de desarollo...${RESET}"
            #read -rp "Ingrese el SN de la HN: " SN
            # Llamamos a la función para obtener la IP de la BMC usando el SN
            #get_k2v4_ip_from_sn "$SN"
            ;;
        19)
        # Recopilación de sugerencias y errores
            echo -e "${BLUE}============================================${RESET}"
            echo -e "${YELLOW}        Sugerencia de Nuevas Tools          ${RESET}"
            echo -e "${BLUE}============================================${RESET}"
            usuario=$(logname)

            # Solicitar turno y validar entrada
            while true; do
                echo -ne "${CYAN}Turno (1, 2, 3, 4, 5 o 1ro, 2do, 3ro, 4to, 5to): ${RESET}"
                read turno
                case "$turno" in
                    1|2|3|4|5|1ro|2do|3ro|4to|5to) break ;;  # Acepta tanto números como "ro", "do", etc.
                    *) echo -e "${RED}❌ Turno no válido. Ingresa uno de los siguientes: 1, 2, 3, 4, 5 o 1ro, 2do, 3ro, 4to, 5to${RESET}" ;;
                esac
            done

            # Preguntar sugerencia
            echo -e "Escribe tu sugerencia. Cuando termines, presiona [ENTER]: "
            read -e sugerencia

            # Confirmar si quiere agregar más detalle
            echo -e "${YELLOW}¿Deseas agregar más detalles? (s/n)${RESET}"
            read -n 1 mas_detalle
            echo ""
            if [[ "$mas_detalle" == "s" || "$mas_detalle" == "S" ]]; then
                echo -e "Escribe los detalles adicionales (puedes usar varias líneas).: "
                echo -e "${YELLOW}Cuando termines, presiona Ctrl+D:${RESET}"
                detalles=$(</dev/stdin)
            else
                detalles="N/A"
            fi

            # Crear carpeta viernesLogs si no existe (desde /home/MW23090133)
            base_dir="/home/MW23090133"
            log_dir="$base_dir/gnw/viernesLogs"

            cd "$base_dir" || { echo -e "${RED}❌ Error: No se pudo acceder a $base_dir${RESET}"; exit 1; }
            if [ ! -d "$log_dir" ]; then
                mkdir -p "$log_dir"
            fi

            # Guardar sugerencia
            log_path="$log_dir/sugerencias.log"
            {
                echo "--------------------------------------------"
                echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
                echo "Usuario:   $usuario"
                echo "Sugerencia: $sugerencia"
                echo "Detalles: $detalles"
                echo ""
            } >> "$log_path"

            echo -e "${GREEN}✅ ¡Gracias! Tu sugerencia ha sido registrada correctamente.${RESET}"
            registrar_uso "19 (Sugerencias)" "NA" "NA"

            ;;
        20)
            # Node Information - Buscar nodo en C4
            read -rp "Ingrese el SN de la unidad a buscar: " SN

            # Cambiar al directorio de trabajo
            cd /mnt/gv2/mfg_gen2_teton2/mfg

            # Obtener la IP del servidor PostgreSQL desde el archivo .env
            ip_db=$(grep POSTGRES_IP .env | head -n 1 | cut -d'=' -f2)

            # Obtener datos del nodo desde la API
            data=$(curl -s -X GET "http://$ip_db:9860/v1/nodes/$SN" -H "accept: application/json")

            # Verificar si se obtuvo información válida
            if [[ -z "$data" || "$data" == "null" ]]; then
                echo -e "${RED}❌ La unidad no se encuentra corriendo en este cluster.${RESET}"
                return
            fi

            # Extraer información del JSON usando jq
            rack=$(echo "$data" | jq -r '.container_serial_num')
            no_rack=$(echo "$data" | jq -r '.container_location')
            test_block=$(echo "$data" | jq -r '.stage')
            test_id=$(echo "$data" | jq -r '.test_state')
            status=$(echo "$data" | jq -r '.state')
            partnumber=$(echo "$data" | jq -r '.part_num')
            test_case_name=$(echo "$data" | jq -r '.test_case_name')

            # Verificar si alguna de las variables clave es null y mostrar mensaje adecuado
            if [[ "$rack" == "null" || "$no_rack" == "null" || "$test_block" == "null" || "$test_id" == "null" || "$status" == "null" || "$partnumber" == "null" || "$test_case_name" == "null" ]]; then
                echo -e "${RED}❌   La unidad no se encuentra corriendo en este cluster.${RESET}"
                return
            fi

            # Mostrar la información del nodo con colores
            echo -e "\n${CYAN}📦 Información del nodo:${RESET}"
            echo -e "${BLUE}Rack SN           :${RESET} $rack"
            echo -e "${BLUE}Ubicación Rack    :${RESET} $no_rack"
            echo -e "${BLUE}Stage de prueba   :${RESET} $test_block"
            echo -e "${BLUE}Estado de prueba  :${RESET} $test_id"
            echo -e "${BLUE}Estado del nodo   :${RESET} $status"
            echo -e "${BLUE}Part Number       :${RESET} $partnumber"
            echo -e "${BLUE}Test Case actual  :${RESET} $test_case_name"

            # Llamar a la función get_bmc_ip_debug2 para obtener la IP BMC
            get_bmc_ip_debug2 "$SN"

            # Verificar si la IP BMC está disponible
            if ping -c 1 "$bmc_ip" &> /dev/null; then
                echo -e "${GREEN}✔️   La unidad tiene BMC estable. Está conectada ahora mismo.${RESET}"
            else
                echo -e "${RED}❌   No se pudo establecer conexión con la BMC de la unidad.${RESET}"
            fi

            ;;
        21)
            # Registrar el uso de la opción 17
            registrar_uso "20 (Salida)" "NA" "NA"
            echo -e "${RED}Saliendo...${RESET}"
            echo -e "${RED}Te espero de nuevo pronto !!...${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opción inválida. Intente de nuevo.${RESET}"
            registrar_uso "Opción Inválida" "NA" "NA"
            ;;
    esac
    read -rp "Presione Enter para continuar..."
done
