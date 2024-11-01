#!/bin/bash

# Display the script name in ASCII art
echo -e "
  ██╗  ██╗███████╗███████╗██╗    ██╗██╗███████╗ █████╗ ██████╗ ██████╗ 
  ╚██╗██╔╝██╔════╝██╔════╝██║    ██║██║╚══███╔╝██╔══██╗██╔══██╗██╔══██╗
   ╚███╔╝ ███████╗███████╗██║ █╗ ██║██║  ███╔╝ ███████║██████╔╝██║  ██║
   ██╔██╗ ╚════██║╚════██║██║███╗██║██║ ███╔╝  ██╔══██║██╔══██╗██║  ██║
  ██╔╝ ██╗███████║███████║╚███╔███╔╝██║███████╗██║  ██║██║  ██║██████╔╝
  ╚═╝  ╚═╝╚══════╝╚══════╝ ╚══╝╚══╝ ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ 
"
                                                                    


# Function to check if a command exists
function command_exists {
    command -v "$1" >/dev/null 2>&1
}

# Function to install a Go tool if not present
function install_go_tool {
    local tool_name=$1
    local install_cmd=$2
    if ! command_exists $tool_name; then
        echo -e "\033[1;34mInstalling $tool_name...\033[0m"
        eval $install_cmd
        if [ $? -ne 0 ]; then
            echo -e "\033[1;31mFailed to install $tool_name. Please check your Go installation and path.\033[0m"
            exit 1
        fi
        echo -e "\033[1;32m$tool_name installed successfully.\033[0m"
    fi
}

# Function to install a Python package if not present
function install_python_tool {
    local tool_name=$1
    local install_cmd=$2
    if ! command_exists $tool_name; then
        echo -e "\033[1;34mInstalling $tool_name...\033[0m"
        eval $install_cmd
        if [ $? -ne 0 ]; then
            echo -e "\033[1;31mFailed to install $tool_name. Please check your Python installation and pip configuration.\033[0m"
            exit 1
        fi
        echo -e "\033[1;32m$tool_name installed successfully.\033[0m"
    fi
}

# Function to install a general tool if not present
function install_tool {
    local tool_name=$1
    local install_cmd=$2
    if ! command_exists $tool_name; then
        echo -e "\033[1;34mInstalling $tool_name...\033[0m"
        eval $install_cmd
        if [ $? -ne 0 ]; then
            echo -e "\033[1;31mFailed to install $tool_name.\033[0m"
            exit 1
        fi
        echo -e "\033[1;32m$tool_name installed successfully.\033[0m"
    fi
}

# Install required Go tools if not already installed
install_go_tool "waybackurls" "go install github.com/tomnomnom/waybackurls@latest"
install_go_tool "gau" "go install github.com/lc/gau/v2/cmd/gau@latest"
install_go_tool "anew" "go install github.com/tomnomnom/anew@latest"
install_go_tool "subfinder" "go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
install_go_tool "httpx" "go install github.com/projectdiscovery/httpx/cmd/httpx@latest"
install_go_tool "gospider" "go install github.com/jaeles-project/gospider@latest"
install_go_tool "hakrawler" "go install github.com/hakluke/hakrawler@latest"
install_go_tool "katana" "go install github.com/projectdiscovery/katana/cmd/katana@latest"
install_go_tool "dalfox" "go install github.com/hahwul/dalfox/v2@latest"

# Install gf if not already installed
install_tool "gf" "go install github.com/tomnomnom/gf@latest && cp -r $GOPATH/src/github.com/tomnomnom/gf/examples ~/.gf"

# Step 1: Accept the domain name from the user
echo -e "\033[1;34mEnter the domain name:\033[0m"
read domain

# Step 1.5: Ask if user wants to provide a custom payload list for dalfox
echo -e "\033[1;34mDo you want to provide a custom payload list for dalfox? (y/n):\033[0m"
read provide_custom_payload

if [ "$provide_custom_payload" == "y" ]; then
    echo -e "\033[1;34mEnter the path to the custom payload list:\033[0m"
    read custom_payload_path
fi

# Create results and domain subfolder
mkdir -p results/$domain

