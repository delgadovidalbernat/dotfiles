# Bernat's Dotfiles

Este repositorio contiene mis configuraciones personales para i3, tmux, bash, AWS, SSH y otras herramientas en Arch Linux.

## Características

- Configuraciones de i3, i3status
- Configuración de tmux optimizada
- Archivos de bash (.bashrc, .bash_profile, .bash_aliases)
- Encriptación de archivos sensibles con git-crypt
- Script de instalación automático
- Soporte para AWS CLI y Docker
- Integración con mi configuración de Neovim (en un repositorio externo)

## Instalación

1. Clona el repositorio:

```bash
git clone <url-del-repositorio> ~/dotfiles
cd ~/dotfiles
```

2. Si es la primera vez que usas este repositorio, configura git-crypt:

```bash
./setup-git-crypt.sh
```

3. Desbloquea los archivos encriptados (si ya has configurado git-crypt):

```bash
git-crypt unlock
```

4. Ejecuta el script de instalación:

```bash
./install.sh
```

## Archivos encriptados

Los siguientes archivos están encriptados con git-crypt:

- Claves SSH en `.ssh/`
- Credenciales de AWS en `.aws/`
- Cualquier archivo con extensión `.key`, `.pem` o `.secret`
- Todo en la carpeta `secrets/`

## Estructura del repositorio

```
dotfiles/
├── .gitattributes       # Configura qué archivos se encriptan
├── .gitignore           # Archivos ignorados por git
├── README.md            # Este archivo
├── install.sh           # Script principal de instalación
├── setup-git-crypt.sh   # Script para configurar git-crypt
├── i3/                  # Configuración de i3
│   ├── config
│   └── i3status.conf
├── tmux/                # Configuración de tmux
│   └── .tmux.conf
├── bash/                # Configuración de bash
│   ├── .bashrc
│   ├── .bash_profile
│   └── .bash_aliases
├── .ssh/                # Archivos SSH (encriptados)
├── .aws/                # Configuración de AWS (encriptada)
└── .Xresources          # Configuración de X
```

## Nvim

Este repositorio no incluye directamente la configuración de Neovim. En su lugar, el script de instalación clona mi configuración de Neovim desde:

```
git@github.com:delgadovidalbernat/nvim.git
```

## Customización

Puedes personalizar cualquier archivo de configuración después de la instalación. Como los archivos son enlaces simbólicos a este repositorio, cualquier cambio que hagas se guardará automáticamente aquí.

## Agregar nuevos usuarios

El script de instalación puede crear un usuario llamado "berni" durante la configuración. Si necesitas más usuarios, puedes modificar el script o ejecutar:

```bash
sudo useradd -m -G wheel -s /bin/bash nombre_usuario
sudo passwd nombre_usuario
```

## Dependencias

El script de instalación verificará e instalará las siguientes dependencias:

- i3
- tmux
- git
- git-crypt
- xterm
- Docker (opcional)
- AWS CLI v2 (opcional)

## Seguridad

- Nunca desbloquees este repositorio en un sistema compartido
- Cambia regularmente tus claves y actualiza los archivos encriptados
- Usa contraseñas fuertes para tu clave GPG
