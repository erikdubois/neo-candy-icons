# A Neo candy Icon Theme

![filemanager](https://github.com/erikdubois/neo-candy-icons/blob/main/sample/filemanager.png)

![menu](https://github.com/erikdubois/neo-candy-icons/blob/main/sample/menu.png)

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
  - [Automatic Installation](#automatic-installation)
  - [Manual Installation](#manual-installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgements](#acknowledgements)
- [Contact](#contact)

## Overview

Neo Candy Icon Theme is a vibrant and visually appealing icon theme designed to enhance the aesthetic experience of your desktop environment. This theme is meticulously crafted to ensure consistency and beauty across all icons, making your system look cohesive and elegant.

## Features

- **High-Quality Icons:** Each icon is designed with attention to detail to ensure a crisp and clear appearance at any size.
- **Wide Coverage:** Includes icons for a wide range of applications and file types.
- **Consistent Style:** All icons follow a unified design language for a harmonious look.
- **Regular Updates:** Continuously updated to include icons for new applications and to refine existing ones.

## Installation

### Automatic Installation

Add this to your pacman.conf

```
[nemesis_repo]
SigLevel = PackageRequired DatabaseNever
Server = https://erikdubois.github.io/$repo/$arch
```
For users who prefer an automated installation process, you can use then pacman:

1. **Use pacman:**
    ```bash
    sudo pacman -S neo-candy-icons
    ```

### Manual Installation

For users who prefer manual installation, follow these steps:

1. **Download the latest release**
2. **Extract the downloaded archive** to your icon directory:
    When on ArcoLinux...
    ```bash
    ex neo-candy-icons-25.04-01.tar.gz
    ```
    or
    ```bash
    unzip neo-candy-icons-25.04-01.tar.gz
    ```
    Move the 3 folders of /usr/share/icons to your ~/.icons folder (create the .icons folder if it does not exist).
    When on Plasma move the 3 folders to ~/.local/share/icons (create the icons folder if it does not exist )
4. **Set the icon theme** using your desktop environment’s settings manager.

## Usage

After installation, you can activate the Neo Candy Icon Theme through your desktop environment's appearance settings. The exact steps may vary depending on the desktop environment you are using (GNOME, KDE, XFCE, etc.).

### GNOME

1. Open **GNOME Tweaks**.
2. Go to the **Appearance** section.
3. Under the **Icons** dropdown, select **Neo Candy Icon Theme**.

### KDE

1. Open **System Settings**.
2. Navigate to **Appearance** > **Icons**.
3. Select **Neo Candy Icon Theme** from the list.

### XFCE

1. Open **Settings Manager**.
2. Go to **Appearance** > **Icons**.
3. Choose **Neo Candy Icon Theme** from the list.

### TWMs

Use lxappearance to change your icon theme.

## Contributing

We welcome contributions from the community! Whether you want to suggest new icons, report bugs, or improve existing ones, your input is valuable.

### Steps to Contribute

1. **Fork the repository.**
2. **Create a new branch:**
    ```bash
    git checkout -b feature-name
    ```
3. **Make your changes** and commit them with a descriptive message:
    ```bash
    git commit -m "Description of changes"
    ```
4. **Push your changes** to your forked repository:
    ```bash
    git push origin feature-name
    ```
5. **Open a pull request** on the original repository.

### Reporting Issues

If you encounter any issues or have suggestions, please open an issue on the [GitHub Issues](https://github.com/erikdubois/neo-candy-icons/issues) page.

## License

This project is licensed under the License file of the different projects it is based on. See the LICENSE file in the different folders for more details.

## Acknowledgements

- Special thanks to the ArcoLinux community for their support and contributions.
- Inspired by various open-source icon themes available in the community.
- Beautyline - https://www.opendesktop.org/p/1425426/
- Candy - https://www.pling.com/p/1305251/
- Garuda Beautyline - https://gitlab.com/garuda-linux/themes-and-settings/artwork/beautyline
