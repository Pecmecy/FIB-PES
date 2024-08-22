# PowerPathFinder
The main repo of power path finder, contains docker files and other pipeline configs

## Project Setup
### VSCode
- IDE: https://code.visualstudio.com/#alt-downloads
- Extensiones:
1. Abrid el repo/carpeta PowerPathFinder con VSCode
2. Abrid la seccion de extensiones
3. Copiad y pegad los siguientes nombres de extension en la barra de busqueda:
```
ms-azuretools.vscode-docker Dart-Code.flutter Dart-Code.dart-code GitHub.copilot GitHub.copilot-chat GitHub.vscode-pull-request-github Gruntfuggly.todo-tree ms-python.python ms-python.pylint ms-python.debugpy ms-python.black-formatter ms-python.vscode-pylance ms-python.mypy-type-checker  
```
![image](https://github.com/pes2324q2-gei-upc/PowerPathFinder/assets/75203757/7e479d8b-4d1c-47fb-9e85-fb2b351a2628)

4. Instalad todas las que aparezcan

---

### Docker
**Los de macOS y Windows os toca apechugar con Docker Desktop**
- **macOS** https://docs.docker.com/desktop/install/mac-install/
- **Windows** https://docs.docker.com/desktop/install/windows-install/

### Python
#### _Instalar Python3.12_
- Windows https://www.python.org/downloads/windows/
- macOS   https://www.python.org/downloads/macOS/
- Linux:  https://www.linuxcapable.com/install-python-3-12-on-ubuntu-linux/

En una terminal ejecutad `python -v` y assegurad que ejecutais la 3.12

#### _Instalar y crear venv_

- Abrid una terminal en el repo PowerPathFinder

```bash
python -m venv .venv

# Linux
source venv/bin/activate

# Windows (no powershell)
.\venv\Scripts\activate

# macOS
source venv/bin/activate
```

#### _Instalar dependencias_

Ahora vuestra terminal deberia ser algo como:
> `(.venv) pgalopa@pau-laptop:~/PowerPathFinder$`

Ejecutad:  

```bash
pip install -r ppf-route-api/requirements.txt
python -m pip install --config-settings editable-mode=strict --editable ppf 
```

---

### Flutter + Dart + Android Studio  
_Flutter_  
- MAC: https://docs.flutter.dev/get-started/install/macos
- WIN: https://docs.flutter.dev/get-started/install/windows

_Android Studio_  
- Download: https://developer.android.com/studio
- Install: https://developer.android.com/studio/intro

Podeis comprovar vuestra instalacion en VSCode.
- Pulsa `Ctrl`+`Shift`+`P`
- Escribe `flutter doctor` y `Enter`
- Deberia aparecer algo parecido a esto

```
[flutter] flutter doctor -v
[✓] Flutter (Channel stable, 3.19.2, on Ubuntu 22.04.4 LTS 6.5.0-21-generic, locale en_US.UTF-8)
    • Flutter version 3.19.2 on channel stable at /usr/local/flutter
    • Upstream repository https://github.com/flutter/flutter.git
    • Framework revision 7482962148 (9 days ago), 2024-02-27 16:51:22 -0500
    • Engine revision 04817c99c9
    • Dart version 3.3.0
    • DevTools version 2.31.1

[✓] Android toolchain - develop for Android devices (Android SDK version 34.0.0)
    • Android SDK at /home/pgalopa/Android/Sdk
    • Platform android-34, build-tools 34.0.0
    • Java binary at: /usr/local/android-studio/jbr/bin/java
    • Java version OpenJDK Runtime Environment (build 17.0.9+0-17.0.9b1087.7-11185874)
    • All Android licenses accepted.

[✓] Chrome - develop for the web
    • Chrome at google-chrome

[✗] Linux toolchain - develop for Linux desktop
    ✗ clang++ is required for Linux development.
      It is likely available from your distribution (e.g.: apt install clang), or can be downloaded from https://releases.llvm.org/
    ✗ CMake is required for Linux development.
      It is likely available from your distribution (e.g.: apt install cmake), or can be downloaded from https://cmake.org/download/
    ✗ ninja is required for Linux development.
      It is likely available from your distribution (e.g.: apt install ninja-build), or can be downloaded from https://github.com/ninja-build/ninja/releases
    • pkg-config version 0.29.2
    ✗ GTK 3.0 development libraries are required for Linux development.
      They are likely available from your distribution (e.g.: apt install libgtk-3-dev)

[✓] Android Studio (version 2023.2)
    • Android Studio at /usr/local/android-studio
    • Flutter plugin can be installed from:
      🔨 https://plugins.jetbrains.com/plugin/9212-flutter
    • Dart plugin can be installed from:
      🔨 https://plugins.jetbrains.com/plugin/6351-dart
    • Java version OpenJDK Runtime Environment (build 17.0.9+0-17.0.9b1087.7-11185874)

[✓] VS Code (version 1.87.0)
    • VS Code at /usr/share/code
    • Flutter extension version 3.84.0

[✓] Connected device (2 available)
    • Linux (desktop) • linux  • linux-x64      • Ubuntu 22.04.4 LTS 6.5.0-21-generic
    • Chrome (web)    • chrome • web-javascript • Google Chrome 122.0.6261.94

[✓] Network resources
    • All expected network resources are available.

! Doctor found issues in 1 category.
exit code 0
```
