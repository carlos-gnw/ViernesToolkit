#!/bin/bash 

#===============================================================
#Developed by Carlos Sanchez WYMX | DEV Team
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

#==============================================================================

# Lista negra de usuarios (lognames) prohibidos
BLACKLIST=("MW24070098", "ML17120024")

# Obtener el logname actual (usuario que inició sesión)
CURRENT_USER=$(logname 2>/dev/null)

# Si no se puede obtener logname, usar whoami como fallback
if [ -z "$CURRENT_USER" ]; then
    CURRENT_USER=$(whoami)
fi

# Función para comprobar si un elemento está en la lista
is_in_blacklist() {
    local user="$1"
    for banned in "${BLACKLIST[@]}"; do
        if [ "$user" == "$banned" ]; then
            return 0  # Encontrado
        fi
    done
    return 1  # No encontrado
}

# Validar si el usuario está en la lista negra
if is_in_blacklist "$CURRENT_USER"; then
    echo -e "${RED} Acceso denegado para el usuario '${YELLOW}$CURRENT_USER${RED}'.${RESET}"
    echo -e "${BLUE}[INFO] Si requieres acceso, solicitarlo a ${CYAN}Aging Team 4to Turno${RESET} / ${LIGHT_PURPLE}Dev Team${RESET}"
    exit 1
fi


#==============================================================================
# Definir la ruta base
dir_base="/opt/test_tools/teton2/nitro-bmc-cli/"


#Funcion para registrar uso de viernes
registrar_uso() {
    local opcion="$1"
    local sn="$2"
    local ip="$3"
    local fecha=$(date +"%Y-%m-%d")
    local hora=$(date +"%H:%M:%S")
    local usuario=$(logname)
    local cluster=$(hostname)  # Obtener el nombre del host (cluster)

    local base_dir="/mnt/gv2/users/GNW/gnw/viernesLogs"
    local archivo_log="$base_dir/viernes_uso.csv"
    local webhook_url="https://script.google.com/macros/s/AKfycbxI7penhtxCvgMuzEwmtK00Jxc1MJFBJYqfJI3x_No7PPX55onJyj8Ra4H9YT0JN1tAng/exec" 

    # Crear directorio si no existe
    [[ -d "$base_dir" ]] || mkdir -p "$base_dir"

    # Agregar encabezado si no existe el archivo
    [[ -f "$archivo_log" ]] || echo "Fecha,Hora,Usuario,Opcion,SN,IP,Cluster" > "$archivo_log"  # Nueva columna Cluster

    # Guardar en archivo local
    echo "$fecha,$hora,$usuario,$opcion,$sn,$ip,$cluster" >> "$archivo_log"  # Guardar el valor de 'cluster'

    # Intentar envío a la nube una sola vez, en segundo plano, sin mostrar nada
    (curl -s --max-time 2 -X POST -H "Content-Type: application/json" \
        -d "{\"fecha\":\"$fecha\", \"hora\":\"$hora\", \"usuario\":\"$usuario\", \"opcion\":\"$opcion\", \"sn\":\"$sn\", \"ip\":\"$ip\", \"cluster\":\"$cluster\"}" \
        "$webhook_url" > /dev/null 2>&1) &
}

# Captura cierres de terminal / Ctrl+C
trap 'echo -e "\n${RED}Aplicación terminada abruptamente.${RESET}"; exit 1' SIGHUP SIGINT

# Función para obtener IP de K2V4 a partir del SN
get_k2v4_ip_from_sn() {
    local sn=$1
    cd /mnt/gv2/users/GNW
    k2v4_ip=$(./getip_viernes "$sn" | awk 'NR==2')
    cd /opt/test_tools/teton2/nitro-bmc-cli/
    export k2v4_ip
}
 
#Funcion de debug 2 para limpiar codigo de formato ANSI
get_bmc_ip_debug2() {
    local sn=$1
    cd /mnt/gv2/users/GNW
    # Extraer la IP eliminando posibles códigos de color
    export bmc_ip=$(./getip_viernes "$sn" | awk 'NR==1')
    cd /opt/test_tools/teton2/nitro-bmc-cli/
}

