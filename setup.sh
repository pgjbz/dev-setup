#!/usr/bin/bash

vpn_installer="snx_install_linux30.sh"
initial_path=$(pwd)
code_deb="https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
vscode_deb="vscode.deb"

info() {
    local msg=$1
    echo "INFO: $msg"
}

getPackageManager() {
   declare -A osInfo;
    osInfo[/etc/redhat-release]=yum
    osInfo[/etc/arch-release]=pacman
    osInfo[/etc/gentoo-release]=emerge
    osInfo[/etc/SuSE-release]=zypp
    osInfo[/etc/debian_version]=apt-get

    for f in ${!osInfo[@]}
    do
        if [[ -f $f ]];then
            echo ${osInfo[$f]}
        fi
    done
}

upgradeDebian() {
    local root_pass=$1
	echo "$root_password"|sudo -S apt update 
	echo "$root_password"|sudo -S apt upgrade -y

}

installPackagesDebian() {
    local root_pass=$1
    packs="wget curl git"
    echo $root_pass | sudo -S add-apt-repository ppa:git-core/ppa
	upgradeDebian
	echo "$root_password"|sudo -S apt install $packs -y
}

installCodeDebian() {
    local root_pass=$1
    finalPath=$initial_path/$vscode_deb
    info "download $code_deb in $finalPath"
    wget $code_deb -O "$finalPath"
    info "installing VSCode"
    echo $root_pass | sudo -S dpkg -i $finalPath
    rm $finalPath
    declare -a extensions
    extensions[0]=SonarSource.sonarlint-vscode
    extensions[1]=redhat.fabric8-analytics
    extensions[2]=usernamehw.errorlens
    extensions[3]=vscjava.vscode-java-pack
    extensions[4]=eamodio.gitlens
    extensions[5]=GabrielBB.vscode-lombok
    extensions[6]=Pivotal.vscode-boot-dev-pack
    extensions[7]=rangav.vscode-thunder-client
    extensions[8]=redhat.vscode-xml
    extensions[9]=cweijan.vscode-database-client2
    extensions[10]=geeebe.duplicate
    for ext in ${extensions[@]}
    do
        info "install VSCode extension $ext"
        code --install-extension "$ext" --force
    done
}

grantDockerWithoutSudo() {
    local root_pass=$1
    echo $root_pass | sudo -S groupadd docker
    echo $root_pass | sudo -S usermod -aG docker $USER
    newgrp docker 
}

dockerPostInstall() {
    local root_pass=$1
    echo $root_pass | sudo -S groupadd docker
    echo $root_pass | sudo -S usermod -aG docker $USER
}

installDockercompose() {
    local root_pass=$1
    info "install docker-compose"
    echo $root_pass | sudo -S curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    echo $root_pass | sudo -S chmod +x /usr/local/bin/docker-compose
}

installDockerDebian() {
    local root_pass=$1
    info "install docker"
    containerdFile=containerd.io_1.4.9-1_amd64.deb
    containerdFinalPath=$initial_path/$containerdFile
    containerdUrl=https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/$containerdFile
    wget $containerdUrl -O $containerdFinalPath 

    dockerCliFile=docker-ce-cli_20.10.9~3-0~ubuntu-focal_amd64.deb
    dockerCliFinalPath=$initial_path/$dockerCliFile
    dockerCliUrl=https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/$dockerCliFile
    wget $dockerCliUrl -O $dockerCliFinalPath 

    dockerCeFile=docker-ce_20.10.9~3-0~ubuntu-focal_amd64.deb
    dockerCeFinalPath=$initial_path/$dockerCeFile
    dockerCeUrl=https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/$dockerCeFile
    wget $dockerCeUrl -O $dockerCeFinalPath 

    echo $root_pass | sudo -S dpkg -i $containerdFinalPath
    echo $root_pass | sudo -S dpkg -i $dockerCliFinalPath 
    echo $root_pass | sudo -S dpkg -i $dockerCeFinalPath
    echo $root_pass | sudo -S systemctl start docker
    echo $root_pass | sudo -S systemctl enable docker
    rm $containerdFinalPath
    rm $dockerCliFinalPath
    rm $dockerCeFinalPath
    installDockercompose
}

installDebian() {
    local root_pass=$1
    installPackagesDebian $root_pass
    installCodeDebian $root_pass
    installDockerDebian $root_pass
}

asdfInfos() {
    info "asdf java global is adoptopenjdk-11.0.14+101 to change local use 'asdf local java #version' or 'asdf global java #version' to change globally"
    info "'asdf list java' to show java versions installed"
    info "asdf nodejs global is lst to change local use 'asdf local nodejs #version' or 'asdf global nodejs #version' to change globally"
    info "'asdf list nodejs' to show java versions installed"
    info "asdf maven global is 3.6.3 to change local use 'asdf local maven #version' or 'asdf global maven #version' to change globally"
    info "'asdf list maven' to show java versions installed"
}

installAdsfExtensions() {
    asdf plugin-add java
    asdf plugin-add maven
    asdf plugin-add nodejs
}

asdfInstallVersions() {
    asdf install nodejs lts
    asdf global nodejs lts
    asdf install maven 3.6.3
    asdf global maven 3.6.3
    asdf install java adoptopenjdk-11.0.14+101
    asdf install java adoptopenjdk-8.0.322+6
    asdf global java adoptopenjdk-11.0.14+101
    echo ". ~/.asdf/plugins/java/set-java-home.bash" >> ~/.bashrc
}

installAsdf() {
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.9.0
    echo ". $HOME/.asdf/asdf.sh" >> $HOME/.bashrc
    echo ". $HOME/.asdf/completions/asdf.bash" >> $HOME/.bashrc
    . $HOME/.asdf/asdf.sh
    installAdsfExtensions
    asdfInstallVersions
}

run() {
    read -sp 'enter root password: ' root_password
    echo
    case $(getPackageManager) in
        "apt-get") installDebian $root_password;;
        *) echo "unsupported distro"
            exit;;
    esac

    info "install dev tools"
    installAsdf
    asdfInfos
}

run