# Flag to indicate if any step needs to be rerun
rerun_steps=false

# Step 2: Run waybackurls if file is missing
if [ ! -f results/$domain/wayback.txt ]; then
    echo -e "\033[1;33mGenerating wayback.txt...\033[0m"
    echo $domain | waybackurls | anew results/$domain/wayback.txt
    rerun_steps=true
fi

# Step 3: Run gau if file is missing
if [ ! -f results/$domain/gau.txt ] || [ "$rerun_steps" = true ]; then
    echo -e "\033[1;33mGenerating gau.txt...\033[0m"
    echo $domain | gau | anew results/$domain/gau.txt
    rerun_steps=true
fi

# Step 4: Run subfinder if file is missing
if [ ! -f results/$domain/subdomains.txt ] || [ "$rerun_steps" = true ]; then
    echo -e "\033[1;33mGenerating subdomains.txt...\033[0m"
    subfinder -d $domain -o results/$domain/subdomains.txt
    rerun_steps=true
fi

# Step 5: Run httpx if file is missing
if [ ! -f results/$domain/activesubs.txt ] || [ "$rerun_steps" = true ]; then
    echo -e "\033[1;33mGenerating activesubs.txt...\033[0m"
    httpx -l results/$domain/subdomains.txt -o results/$domain/activesubs.txt -threads 200 -silent -follow-redirects
    rerun_steps=true
fi

# Step 6: Run gospider if file is missing
if [ ! -f results/$domain/gospider.txt ] || [ "$rerun_steps" = true ]; then
    echo -e "\033[1;33mGenerating gospider.txt...\033[0m"
    gospider -S results/$domain/activesubs.txt -c 10 -d 5 -t 20 --blacklist ".(jpg|jpeg|gif|css|tif|tiff|png|ttf|woff|woff2|ico|pdf|svg|txt|js)" --other-source --timeout 10 | grep -e "code-200" | awk '{print $5}' | grep "=" | grep $domain | anew results/$domain/gospider.txt
    rerun_steps=true
fi

# Step 7: Run hakrawler if file is missing
if [ ! -f results/$domain/hakrawler.txt ] || [ "$rerun_steps" = true ]; then
    echo -e "\033[1;33mGenerating hakrawler.txt...\033[0m"
    cat results/$domain/activesubs.txt | hakrawler -d 10 | grep "$domain" | grep "=" | egrep -iv ".(jpg|jpeg|gif|css|tif|tiff|png|ttf|woff|woff2|ico|pdf|svg|txt|js)" | anew results/$domain/hakrawler.txt
    rerun_steps=true
fi

# Step 8: Run katana if file is missing
if [ ! -f results/$domain/katana.txt ] || [ "$rerun_steps" = true ]; then
    echo -e "\033[1;33mGenerating katana.txt...\033[0m"
    katana -list results/$domain/activesubs.txt -f url -d 10 -o results/$domain/katana.txt
    rerun_steps=true
fi

# Step 9: Merge results and remove duplicates if paths.txt is missing
if [ ! -f results/$domain/paths.txt ] || [ "$rerun_steps" = true ]; then
    echo -e "\033[1;33mMerging results...\033[0m"
    cat results/$domain/{wayback.txt,gau.txt,gospider.txt,hakrawler.txt,katana.txt} | anew results/$domain/paths.txt
fi

# Step 10: Run dalfox if paths.txt exists and user provided a payload list
if [ -f results/$domain/paths.txt ]; then
    if [ "$provide_custom_payload" == "y" ]; then
        echo -e "\033[1;33mRunning dalfox with custom payload...\033[0m"
        dalfox file results/$domain/paths.txt -p $custom_payload_path | tee results/$domain/dalfox.txt
    else
        echo -e "\033[1;33mRunning dalfox with default payload...\033[0m"
        dalfox file results/$domain/paths.txt | tee results/$domain/dalfox.txt
    fi
else
    echo -e "\033[1;31mNo paths found to scan with dalfox.\033[0m"
fi

echo -e "\033[1;32mDone! All results are saved in results/$domain/\033[0m"