#Funcion de debug de la eth0 IP
get_eth0_ip_debug() {
    local sn=$1
    cd /mnt/gv2/users/GNW
    eth0_ip=$(./getip_viernes "$sn" | awk 'NR==3')
    export eth0_ip
    cd /opt/test_tools/teton2/nitro-bmc-cli/
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
    echo -e " \ \    / (_)            GNW Team            "
    echo -e "  \ \  / / _  ___ _ __ _ __   ___  ___ \e[31m"
    echo -e "   \ \/ / | |/ _ \ '__| '_ \ / _ \/ __|"
    echo -e "    \  /  | |  __/ |  | | | |  __/\__ \\"
    echo -e "     \/   |_|\___|_|  |_| |_|\___||___/ "
    echo -e "\e[0m"
    echo -e "${CYAN}────────────────────────────────────────────────────${RESET}"
    echo -e "${YELLOW} TETON 2 Tool | DEV TEAM - DEV Carlos Sanchez  ${RESET}"
    echo -e "${LIGHT_PURPLE}────────────────── L11 Tools ──────────────────${RESET}"
    echo -e "${GREEN}1) Activar K2V4${RESET}"
    echo -e "${GREEN}2) SW Autoconfig (Lengueta Morada/Naranja y Console)${RESET}"
    echo -e "${GREEN}3) Rack Information${RESET}"
    echo -e "${GREEN}4) PCIe Verification${RESET}"
    echo -e "${LIGHT_PURPLE}================= MLA Tools ===================${RESET}"
    echo -e "${GREEN}5) Ejecutar UART Tool${RESET}"
    echo -e "${GREEN}6) Proxy Cards Check (K2V5s and GPUs)${RESET}"
    echo -e "${GREEN}7) Verificacion de K2V5 card type${RESET}"
    #echo -e "${GREEN}8) Prueba de Cable Detect ALL Rack${RESET}"
    echo -e "${GREEN}8) Limpiar eventos (SEL Clear)${RESET}"
    echo -e "${GREEN}9) Mostrar Sensor List${RESET}"
    echo -e "${GREEN}10) Sel Clear + VPD${RESET}"
    echo -e "${GREEN}11) Imprimir FRU${RESET}"
    echo -e "${GREEN}12) Verificar BMC Network${RESET}"
    echo -e "${GREEN}13) Clear DHCP + VPD${RESET}"
    echo -e "${GREEN}14) Check IPV4 (extend)${RESET}"
    echo -e "${LIGHT_PURPLE}================= Power Status ================${RESET}"
    echo -e "${GREEN}15) BMC Reboot${RESET}"
    echo -e "${GREEN}16) Sol Activate${RESET}"
    echo -e "${LIGHT_PURPLE}============== Viernes Autodebug ============${RESET}"
    echo -e "${GREEN}17) Issue TT2_K2V4_KEG_SYNC${RESET}"
    echo -e "${LIGHT_PURPLE}================= Others =====================${RESET}"
    echo -e "${GREEN}18) Opnion/Sugerencias de Tools${GREEN}"
    echo -e "${GREEN}19) Node Information | Buscar unidad${GREEN}"
    echo -e "${RED}20) Salir${RESET}"
    echo -e "${CYAN}=================================================${RESET}"
    echo -e "${GREEN}    Last Update: January 31th, 2026${RESET}"
    echo -e "${GREEN}    Operating Since: February 06th, 2025${RESET}"
    echo -e "${CYAN}=================================================${RESET}"

    # Timeout de 180 segundos en el menú principal
    read -t 180 -rp "Selecciona una opción: " opcion || {
        echo -e "\n${RED}Sin actividad en el menú principal por 3 minutos. Cerrando Viernes...${RESET}"
        exit 0
    }

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
            output_sfc=$(bash /mnt/gv2/users/GNW/gnw/tools/toolsgnw/dbconsult.sh --GetDynamicData --usn="$SN_RACK" --value=DYN_POSITION_FIONA --name=USN)
            
            sw_mac1=$(echo "$output_sfc" | grep "Table19" -A 6 | awk -F '<|>' '/ETH0MAC/ {print $3}')
            sw_mac2=$(echo "$output_sfc" | grep "Table39" -A 6 | awk -F '<|>' '/ETH0MAC/ {print $3}')
            sw_sn1=$(echo "$output_sfc" | grep "Table19" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            sw_sn2=$(echo "$output_sfc" | grep "Table39" -A 6 | awk -F '<|>' '/CSN/ {print $3}')


            #Info para autoconfig de console
            console_sn=$(echo "$output_sfc" | grep "Table21" -A 6 | awk -F '<|>' '/CSN/ {print $3}')
            console_mac=$(echo "$output_sfc" | grep "Table21" -A 6 | awk -F '<|>' '/ETH0MAC/ {print $3}')

            # Verificar si se obtuvieron las MACs correctamente
            if [[ -z "$sw_mac1" || -z "$sw_mac2" || -z "$console_mac" ]]; then
                echo -e "${RED}Error: No se pudieron obtener las MACs de los switches.${RESET}"
                read -rp "Presione cualquier tecla para volver al menú principal... " -n1 -s
                continue
            fi

            # Obtener las IPs de los switches
            get_sw_ip "$sw_mac1"
            sw_ip1="$sw_ip"

            get_sw_ip "$sw_mac2"
            sw_ip2="$sw_ip"

            get_sw_ip "$console_mac"
            console_ip="$sw_ip"


            # Verificar si se obtuvieron las IPs correctamente
            if [[ -z "$sw_ip1" || -z "$sw_ip2" || -z "$console_ip" ]]; then
                echo -e "${RED}Error: No se pudieron obtener las IPs de los switches.${RESET}"
                echo -e "${BLUE}NOTA: Asegure IPs primero en ambos SW o reconfigure con cable CONSOLE.${RESET}"
                echo -e "${BLUE}NOTA: Si se trata de un rack fresh, por favor configure manualmente o con la lista de pruebas.${RESET}"
                read -rp "Presione cualquier tecla para volver al menú principal... " -n1 -s
            continue
            fi
            
            # Mostrar el submenú de selección de switch
            echo -e "${BLUE}Se detectaron los siguientes switchs:${RESET}"
            echo -e "--------------------------------------------------------------"
            echo -e "1) Switch 1 - MAC: $sw_mac1 - SN: $sw_sn1 - IP: $sw_ip1"
            echo -e "2) Switch 2 - MAC: $sw_mac2 - SN: $sw_sn2 - IP: $sw_ip2"
            opt_count=2

            # Si el console tiene SN válido (empieza con 4444), mostrar opción
            if [[ "$console_sn" == 4444* ]]; then
                echo -e "3) Console - MAC: $console_mac - SN: $console_sn - IP: $console_ip"
                opt_count=3
            else
                echo -e ""
                echo -e "${YELLOW}⚠️ Console detectado pero no configurable (SN: $console_sn).${RESET}"
                echo -e "${YELLOW}   Si el console es negro, entonces asegure conexión BMC en puertos 47/48.${RESET}"
            fi

            echo -e "--------------------------------------------------------------"
            echo -e "${YELLOW}ASEGURA LA CONEXION DE LOS SWITCHS DE LA SIG MANERA: ${RESET}"
            echo -e "--------------------------------------------------------------"
            echo -e "${YELLOW}🔔 FR:${RESET} SW BOT - Fibra 40G en puerto 9, Puente en puerto 10.${RESET}"
            echo -e "${YELLOW}🔔 FR:${RESET} SW TOP - Puente en puerto 9.${RESET}"
            echo -e "--------------------------------------------------------------"
            read -rp "Seleccione el dispositivo a configurar (1-${opt_count}): " sw_option

            # Asignar la IP correspondiente según la selección
            case $sw_option in
                1) SW_IP="$sw_ip1" ;;
                2) SW_IP="$sw_ip2" ;;
                3)
                    if [[ "$console_sn" != 4444* ]]; then
                        echo -e "${RED}Error: El console no es configurable. SN inválido: $console_sn${RESET}"
                        read -rp "Presione cualquier tecla para volver al menú principal... " -n1 -s
                        continue
                    fi
                    SW_IP="$console_ip"
                    ;;
                *)
                    echo -e "${RED}Opción inválida. Regresando al menú principal.${RESET}"
                    read -rp "Presione cualquier tecla para continuar... " -n1 -s
                    continue
                    ;;
            esac

            # Validación de conexión al switch seleccionado
            echo -e "${BLUE}Verificando conectividad con el dispositivo en la IP: $SW_IP...${RESET}"
            if ! ping -c 3 "$SW_IP" > /dev/null; then
                echo -e "${RED}El dispositivo no responde. Verifique la conexión IP.${RESET}"
                echo -e "${BLUE}NOTA: Asegure IPs primero en ambos SW/Console o reconfigure con cable CONSOLE.${RESET}"
                read -rp "Presione cualquier tecla para volver al menú principal... " -n1 -s
                continue
            fi

            # Determinar el SN del switch seleccionado
            if [[ "$sw_option" == "1" ]]; then
                SW_SN="$sw_sn1"
            elif [[ "$sw_option" == "2" ]]; then
                SW_SN="$sw_sn2"
            elif [[ "$sw_option" == "3" ]]; then
                SW_SN="$console_sn"
            else
                echo -e "${RED}Error inesperado: opción inválida de switch.${RESET}"
                continue
            fi

            # Configurar según el tipo de switch (8060 o C8260)
            echo -e "${BLUE}Configurando dispositivo ($SW_SN) en la IP: $SW_IP...${RESET}"
            echo -e "${BLUE}Utilizando ultimo integrador validado ... ${RESET}"
            if [[ "$SW_SN" == 8060* ]]; then
                # Switch tipo 8060
                ssh root@"$SW_IP" <<EOF
                    cd /bin
                    integrator_mode -m "1-2:4x10G;3-8:2x100G;9-12:40G;13-32:Copper_4x100G"
EOF
                echo -e "${GREEN}Configuración 8060 aplicada exitosamente.${RESET}"
            elif [[ "$SW_SN" == C8260* ]]; then
                # Switch tipo C8260
                ssh root@"$SW_IP" <<EOF
                    cd /root/sdk/R*
                    ./integrator_mode -d -m "1-2:Copper_4x10G;3-8:Copper_2x100G;9-12:Copper_1x40G;13-24:4x100G;25-32:Copper_4x100G"
EOF
                echo -e "${GREEN}Configuración C8260 aplicada exitosamente.${RESET}"

            elif [[ "$SW_SN" == 444* ]]; then
                # Console AZ444
                ssh root@"$SW_IP" <<EOF
                    integrator_mode -m "1-48:1G;49-52:10G"
EOF
                echo -e "${GREEN}Configuración AZ444 aplicada exitosamente.${RESET}"

            else
                echo -e "${YELLOW}Advertencia: SN del dispositivo no coincide con prefijos conocidos (8060. C8260, 444).${RESET}"
                echo -e "${RED}Configuración NO aplicada. Revise el SN manualmente: $SW_SN${RESET}"
                read -rp "Presione cualquier tecla para continuar... " -n1 -s
                continue
            fi

            # Registrar uso en CSV
            registrar_uso "2 (SW Autoconfig)" "$SN_RACK" "$SW_IP"
            ;;
        3)
        #Rack information, codigo pendiente desarollar en Wiwynn
            read -rp "Ingrese el SN del rack: " SN_RACK
            echo -e "${BLUE}Obteniendo Rack Information...${RESET}"
            echo -e "${BLUE}Espere un momento por favor !!...${RESET}"
            output_sfc=$(bash /mnt/gv2/users/GNW/gnw/tools/toolsgnw/dbconsult.sh --GetDynamicData --usn="$SN_RACK" --value=DYN_POSITION_FIONA --name=USN)
            
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
        # Verificación de Puerto PCIE - Funciona correctamente
        # Verificación de Puerto PCIE - Funciona correctamente
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
            sshpass -p 'password' ssh -o StrictHostKeyChecking=no root@"$eth0_ip" <<'EOF'
                # Definición de las variables directamente en la sesión SSH
                RED='\033[0;31m'
                GREEN='\033[0;32m'
                BLUE='\033[0;34m'
                YELLOW='\033[1;33m'
                CYAN='\033[0;36m'
                RESET='\033[0m'
                BOLD='\033[1m'

                HW_DEFINITION_PATH="/opt/mfg/projects/teton2pd/MP_L10.5/110-006747/golden/hw_def.yaml"

                PCIe_DEVICES_16X8=( 0000:6a:01.0 0000:6b:00.0 0000:6b:00.1 0000:6b:00.2 0001:6a:01.0 0001:6b:00.0
                                    0001:04:01.0 0001:05:00.0 0001:0a:00.0 0001:0c:00.0 0001:09:00.0 0001:12:00.0
                                    0001:04:05.0 0001:1a:00.0 0001:1f:00.0 0001:21:00.0 0001:1e:00.0 0001:27:00.0
                                    0001:6a:05.0 0001:6d:00.0 0001:72:00.0 0001:74:00.0 0001:71:00.0 0001:7A:00.0
                                    0001:ab:01.0 0001:ac:00.0 0001:B1:00.0 0001:B3:00.0 0001:B0:00.0 0001:B9:00.0
                                    0000:04:01.0 0000:05:00.0 0000:0a:00.0 0000:0c:00.0 0000:09:00.0 0000:12:00.0
                                    0000:04:05.0 0000:1a:00.0 0000:1f:00.0 0000:21:00.0 0000:1e:00.0 0000:27:00.0
                                    0000:6a:05.0 0000:6d:00.0 0000:72:00.0 0000:74:00.0 0000:71:00.0 0000:7A:00.0
                                    0000:ab:01.0 0000:ac:00.0 0000:B1:00.0 0000:B3:00.0 0000:B0:00.0 0000:B9:00.0)
                DEVICE_NAMES_16X8=( K2V4 K2V4 K2V4 K2V4 K2V4 K2V4 JBOG_0_ROOT_PORT JBOG_0_PEX_DSP JBOG_0_K2V5_S0
                                    JBOG_0_K2V5_S1 JBOG_0_MX2_S0 JBOG_0_MX2_S1 JBOG_1_ROOT_PORT JBOG_1_PEX_DSP
                                    JBOG_1_K2V5_S0 JBOG_1_K2V5_S1 JBOG_1_MX2_S0 JBOG_1_MX2_S1 JBOG_2_ROOT_PORT
                                    JBOG_2_PEX_DSP JBOG_2_K2V5_S0 JBOG_2_K2V5_S1 JBOG_2_MX2_S0 JBOG_2_MX2_S1
                                    JBOG_3_ROOT_PORT JBOG_3_PEX_DSP JBOG_3_K2V5_S0 JBOG_3_K2V5_S1 JBOG_3_MX2_S0
                                    JBOG_3_MX2_S1 JBOG_4_ROOT_PORT JBOG_4_PEX_DSP JBOG_4_K2V5_S0 JBOG_4_K2V5_S1
                                    JBOG_4_MX2_S0 JBOG_4_MX2_S1 JBOG_5_ROOT_PORT JBOG_5_PEX_DSP JBOG_5_K2V5_S0
                                    JBOG_5_K2V5_S1 JBOG_5_MX2_S0 JBOG_5_MX2_S1 JBOG_6_ROOT_PORT JBOG_6_PEX_DSP
                                    JBOG_6_K2V5_S0 JBOG_6_K2V5_S1 JBOG_6_MX2_S0 JBOG_6_MX2_S1 JBOG_7_ROOT_PORT
                                    JBOG_7_PEX_DSP JBOG_7_K2V5_S0 JBOG_7_K2V5_S1 JBOG_7_MX2_S0 JBOG_7_MX2_S1)
                PCIe_DEVICES_8X8=(0000:ab:05.0 0001:ab:05.0 0000:c1:00.0 0000:c1:00.1 0001:c1:00.0 0001:c1:00.1)
                DEVICE_NAMES_8X8=(K2XN K2XN K2XN-SSD K2XN-SSD K2XN-SSD K2XN-SSD)

                hw_definitions=$(cat "$HW_DEFINITION_PATH")

                check_pcie_device() {
                    local pcie_device="$1"
                    local device_name="$2"

                    expected_speed=$(echo "$hw_definitions" | grep "$pcie_device" -A 2 | grep -e Speed -e Width | awk '{print $2}' | head -n 1)
                    expected_width=$(echo "$hw_definitions" | grep "$pcie_device" -A 2 | grep -e Speed -e Width | awk '{print $2}' | tail -n 1)

                    current_speed=$(lspci -s "$pcie_device" -vvv | grep -i "LnkSta:" | awk '{print $3}')
                    current_width=$(lspci -s "$pcie_device" -vvv | grep -i "LnkSta:" | awk '{print $6}')

                    # Check Speed
                    if [ "$expected_speed" = "$current_speed" ]; then
                        echo -e "    ${GREEN}✓ SPEED OK${RESET} (${device_name}) -> $current_speed"
                    else
                        echo -e "    ${RED}✗ SPEED FAILED${RESET} (${device_name})"
                        echo -e "      ${YELLOW}Current:${RESET} $current_speed | ${YELLOW}Expected:${RESET} $expected_speed"
                    fi

                    # Check Width
                    if [ "$expected_width" = "$current_width" ]; then
                        echo -e "    ${GREEN}✓ WIDTH OK${RESET} (${device_name}) -> $current_width"
                    else
                        echo -e "    ${RED}✗ WIDTH FAILED${RESET} (${device_name})"
                        echo -e "      ${YELLOW}Current:${RESET} $current_width | ${YELLOW}Expected:${RESET} $expected_width"
                    fi
                    echo
                }

                clear
                echo -e "${BOLD}${CYAN}🔍 Iniciando verificación de puertos PCIe...${RESET}"
                echo "=============================================================="
                echo -e "${BOLD}K2XN / SSD${RESET}"
                echo "=============================================================="

                for i in "${!PCIe_DEVICES_8X8[@]}"; do
                    check_pcie_device "${PCIe_DEVICES_8X8[$i]}" "${DEVICE_NAMES_8X8[$i]}"
                done

                echo
                echo -e "${BOLD}JBOG Groups${RESET}"
                echo "=============================================================="

                for i in "${!PCIe_DEVICES_16X8[@]}"; do
                    device_name="${DEVICE_NAMES_16X8[$i]}"
                    jbog_group=$(echo "$device_name" | grep -o 'JBOG_[0-7]')

                    if [ "$jbog_group" != "$last_jbog_group" ]; then
                        echo
                        echo -e "${BLUE}🔹 Checking $jbog_group${RESET}"
                        echo "--------------------------------------------------------------"
                        last_jbog_group="$jbog_group"
                    fi

                    check_pcie_device "${PCIe_DEVICES_16X8[$i]}" "$device_name"
                done

                echo -e "${CYAN}✅ Verificación completada.${RESET}"
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
            cd /mnt/gv2/users/GNW/gnw/tools/toolscript
            bash proxycards_k2.sh "$k2v4_ip"

            echo -e "${BLUE}Verificando GPUs...${RESET}"
            # Ejecutar comando para verificar GPUs
            cd /mnt/gv2/users/GNW/gnw/tools/toolscript
            bash proxycards_mx.sh "$k2v4_ip"

            cd /opt/test_tools/teton2/nitro-bmc-cli/
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
        9)
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
        10)
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
        11)
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
        12)
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
        13)
        #Limpia el DHCP y ejecuta un VPD
            read -rp "Ingrese el SN de la HN: " SN
            # Llamamos a la función para obtener la IP de la BMC usando el SN
            get_k2v4_ip_from_sn "$SN"

            # Verificar si la IP de K2V4 se obtuvo correctamente
            if [ -z "$k2v4_ip" ]; then
                echo -e "${RED}Error: No se pudo obtener la IP de la K2V4 para el SN $SN.${RESET}"
                exit 1
            fi
            cd /opt/test_tools/teton2/nitro-bmc-cli/
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
        14)
        #Getip extend
            read -rp "Ingrese el SN de la unidad: " SN
            # Llamamos a la función para obtener la IP de la BMC usando el SN
            echo -e "${BLUE}Verificando IPV4 en el KIT...${RESET}"
            #getip --extend "$SN"


            # Cambiar al directorio de trabajo
            cd /mnt/gv2/mfg_gen2_teton2/mfg

            #Obtener la IP del servidor PostgreSQL desde el archivo .env
            ip_db=$(grep POSTGRES_IP .env | head -n 1 | cut -d'=' -f2)

            # Obtener datos del nodo desde la API
            data=$(curl -s -X GET "http://$ip_db:9860/v1/nodes/$SN" -H "accept: application/json")

            # Extraer información del JSON usando jq
    
            k2v4_ip=$(echo "$data" | jq -r '.extend.k2v4_ipv4')
            k2v4_mac=$(echo "$data" | jq -r '.extend.k2v4_mac')

            jbog0_sn=$(echo "$data" | jq -r '.extend.jbog_0_sn')
            jbog0_mac=$(echo "$data" | jq -r '.extend.jbog_0_mac')
            jbog0_ipv4=$(echo "$data" | jq -r '.extend.jbog_0_ipv4')

            jbog1_sn=$(echo "$data" | jq -r '.extend.jbog_1_sn')
            jbog1_mac=$(echo "$data" | jq -r '.extend.jbog_1_mac')
            jbog1_ipv4=$(echo "$data" | jq -r '.extend.jbog_1_ipv4')

            jbog2_sn=$(echo "$data" | jq -r '.extend.jbog_2_sn')
            jbog2_mac=$(echo "$data" | jq -r '.extend.jbog_2_mac')
            jbog2_ipv4=$(echo "$data" | jq -r '.extend.jbog_2_ipv4')

            jbog3_sn=$(echo "$data" | jq -r '.extend.jbog_3_sn')
            jbog3_mac=$(echo "$data" | jq -r '.extend.jbog_3_mac')
            jbog3_ipv4=$(echo "$data" | jq -r '.extend.jbog_3_ipv4')

            jbog4_sn=$(echo "$data" | jq -r '.extend.jbog_4_sn')
            jbog4_mac=$(echo "$data" | jq -r '.extend.jbog_4_mac')
            jbog4_ipv4=$(echo "$data" | jq -r '.extend.jbog_4_ipv4')

            jbog5_sn=$(echo "$data" | jq -r '.extend.jbog_5_sn')
            jbog5_mac=$(echo "$data" | jq -r '.extend.jbog_5_mac')
            jbog5_ipv4=$(echo "$data" | jq -r '.extend.jbog_5_ipv4')

            jbog6_sn=$(echo "$data" | jq -r '.extend.jbog_6_sn')
            jbog6_mac=$(echo "$data" | jq -r '.extend.jbog_6_mac')
            jbog6_ipv4=$(echo "$data" | jq -r '.extend.jbog_6_ipv4')

            jbog7_sn=$(echo "$data" | jq -r '.extend.jbog_7_sn')
            jbog7_mac=$(echo "$data" | jq -r '.extend.jbog_7_mac')
            jbog7_ipv4=$(echo "$data" | jq -r '.extend.jbog_7_ipv4')

            # Ping y color para K2V4 IP
            if ping -c 1 -W 1 "$k2v4_ip" &>/dev/null; then
                k2v4_ip_colored="${GREEN}${k2v4_ip}${RESET}"
            else
                k2v4_ip_colored="${RED}${k2v4_ip}${RESET}"
            fi

            echo -e "${YELLOW}-------------------------------------${RESET}"
            echo -e "${CYAN} EXTEND - IPV4 INFORMATION${RESET}"
            echo -e "${YELLOW}-------------------------------------${RESET}"

            # Mostrar K2V4 con color en IP
            echo -e "${YELLOW}K2V4:${RESET} IP: $k2v4_ip_colored | MAC: $k2v4_mac"

            # JBOGs info (lineal)
            echo -e "${YELLOW}JBOGs:${RESET}"
            for i in {0..7}; do
                sn_var="jbog${i}_sn"
                mac_var="jbog${i}_mac"
                ip_var="jbog${i}_ipv4"

                sn_val=${!sn_var}
                mac_val=${!mac_var}
                ip_val=${!ip_var}

                if [[ "$sn_val" != "null" && -n "$sn_val" ]]; then
                    # Validar ping en JBOG IP
                    if ping -c 1 -W 1 "$ip_val" &>/dev/null; then
                        ip_colored="${GREEN}${ip_val}${RESET}"
                    else
                        ip_colored="${RED}${ip_val}${RESET}"
                    fi
                    echo -e "  JB$i  | SN: $sn_val | MAC: $mac_val | IP: $ip_colored"
                else
                    echo -e "  JB$i  | ${RED}No presente o sin respuesta${RESET}"
                fi
            done

            echo -e "\n${GREEN} Lectura completa.${RESET}"
            echo -e "${YELLOW}-------------------------------------${RESET}"
            echo -e "${GREEN}WARNING: Informacion tomada del extend/monitor.${RESET}"
            echo -e "${GREEN}Las IPs pueden ser diferentes a las reales, debido a que el DHCP server${RESET}"
            echo -e "${GREEN}puede asignar nuevas IPs a las unidades. Favor de corroborar manualmente${RESET}"
            echo -e "${GREEN}en caso de que tengas una IP no pingeable con esta herramienta.${RESET}"
            echo -e "${YELLOW}-------------------------------------${RESET}"

            # Registrar el uso de la opción 17
            registrar_uso "17 (Verificar IPv4)" "$SN" "NA"
            cd /opt/test_tools/teton2/nitro-bmc-cli/
            ;;
        15)
        # Ejecutar un BMC reboot con validación de IP y confirmación del usuario
            read -rp "Ingrese el SN de la unidad: " SN
            get_bmc_ip_debug2 "$SN"

            # Verificar si se obtuvo una IP válida
            if [[ -z "$bmc_ip" || ! "$bmc_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                echo -e "${RED}Error: No se pudo obtener una IP válida para el SN ingresado.${RESET}"
                continue
            fi
            cd /opt/test_tools/teton2/nitro-bmc-cli/
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
        16)
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
            ./nitro-bmc -i "$bmc_ip" sol deactivate --coap -d 0
            ./nitro-bmc -i "$bmc_ip" sol activate --coap -d 0 
            ;;
        17)
        # FUNCION #1 - VIERNES AUTODEBUG CON PUSH KEG
        # Analiza el estado de sincronización de kegs y realiza VPD + push en caso de error
        
        # Colores
        RED="\033[0;31m"
        GREEN="\033[0;32m"
        CYAN="\033[0;36m"
        YELLOW="\033[1;33m"
        RESET="\033[0m"
            
        # Función PUSH KEG (solo si el VPD falló y K2IP está estable de nuevo)
        push_keg_files() {
            local k2ip=$1
            chmod 755 /opt/test_tools/teton2/keg/keg-install

            push_keg() {
                local keg_file="$1"
                local keg_name="$2"

                echo "Starting push the $keg_name by keg-install..."
                result=$(cd /opt/test_tools/teton2/keg && ./keg-install --keg "$keg_file" --ip "$k2ip")
                if echo "$result" | grep -q "Update successful!"; then
                    echo -e "${GREEN}[✔] Push exitoso: $keg_name${RESET}"
                else
                    echo -e "${RED}[✘] Push fallido: $keg_name${RESET}"
                fi
            }

            push_keg "/opt/test_fw/teton2/K2V4_KEG/CarbonAPI-aarch64-1.2.20250130.249927.keg_signed" "CarbonAPI-aarch64-1.2.20250130.249927.keg_signed"
            push_keg "/opt/test_fw/teton2/K2V4_KEG/k2-mega-aarch64.213932.0.keg_signed" "k2-mega-aarch64.213932.0.keg_signed"
            push_keg "/opt/test_fw/teton2/K2V4_KEG/pacific-aarch64-unknown-linux-musl-0.6886.0.keg_signed" "pacific-aarch64-unknown-linux-musl-0.6886.0.keg_signed"
            push_keg "/opt/test_fw/teton2/K2V4_KEG/Provisioning-mega-cbm-trn2-0.34039.0.keg_signed" "Provisioning-mega-cbm-trn2-0.34039.0.keg_signed"
            push_keg "/opt/test_fw/teton2/K2V4_KEG/FirmwareImages@mega-cbm-trn2_nsk-primary-0.66658.0.keg_signed" "FirmwareImages@mega-cbm-trn2_nsk-primary-0.66658.0.keg_signed"
            push_keg "/opt/test_fw/teton2/K2V4_KEG/computefirmware@aws.fb21i-rqimbx_mega.keg" "computefirmware@aws.fb21i-rqimbx_mega.keg"
            push_keg "/opt/test_fw/teton2/K2V4_KEG/carbon-mega-skyrock-toprock-pacific-0.292399.0.keg_signed" "carbon-mega-skyrock-toprock-pacific-0.292399.0.keg_signed"
        }

        # Función para ejecutar el proceso de DHCP Clear
        dhcp_clear() {
            # Verificar si se proporcionó la dirección IP como parámetro
            if [ -z "$1" ]; then
                echo "Error: Se debe proporcionar la dirección IP del K2v4 como parámetro."
                echo "Uso: dhcp_clear <K2V4_IP>"
                return 1
            fi
        
            # Asignar la dirección IP proporcionada a la variable k2v4_ipv4
            k2v4_ipv4=$1
            echo "Utilizando la IP K2v4: $k2v4_ipv4"
        
            # Contador de intentos para Clear DHCP
            for i in {1..3}; do
                echo "Limpiando DHCP, intento $i..."
                COAP="coap -O65001,0 --prettier --method GET --timeout 120 -m PUT"
            
                # Eliminar archivo dhcp.leases
                echo "Ejecutando: $COAP coaps+tcp://$k2v4_ipv4/api-v1/debug/utils/delete?file=/local/var/cordite/dhcp.leases"
                dhcp_leases=$(eval "$COAP coaps+tcp://$k2v4_ipv4/api-v1/debug/utils/delete?file=/local/var/cordite/dhcp.leases")
                echo "$dhcp_leases"
            
                # Eliminar archivo managed_cards.cbor
                echo "Ejecutando: $COAP coaps+tcp://$k2v4_ipv4/api-v1/debug/utils/delete?file=/local/var/managed_cards.cbor"
                managed_cards=$(eval "$COAP coaps+tcp://$k2v4_ipv4/api-v1/debug/utils/delete?file=/local/var/managed_cards.cbor")
                echo "$managed_cards"
            
                # Espera de 60 segundos
                echo "Durmiendo 60 segundos..."
                sleep 60
            done
        
            # Comando final para obtener proxy cards
            COAP="coap -O65001,0 -Y"
            echo "Ejecutando: $COAP coaps+tcp://$k2v4_ipv4/api-v1/host/proxy/cards -J"
            proxy_cards=$(eval "$COAP coaps+tcp://$k2v4_ipv4/api-v1/host/proxy/cards -J")
            echo "$proxy_cards" > proxy_cards.txt
        
            # Contar ocurrencias de "stock" y "cbm"
            stock_count=$(echo "$proxy_cards" | grep -o "stock" | wc -l)
            cbm_count=$(echo "$proxy_cards" | grep -o "cbm" | wc -l)
        
            # Verificación: siempre cuenta stock + cbm como 0
            def_value=0
            get_value=$((stock_count + cbm_count))
        
            if [ "$def_value" -eq "$get_value" ]; then
                echo "DHCP clear ejecutado correctamente y sin errores."
            else
                echo "Error: stock ($stock_count) + cbm ($cbm_count) no es igual a $def_value. Fallo en la verificación."
                return 1
            fi
        }
        
        
        # Función para realizar la segunda verificación de la sincronización de los kegs
        verificar_sincronizacion_kegs() {
            echo -e "${CYAN}Realizando segunda verificación de la sincronización de los kegs...${RESET}"
        
            for ((intento=0; intento<=limite; intento++)); do
                bandera=1
        
                for keg in "${keg_list[@]}"; do
                    url="coaps+tcp://$k2v4_ip/api-v2/packages/$keg"
                    respuesta=$($coap_cmd "$url" -J 2>/dev/null)
                    estado=$(echo "$respuesta" | jq -r '.running.cards_synced' 2>/dev/null)
        
                    if [[ "$estado" != "true" ]]; then
                        echo -e "${YELLOW}El estado de sincronización del keg '$keg' es: $estado${RESET}"
                        bandera=0
                    fi
                done
        
                if [[ $bandera -eq 1 ]]; then
                    echo -e "${GREEN}Todos los kegs están sincronizados correctamente. Prueba superada.${RESET}"
                    return 0
                elif [[ $intento -ge $limite ]]; then
                    echo -e "${RED}Algunos kegs no están sincronizados. Límite de reintentos alcanzado.${RESET}"
                    return 1
                else
                    echo -e "${YELLOW}Reintentando en 7 segundos... (Intento $intento)${RESET}"
                    sleep 7
                fi
            done
        }
        
        clean_up() {
            echo -e "${CYAN}[i] Limpiando archivos temporales...${RESET}"
            rm -f /tmp/push_log.txt /tmp/proxy_cards.txt  # Ejemplo de archivos temporales
            # Agregar aquí cualquier otro archivo temporal que quieras eliminar
        }

        trap clean_up EXIT

        # ========== SCRIPT PRINCIPAL ==========

        read -rp "Ingrese el SN de la unidad HN: " SN
        get_k2v4_ip_from_sn "$SN"

        keg_list=("CarbonAPI" "Carbon" "FirmwareImages" "K2" "pacific" "ComputeFirmware" "Provisioning")
        limite=15
        coap_cmd="coap -O65001,0"
        todo_ok=1

        echo -e "${CYAN}Hola, Soy Viernes y estoy analizando la falla.${RESET}"
        sleep 3
        echo -e "${CYAN}Me encuentro revisando el estado de sincronizacion del keg...${RESET}"

        for ((intento=0; intento<=limite; intento++)); do
            bandera=1

            for keg in "${keg_list[@]}"; do
                url="coaps+tcp://$k2v4_ip/api-v2/packages/$keg"
                respuesta=$($coap_cmd "$url" -J 2>/dev/null)
                estado=$(echo "$respuesta" | jq -r '.running.cards_synced' 2>/dev/null)

                if [[ "$estado" != "true" ]]; then
                    echo -e "${YELLOW}El estado de sincronización del keg '$keg' es: $estado${RESET}"
                    bandera=0
                fi
            done

            if [[ $bandera -eq 1 ]]; then
                echo -e "${GREEN}Todos los kegs están sincronizados correctamente. Prueba superada.${RESET}"
                # Terminar el script si todos los kegs están sincronizados
                echo -e "${GREEN}Proceso completado exitosamente. El script terminará ahora.${RESET}"
                echo -e "${GREEN}Favor de correr la unidad desde el case. RERUN TASK O RERUN FROM CASE${RESET}"
                exit 0
            elif [[ $intento -ge $limite ]]; then
                echo -e "${RED}Algunos kegs no están sincronizados. Límite de reintentos alcanzado.${RESET}"
                todo_ok=0
            else
                echo -e "${YELLOW}Reintentando en 7 segundos... (Intento $intento)${RESET}"
                sleep 7
            fi
        done

        if [[ $todo_ok -ne 1 ]]; then
            echo -e "${RED}Fallo: al menos un keg no se sincronizó correctamente.${RESET}"
            get_bmc_ip_debug2 "$SN"

            echo -e "${CYAN}Ejecutando Virtual Power Drain (VPD) en BMC IP: $bmc_ip...${RESET}"
            ./nitro-bmc -i "$bmc_ip" sel clear
            ./nitro-bmc -i "$bmc_ip" power off
            ./nitro-bmc -i "$bmc_ip" power virtualpowerdrain
        fi

        # Esperando que K2V4 IP vuelva a estar disponible...
        while true; do
            if ping -c 1 -W 1 "$k2v4_ip" > /dev/null; then
                echo -e "${GREEN}Por fin !!, K2V4 IP disponible: $k2v4_ip${RESET}"
                break
            else
                echo -e "${YELLOW}Esperando que K2V4 IP esté disponible...${RESET}"
                sleep 3
            fi
        done  # Aquí cerramos el 'while'
        echo -e "${YELLOW}Durmiendo 60 segundos..... zzzz ${RESET}"
        sleep 60
        echo -e "${YELLOW}Muy bien, ahora ejecutaremos push keg..... zzzz ${RESET}"
        push_keg_files "$k2v4_ip"  # Llamada a la función para subir KEGs

        echo -e "${GREEN}Todo el proceso se completó correctamente.${RESET}"

        # Llamada a dhcp_clear para limpiar el DHCP
        dhcp_clear "$k2v4_ip"
        echo -e "${YELLOW}Durmiendo 30 segundos..... zzzz ${RESET}"
        sleep 30
        # Segunda verificación de sincronización de los kegs después de limpiar DHCP
        if ! verificar_sincronizacion_kegs; then
            echo -e "${RED}La sincronización de los kegs no se completó con éxito después del DHCP clear.${RESET}"
        else
            echo -e "${GREEN}La sincronización de los kegs ha sido exitosa después del DHCP clear.${RESET}"
            echo -e "${GREEN}Favor de correr la unidad desde el case. RERUN TASK O RERUN FROM CASE${RESET}"
        fi

        echo -e "${GREEN}Todo el proceso se completó correctamente.${RESET}"
        registrar_uso "18 (Issue Keg Sync)" "$SN" "$k2v4_ip"
            ;;
        18)
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
            base_dir="/mnt/gv2/users/GNW"
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
        19)
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
                read -rp "Presione cualquier tecla para volver al menú principal... " -n1 -s
                continue
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
                read -rp "Presione cualquier tecla para volver al menú principal... " -n1 -s
                continue
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
                echo -e "${RED}❌   La unidad no tiene BMC estable. Puede estar desconectada.${RESET}"
            fi
            registrar_uso "20 (Buscar Nodo)" "$SN" "NA"
            ;;
        20)
            # Registrar el uso de la opción 17
            registrar_uso "21 (Salida)" "NA" "NA"
            echo -e "${RED}Saliendo...${RESET}"
            echo -e "${RED}Gracias por usar VIERNES !!...${RESET}"
            echo -e "${RED}Siempre primera !.. !!...${RESET}"
            echo -e "${RED}Te espero de nuevo pronto !!...${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opción inválida. Intente de nuevo.${RESET}"
            read -t 30 -rp "Presione Enter para continuar... (30s timeout) " || {
                echo -e "\n${RED}Sin actividad. Cerrando Viernes...${RESET}"
                exit 0
            }
            ;;
    esac
    # Pausa centralizada con timeout para opciones válidas (excepto salir)
    if [[ "$opcion" != "20" && "$opcion" -le 20 && "$opcion" =~ ^[0-9]+$ ]]; then
        read -t 30 -rp "Presione Enter para continuar... (30s timeout) " || {
            echo -e "\n${RED}Sin actividad. Cerrando Viernes...${RESET}"
            exit 0
        }
    fi
done
